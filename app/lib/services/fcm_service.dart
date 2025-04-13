import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';

class FCMService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseDatabase _firebaseDatabase = FirebaseDatabase.instance;
  final GlobalKey<NavigatorState> navigatorKey;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();
  
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
    enableVibration: true,
    playSound: true,
  );

  FCMService({required this.navigatorKey});

  Future<void> initialize() async {
    // Yêu cầu quyền thông báo
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    
    print('Quyền thông báo: ${settings.authorizationStatus}');
    
    // Khởi tạo thông báo cục bộ với xử lý khi nhấn
    await _initLocalNotifications();
    
    // Xử lý thông báo khi ứng dụng đang mở (foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('Nhận được thông báo khi ứng dụng đang mở: ${message.notification?.title}');
      print('Message data: ${message.data}');
      
      // Kiểm tra lockId trước khi hiển thị thông báo
      final bool shouldShowNotification = await _verifyLockId(message.data);
      
      if (!shouldShowNotification) {
        print('LockId không khớp với dữ liệu realtime, bỏ qua thông báo');
        return;
      }
      
      // Thêm timestamp vào dữ liệu thông báo nếu chưa có
      final timestamp = message.data['timestamp'] ?? 
                        DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
      final updatedData = {...message.data, 'timestamp': timestamp};
      
      // Mở trực tiếp trang chi tiết thông báo (thay vì hiển thị dialog)
      _navigateToNotificationDetailScreen(message, updatedData);
      
      // Vẫn hiển thị thông báo cục bộ trong trường hợp người dùng không nhìn thấy màn hình
      _showLocalNotification(message, updatedData);
    });

    // Xử lý khi người dùng nhấn vào thông báo khi ứng dụng ở chế độ nền
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Người dùng nhấn vào thông báo (background): ${message.notification?.title}');
      print('Message data (background): ${message.data}');
      
      // Thêm timestamp nếu chưa có
      final timestamp = message.data['timestamp'] ?? 
                        DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
      final updatedData = {...message.data, 'timestamp': timestamp};
      
      _navigateToNotificationDetailScreen(message, updatedData);
    });

    // Kiểm tra xem ứng dụng có được mở từ thông báo không
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('Ứng dụng được mở từ thông báo (terminated): ${message.notification?.title}');
        print('Message data (terminated): ${message.data}');
        
        // Thêm timestamp nếu chưa có
        final timestamp = message.data['timestamp'] ?? 
                          DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
        final updatedData = {...message.data, 'timestamp': timestamp};
        
        _navigateToNotificationDetailScreen(message, updatedData);
      }
    });

    // Lấy FCM Token
    String? token = await _firebaseMessaging.getToken();
    print('FCM Token: $token');
  }

  // Kiểm tra lockId với dữ liệu từ Firebase Realtime Database
  Future<bool> _verifyLockId(Map<String, dynamic> data) async {
    try {
      final String? deviceId = data['deviceId'];
      final String? lockId = data['lockId'];
      
      if (lockId == null || deviceId == null) {
        print('Không có lockId hoặc deviceId, hiển thị thông báo mặc định');
        return true;
      }
      
      final DatabaseReference deviceRef = _firebaseDatabase.ref('devices/$deviceId');
      final DatabaseEvent event = await deviceRef.once();
      
      if (event.snapshot.value == null) {
        print('Không tìm thấy thiết bị với ID: $deviceId');
        return false;
      }
      
      final deviceData = event.snapshot.value as Map<dynamic, dynamic>;
      final String? currentLockId = deviceData['lockId']?.toString();
      
      print('LockId từ thông báo: $lockId');
      print('LockId từ database: $currentLockId');
      
      return lockId == currentLockId;
    } catch (e) {
      print('Lỗi khi kiểm tra lockId: $e');
      return true;
    }
  }

  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        if (details.payload != null) {
          try {
            print('Local notification tapped with payload: ${details.payload}');
            Map<String, dynamic> data = jsonDecode(details.payload!);
            
            // Tạo RemoteMessage giả để truyền vào hàm điều hướng
            RemoteMessage mockMessage = RemoteMessage(
              notification: RemoteNotification(
                title: data['title'] ?? 'Thông báo',
                body: data['body'] ?? '',
                android: const AndroidNotification(
                  channelId: 'high_importance_channel',
                ),
              ),
              data: data,
            );
            
            _navigateToNotificationDetailScreen(mockMessage, data);
          } catch (e) {
            print('Error parsing notification payload: $e');
          }
        }
      },
    );
    
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  void _showLocalNotification(RemoteMessage message, Map<String, dynamic> data) {
    final notification = message.notification;
    final android = message.notification?.android;
    
    if (notification != null) {
      // Lưu thêm title và body vào data để khi nhấn vào thông báo có thể tạo lại thông tin đầy đủ
      final fullData = {
        ...data,
        'title': notification.title,
        'body': notification.body,
      };
      
      _flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            icon: android?.smallIcon ?? 'notification_icon',
            importance: Importance.max,
            priority: Priority.high,
            sound: const RawResourceAndroidNotificationSound('notification_sound'),
            playSound: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(fullData),
      );
    }
  }

  // Hàm mới để điều hướng đến trang chi tiết thông báo
  void _navigateToNotificationDetailScreen(RemoteMessage message, Map<String, dynamic> data) {
    if (navigatorKey.currentState != null) {
      // Sử dụng Future.delayed để đảm bảo điều hướng xảy ra sau frame hiện tại
      Future.delayed(Duration.zero, () {
        navigatorKey.currentState!.push(
          MaterialPageRoute(
            builder: (context) => NotificationDetailScreen(
              message: message,
              data: data,
              onActionPressed: () => _handleNotificationData(data),
            ),
          ),
        );
      });
    }
  }

  void _handleNotificationData(Map<String, dynamic> data) {
    final screen = data['screen'];
    final deviceId = data['deviceId'];
    
    print('Navigation data: screen=$screen, deviceId=$deviceId');
    
    if (screen != null && navigatorKey.currentState != null) {
      Future.delayed(Duration.zero, () {
        switch (screen) {
          case 'warning_history':
            print('Navigating to warning_history with deviceId: $deviceId');
            navigatorKey.currentState?.pushNamed(
              '/warning_history', 
              arguments: deviceId
            );
            break;
          case 'open_history':
            print('Navigating to open_history with deviceId: $deviceId');
            navigatorKey.currentState?.pushNamed(
              '/open_history', 
              arguments: deviceId
            );
            break;
          default:
            print('Navigating to home screen');
            navigatorKey.currentState?.pushNamed('/home');
            break;
        }
      });
    } else {
      print('Cannot navigate: screen=$screen, navigatorState=${navigatorKey.currentState != null}');
    }
  }

  // Lưu trạng thái đăng ký topic
  Future<void> saveTopicSubscription(String topic, bool isSubscribed) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('topic_$topic', isSubscribed);
      
      if (isSubscribed) {
        await _firebaseMessaging.subscribeToTopic(topic);
      } else {
        await _firebaseMessaging.unsubscribeFromTopic(topic);
      }
      
      print('Đã lưu trạng thái đăng ký cho topic $topic: $isSubscribed');
    } catch (e) {
      print('Lỗi khi lưu trạng thái đăng ký topic: $e');
    }
  }

  // Kiểm tra trạng thái đăng ký topic
  Future<bool> isTopicSubscribed(String topic) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('topic_$topic') ?? false;
    } catch (e) {
      print('Lỗi khi kiểm tra trạng thái đăng ký topic: $e');
      return false;
    }
  }
}

