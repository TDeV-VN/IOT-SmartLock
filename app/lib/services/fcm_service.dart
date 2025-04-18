import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("===== BACKGROUND NOTIFICATION =====");
  print("ID: ${message.messageId}");
  print("Title: ${message.notification?.title}");
  print("Body: ${message.notification?.body}");
  print("Data: ${message.data}");
  print("===================================");
}

class FCMService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final GlobalKey<NavigatorState> navigatorKey;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'new_firmware_channel',
    'Cập nhật Firmware',
    description: 'Kênh thông báo về cập nhật firmware mới',
    importance: Importance.high,
  );

  FCMService({required this.navigatorKey});

  Future<void> init() async {
    print("===== INITIALIZING FCM SERVICE =====");

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true, badge: true, sound: true,
    );

    print("Quyền thông báo: ${settings.authorizationStatus}");

    String? token = await _firebaseMessaging.getToken();
    print("FCM TOKEN: $token");

    await _initLocalNotifications();
    await _firebaseMessaging.subscribeToTopic("NewFirmware");

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    await _checkInitialMessage();

    print("===== FCM SERVICE INITIALIZED =====");
  }

  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@drawable/splash_icon');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        print("===== NOTIFICATION CLICKED =====");
        print("Payload: ${details.payload}");
        print("==============================");

        _handleNotificationClick(details.payload);
      },
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  void _handleNotificationClick(String? payload) {
    if (payload != null) {
      Map<String, dynamic> data = _parsePayload(payload);
      _navigateToNotificationDetailsScreen(data);
    }
  }

  Map<String, dynamic> _parsePayload(String payload) {
    Map<String, dynamic> result = {};

    try {
      String cleanPayload = payload.replaceAll('{', '').replaceAll('}', '');

      List<String> pairs = cleanPayload.split(',');
      for (String pair in pairs) {
        if (pair.trim().isNotEmpty) {
          List<String> keyValue = pair.split(':');
          if (keyValue.length >= 2) {
            String key = keyValue[0].trim().replaceAll('"', '');
            String value = keyValue.sublist(1).join(':').trim();
            value = value.replaceAll('"', '');
            result[key] = value;
          }
        }
      }

      if (payload.contains("topic") || payload.contains("title") || payload.contains("body")) {
        final RegExp topicRegex = RegExp(r'"topic"\s*:\s*"([^"]+)"');
        final RegExp titleRegex = RegExp(r'"title"\s*:\s*"([^"]+)"');
        final RegExp bodyRegex = RegExp(r'"body"\s*:\s*"([^"]+)"');

        final topicMatch = topicRegex.firstMatch(payload);
        final titleMatch = titleRegex.firstMatch(payload);
        final bodyMatch = bodyRegex.firstMatch(payload);

        if (topicMatch != null) result['topic'] = topicMatch.group(1);
        if (titleMatch != null) result['title'] = titleMatch.group(1);
        if (bodyMatch != null) result['body'] = bodyMatch.group(1);
      }

    } catch (e) {
      print("Lỗi khi phân tích payload: $e");
      result = {
        'error': 'Không thể phân tích dữ liệu thông báo',
        'raw_payload': payload
      };
    }

    return result;
  }

  void _navigateToNotificationDetailsScreen(Map<String, dynamic> data) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => NotificationDetailsScreen(data: data),
      ),
    );
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print("===== FOREGROUND NOTIFICATION =====");
    print("ID: ${message.messageId}");
    print("Title: ${message.notification?.title}");
    print("Body: ${message.notification?.body}");
    print("Data: ${message.data}");
    print("===================================");

    if (message.notification != null) {
      Map<String, dynamic> enhancedData = Map.from(message.data);

      if (message.notification?.title != null) {
        enhancedData['title'] = message.notification?.title;
      }
      if (message.notification?.body != null) {
        enhancedData['body'] = message.notification?.body;
      }

      await _showLocalNotification(message, enhancedData);
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message, [Map<String, dynamic>? enhancedData]) async {
    final RemoteNotification? notification = message.notification;

    if (notification != null) {
      final payloadData = enhancedData ?? message.data;

      await _flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            icon: '@drawable/splash_icon',
            styleInformation: BigTextStyleInformation(
              notification.body ?? '',
              htmlFormatBigText: true,
              contentTitle: notification.title,
              htmlFormatContentTitle: true,
              summaryText: 'Chi tiết thông báo',
              htmlFormatSummaryText: true,
            ),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payloadData.toString(),
      );
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    print("===== APP OPENED FROM NOTIFICATION =====");
    print("ID: ${message.messageId}");
    print("Title: ${message.notification?.title}");
    print("Body: ${message.notification?.body}");
    print("Data: ${message.data}");
    print("=======================================");

    Map<String, dynamic> enhancedData = Map.from(message.data);

    if (message.notification?.title != null) {
      enhancedData['title'] = message.notification?.title;
    }
    if (message.notification?.body != null) {
      enhancedData['body'] = message.notification?.body;
    }

    _navigateToNotificationDetailsScreen(enhancedData);
  }

  Future<void> _checkInitialMessage() async {
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();

    if (initialMessage != null) {
      print("===== APP STARTED FROM NOTIFICATION =====");
      print("ID: ${initialMessage.messageId}");
      print("Title: ${initialMessage.notification?.title}");
      print("Body: ${initialMessage.notification?.body}");
      print("Data: ${initialMessage.data}");
      print("=========================================");

      Map<String, dynamic> enhancedData = Map.from(initialMessage.data);

      if (initialMessage.notification?.title != null) {
        enhancedData['title'] = initialMessage.notification?.title;
      }
      if (initialMessage.notification?.body != null) {
        enhancedData['body'] = initialMessage.notification?.body;
      }

      _navigateToNotificationDetailsScreen(enhancedData);
    }
  }

  Future<void> unsubscribeFromTopic() async {
    await _firebaseMessaging.unsubscribeFromTopic("NewFirmware");
    print("Đã hủy đăng ký topic 'NewFirmware'");
  }

  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }
}

class NotificationDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const NotificationDetailsScreen({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết thông báo'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.indigo.withOpacity(0.05), Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data.containsKey('title')) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.notification_important,
                                color: Colors.indigo[700],
                                size: 24),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                data['title'].toString(),
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                if (data.containsKey('body')) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nội dung:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          data['body'].toString(),
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.black87,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.indigo[700]),
                      const SizedBox(width: 6),
                      Text(
                        'Nhận lúc: ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.indigo[700],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                if (data.containsKey('topic') && data['topic'] == 'NewFirmware') ...[
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đang tải xuống bản cập nhật firmware...'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      icon: const Icon(Icons.system_update),
                      label: const Text('Cập nhật ngay'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}