<<<<<<< HEAD
import 'package:firebase_messaging/firebase_messaging.dart';
=======
import 'package:firebase_auth/firebase_auth.dart';
>>>>>>> 80ac0e23b975adfbd9e00046b57f04e455792b01

import 'screens/device_manager.dart';
import 'screens/home_screen.dart';
import 'screens/open_history.dart';
import 'screens/warning_history.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'screens/loginScreen.dart';
import 'screens/signupScreen.dart';
import 'services/fcm_service.dart'; 

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final fcmService = FCMService(navigatorKey: navigatorKey);
  await fcmService.initialize();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            final user = snapshot.data;
            if (user == null) {
              return Signin(); // Chuyển đến màn hình đăng nhập nếu chưa đăng nhập
            }
            return HomeScreen(); // Chuyển đến màn hình chính nếu đã đăng nhập
          }
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
      ),
      routes: {
        '/home': (context) => HomeScreen(),
        '/signup': (context) => SignUp(),
        '/login': (context) => Signin(),
        '/open_history': (context) => OpenHistoryScreen(),
        '/warning_history': (context) => WarningHistoryScreen(),
        '/device_manager': (context) => DeviceManagerScreen(),
      },
    );
  }
}