// Màn hình chi tiết thông báo mới
class NotificationDetailScreen extends StatelessWidget {
  final RemoteMessage message;
  final Map<String, dynamic> data;
  final VoidCallback onActionPressed;

  const NotificationDetailScreen({
    Key? key,
    required this.message,
    required this.data,
    required this.onActionPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final notification = message.notification;
    final title = notification?.title ?? data['title'] ?? 'Thông báo';
    final body = notification?.body ?? data['body'] ?? '';
    final timestamp = data['timestamp'] ?? 
                      DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    final deviceId = data['deviceId'] ?? 'Không xác định';
    final String? actionType = data['screen'];
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar với gradient và nút back
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _getNotificationColor(actionType).withOpacity(0.8),
                      _getNotificationColor(actionType),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getNotificationIcon(actionType),
                            size: 70,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              title: Text(
                _getNotificationTypeText(actionType),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
            ),
            backgroundColor: _getNotificationColor(actionType),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.white),
                onPressed: () {
                  // Hiển thị trang danh sách thông báo
                  Navigator.of(context).pushNamed('/notifications');
                },
              ),
            ],
          ),
          
          // Nội dung
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tiêu đề và thời gian
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: _getNotificationColor(actionType).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: _getNotificationColor(actionType),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatTime(timestamp),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _getNotificationColor(actionType),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Text(
                          body,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Thông tin chi tiết
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Thông tin chi tiết',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 15),
                        
                        // Thời gian đầy đủ
                        _buildInfoRow(
                          Icons.calendar_today,
                          'Ngày nhận',
                          _formatDate(timestamp),
                        ),
                        const SizedBox(height: 12),
                        
                        // ID thiết bị
                        _buildInfoRow(
                          Icons.devices,
                          'Thiết bị',
                          deviceId,
                        ),
                        
                        // Mã khóa (nếu có)
                        if (data['lockId'] != null) ...[
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            Icons.lock,
                            'Mã khóa',
                            data['lockId'],
                          ),
                        ],
                        
                        // Loại cảnh báo
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          _getNotificationIcon(actionType),
                          'Loại thông báo',
                          _getNotificationTypeText(actionType),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Nút hành động
                  ElevatedButton(
                    onPressed: onActionPressed,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: _getNotificationColor(actionType),
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_getActionIcon(actionType)),
                        const SizedBox(width: 10),
                        Text(
                          _getActionText(actionType),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 15),
                  
                  // Nút đóng
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      side: BorderSide(color: Colors.grey[300]!),
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Đóng thông báo',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Tạo hàng thông tin có định dạng đẹp
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: Colors.grey[700]),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Màu sắc dựa trên loại thông báo
  Color _getNotificationColor(String? actionType) {
    switch (actionType) {
      case 'warning_history':
        return Colors.red[700] ?? Colors.red;
      case 'open_history':
        return Colors.green[700] ?? Colors.green;
      default:
        return Colors.blue[700] ?? Colors.blue;
    }
  }

  // Icon dựa trên loại thông báo
  IconData _getNotificationIcon(String? actionType) {
    switch (actionType) {
      case 'warning_history':
        return Icons.warning_amber_rounded;
      case 'open_history':
        return Icons.door_front_door_outlined;
      default:
        return Icons.notifications;
    }
  }
  
  // Tên loại thông báo
  String _getNotificationTypeText(String? actionType) {
    switch (actionType) {
      case 'warning_history':
        return 'Cảnh báo an ninh';
      case 'open_history':
        return 'Lịch sử mở cửa';
      default:
        return 'Thông báo hệ thống';
    }
  }
  
  // Icon cho nút hành động
  IconData _getActionIcon(String? actionType) {
    switch (actionType) {
      case 'warning_history':
        return Icons.security;
      case 'open_history':
        return Icons.history;
      default:
        return Icons.info_outline;
    }
  }
  
  // Văn bản cho nút hành động
  String _getActionText(String? actionType) {
    switch (actionType) {
      case 'warning_history':
        return 'Xem chi tiết cảnh báo';
      case 'open_history':
        return 'Xem lịch sử mở cửa';
      default:
        return 'Xem chi tiết';
    }
  }
  
  // Định dạng ngày tháng
  String _formatDate(String timestamp) {
    try {
      // Cố gắng phân tích timestamp từ format 'dd/MM/yyyy HH:mm'
      final DateTime dateTime = DateFormat('dd/MM/yyyy HH:mm').parse(timestamp);
      return DateFormat('EEEE, dd/MM/yyyy', 'vi_VN').format(dateTime);
    } catch (e) {
      // Trả về timestamp gốc nếu không phân tích được
      return timestamp;
    }
  }
  
  // Định dạng thời gian
  String _formatTime(String timestamp) {
    try {
      // Cố gắng phân tích timestamp từ format 'dd/MM/yyyy HH:mm'
      final DateTime dateTime = DateFormat('dd/MM/yyyy HH:mm').parse(timestamp);
      return DateFormat('HH:mm').format(dateTime);
    } catch (e) {
      // Trả về timestamp gốc nếu không phân tích được
      return timestamp;
    }
  }
}