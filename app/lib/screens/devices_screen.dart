import 'package:app/services/fcm_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:app/widgets/custom_appbar.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class DevicesScreen extends StatefulWidget {
  final FCMService fcmService;

  const DevicesScreen({Key? key, required this.fcmService}) : super(key: key);

  @override
  _DevicesScreenState createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  final database = FirebaseDatabase.instance.ref();
  final auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> locks = [];
  Map<String, bool> subscriptionStatus = {};

  @override
  void initState() {
    super.initState();
    print("[DEBUG] DevicesScreen - initState được gọi");
    _listenToUserLocks();
  }

  void _listenToUserLocks() {
    final uuid = auth.currentUser?.uid;
    print("[DEBUG] UUID của người dùng: $uuid");
    if (uuid == null) {
      print("[ERROR] UUID là null, không thể lấy dữ liệu khóa");
      return;
    }

    final userLocksRef = database.child('account/$uuid/lock');
    print("[DEBUG] Đang lắng nghe tại đường dẫn: account/$uuid/lock");

    userLocksRef.onValue.listen((event) {
      print("[DEBUG] Nhận được dữ liệu từ Firebase");
      final data = event.snapshot.value;
      print("[DEBUG] Dữ liệu nhận được: $data");
      
      if (data == null) {
        print("[ERROR] Dữ liệu là null");
        setState(() {
          locks = [];
        });
        return;
      }
      
      // Xử lý dữ liệu là Map (cấu trúc mới của Firebase RTDB)
      if (data is Map) {
        print("[DEBUG] Dữ liệu là Map");
        List<Map<String, dynamic>> updatedLocks = [];
        
        try {
          (data as Map<dynamic, dynamic>).forEach((key, value) {
            print("[DEBUG] Đang xử lý key: $key, value: $value");
            
            if (value is Map) {
              final lockData = Map<String, dynamic>.from(value);
              print("[DEBUG] LockData: $lockData");
              
              // Lấy lockId từ trường 'id' trong dữ liệu
              final lockId = lockData['id'] ?? '';
              print("[DEBUG] Đã trích xuất lockId: $lockId từ index $key");
              
              Map<String, dynamic> latestNotification = {};
              if (lockData['latest_notification'] is Map) {
                latestNotification = Map<String, dynamic>.from(lockData['latest_notification']);
                print("[DEBUG] LatestNotification: $latestNotification");
              }

              updatedLocks.add({
                'id': lockId,
                'name': lockData['name'] ?? 'Không tên',
                'message': latestNotification['message'] ?? '',
                'time': latestNotification['time'] ?? '',
                'index': key,
              });
              
              // Kiểm tra trạng thái đăng ký topic cho thiết bị này
              _checkSubscriptionStatus(lockId);
            }
          });
          
          print("[DEBUG] Tổng số khóa đã xử lý: ${updatedLocks.length}");
          
          setState(() {
            locks = updatedLocks;
            print("[DEBUG] Đã cập nhật state với ${locks.length} khóa");
          });
        } catch (e) {
          print("[ERROR] Lỗi khi xử lý dữ liệu Map: $e");
        }
        return;
      }
      
      // Xử lý trường hợp dữ liệu là List (cấu trúc cũ)
      if (data is List) {
        print("[DEBUG] Dữ liệu là List");
        List<Map<String, dynamic>> updatedLocks = [];
        
        try {
          for (int i = 0; i < data.length; i++) {
            final item = data[i];
            print("[DEBUG] Đang xử lý item tại index $i: $item");
            
            if (item != null && item is Map) {
              final lockData = Map<String, dynamic>.from(item);
              final lockId = lockData['id'] ?? '';
              print("[DEBUG] Đã trích xuất lockId: $lockId từ index $i");
              
              Map<String, dynamic> latestNotification = {};
              if (lockData['latest_notification'] is Map) {
                latestNotification = Map<String, dynamic>.from(lockData['latest_notification']);
                print("[DEBUG] LatestNotification: $latestNotification");
              }

              updatedLocks.add({
                'id': lockId,
                'name': lockData['name'] ?? 'Không tên',
                'message': latestNotification['message'] ?? '',
                'time': latestNotification['time'] ?? '',
                'index': i,
              });
              
              // Kiểm tra trạng thái đăng ký topic cho thiết bị này
              _checkSubscriptionStatus(lockId);
            }
          }
          
          print("[DEBUG] Tổng số khóa đã xử lý từ List: ${updatedLocks.length}");
          
          setState(() {
            locks = updatedLocks;
            print("[DEBUG] Đã cập nhật state với ${locks.length} khóa");
          });
        } catch (e) {
          print("[ERROR] Lỗi khi xử lý dữ liệu List: $e");
        }
      }
    }, onError: (error) {
      print("[ERROR] Lỗi khi lắng nghe Firebase: $error");
    });
  }

  void _checkSubscriptionStatus(String lockId) async {
    try {
      // Tạo tên topic theo định dạng "warning_lockId"
      final topicName = 'warning_$lockId';
      print("[DEBUG] Kiểm tra trạng thái đăng ký topic: $topicName cho lockId: $lockId");
      
      // Đây là cách đơn giản, lý tưởng hơn sẽ là kiểm tra xem topic đã được đăng ký chưa
      // Vì Firebase không cung cấp API để kiểm tra topic đã đăng ký, nên chúng ta sẽ lưu trạng thái
      // trong SharedPreferences. Đây là phương án tạm thời để demo
      final fcmToken = await FirebaseMessaging.instance.getToken();
      final hasToken = fcmToken != null && fcmToken.isNotEmpty;
      
      // Kiểm tra trong SharedPreferences tình trạng đăng ký cho topicName này
      final isSubscribed = await widget.fcmService.isTopicSubscribed(topicName);
      
      print("[DEBUG] Token FCM có sẵn: $hasToken, Đã đăng ký topic $topicName: $isSubscribed");
      
      setState(() {
        subscriptionStatus[lockId] = isSubscribed;
      });
    } catch (e) {
      print("[ERROR] Lỗi khi kiểm tra trạng thái đăng ký: $e");
    }
  }

  Future<void> _toggleNotificationSubscription(String lockId, bool subscribe) async {
    // Tạo tên topic theo định dạng "warning_lockId"
    final topicName = 'warning_$lockId';
    print("[DEBUG] Thay đổi đăng ký thông báo cho topic: $topicName (lockId: $lockId): $subscribe");
    
    try {
      if (subscribe) {
        await FirebaseMessaging.instance.subscribeToTopic(topicName);
        await widget.fcmService.saveTopicSubscription(topicName, true);
        print("[DEBUG] Đã đăng ký topic: $topicName");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã bật thông báo cho ${_getLockName(lockId)}')),
        );
      } else {
        await FirebaseMessaging.instance.unsubscribeFromTopic(topicName);
        await widget.fcmService.saveTopicSubscription(topicName, false);
        print("[DEBUG] Đã hủy đăng ký topic: $topicName");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã tắt thông báo cho ${_getLockName(lockId)}')),
        );
      }
      
      setState(() {
        subscriptionStatus[lockId] = subscribe;
      });
    } catch (e) {
      print("[ERROR] Lỗi khi thay đổi trạng thái đăng ký topic: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Có lỗi xảy ra khi thay đổi cài đặt thông báo')),
      );
    }
  }

  String _getLockName(String lockId) {
    final lock = locks.firstWhere((lock) => lock['id'] == lockId, orElse: () => {'name': 'Không xác định'});
    return lock['name'];
  }

  String formatTimestamp(dynamic timestamp) {
    if (timestamp == null || timestamp.toString().isEmpty) return '';
    try {
      final dt = DateTime.fromMillisecondsSinceEpoch(
          int.parse(timestamp.toString()) * 1000);
      return DateFormat('HH:mm:ss dd/MM/yyyy').format(dt);
    } catch (e) {
      print("[ERROR] Lỗi khi format timestamp: $e, timestamp: $timestamp");
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    print("[DEBUG] Build được gọi với ${locks.length} khóa");
    
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              CustomAppBar(subtitle: 'Quản lý thiết bị'),
              SizedBox(height: 20),
              
              // Thêm container để debug nếu không có nội dung hiển thị
              if (locks.isEmpty) 
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  color: Colors.yellow[100],
                  child: Text(
                    'Không có thiết bị nào được tìm thấy. Vui lòng kiểm tra kết nối Firebase.',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              
              ...locks.map((lock) {
                final lockId = lock['id'] ?? '';
                print("[DEBUG] Đang render khóa: $lockId, name: ${lock['name']}");
                final isSubscribed = subscriptionStatus[lockId] ?? false;
                
                return _buildSmartLockCard(
                  name: lock['name'] ?? 'Không tên',
                  message: lock['message'] ?? '',
                  time: formatTimestamp(lock['time']),
                  isSubscribed: isSubscribed,
                  onTap: () {
                    _showLockDetailDialog(lock);
                  },
                  onToggleNotification: (value) {
                    _toggleNotificationSubscription(lockId, value);
                  },
                );
              }).toList(),
              SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  void _showLockDetailDialog(Map<String, dynamic> lock) {
    final lockId = lock['id'] ?? '';
    print("[DEBUG] Hiển thị chi tiết cho khóa: $lockId");
    
    // Tạo tên topic theo định dạng "warning_lockId"
    final topicName = 'warning_$lockId';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chi tiết thiết bị'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Tên: ${lock['name']}'),
              SizedBox(height: 8),
              Text('ID: $lockId'),
              SizedBox(height: 8),
              Text('Index: ${lock['index']}'),
              SizedBox(height: 8),
              Text('Topic: $topicName'),
              SizedBox(height: 16),
              Text('Thông báo gần nhất:'),
              SizedBox(height: 4),
              Text('${lock['message']}'),
              SizedBox(height: 4),
              Text('Thời gian: ${formatTimestamp(lock['time'])}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Đóng'),
          ),
          ElevatedButton(
            onPressed: () {
              _sendTestNotification(lockId);
              Navigator.of(context).pop();
            },
            child: Text('Gửi thông báo kiểm tra'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendTestNotification(String lockId) async {
    print("[DEBUG] Gửi thông báo kiểm tra cho khóa: $lockId");
    
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã gửi thông báo kiểm tra đến thiết bị $lockId')),
      );
      
      final uuid = auth.currentUser?.uid;
      if (uuid == null) {
        print("[ERROR] UUID là null, không thể gửi thông báo kiểm tra");
        return;
      }
      
      final lockData = locks.firstWhere((lock) => lock['id'] == lockId, orElse: () => {'index': null});
      final lockIndex = lockData['index'];
      print("[DEBUG] Index của khóa cần gửi thông báo: $lockIndex");
      
      if (lockIndex != null) {
        await database.child('account/$uuid/lock/$lockIndex/latest_notification').set({
          'message': 'Thông báo kiểm tra',
          'time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        });
        print("[DEBUG] Đã gửi thông báo kiểm tra thành công");
      }
    } catch (e) {
      print("[ERROR] Lỗi khi gửi thông báo kiểm tra: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Có lỗi xảy ra khi gửi thông báo kiểm tra')),
      );
    }
  }

  Widget _buildSmartLockCard({
    required String name,
    required String message,
    required String time,
    required bool isSubscribed,
    required VoidCallback onTap,
    required Function(bool) onToggleNotification,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.lock, size: 24, color: Colors.indigo),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      SizedBox(height: 4),
                      Text(
                        message.isNotEmpty && time.isNotEmpty ? 
                          '$message: $time' : 
                          'Chưa có thông báo',
                        style: TextStyle(color: Colors.black54)
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isSubscribed,
                  onChanged: onToggleNotification,
                  activeColor: Colors.indigo,
                ),
              ],
            ),
            Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Thông báo: ${isSubscribed ? "Đang bật" : "Đang tắt"}',
                  style: TextStyle(
                    fontSize: 14, 
                    color: isSubscribed ? Colors.green : Colors.grey
                  ),
                ),
                Text(
                  'Nhấn để xem chi tiết',
                  style: TextStyle(fontSize: 14, color: Colors.indigo),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}