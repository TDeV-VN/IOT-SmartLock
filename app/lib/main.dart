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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final fcmService = FCMService(navigatorKey: navigatorKey);
  await fcmService.init();

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
      home: DeviceManagerScreen(lockId: 'lock_id1'),
      routes: {
        '/home': (context) => HomeScreen(),
        '/signup': (context) => SignUp(),
        '/login': (context) => Signin(),
        '/open_history': (context) => OpenHistoryScreen(lockId: 'lock_id1'),
        '/warning_history': (context) => WarningHistoryScreen(lockId: 'lock_id1'),
        '/device_manager': (context) => DeviceManagerScreen(lockId: 'lock_id1'),
      },
    );
  }
}