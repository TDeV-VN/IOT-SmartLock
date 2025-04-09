import 'screens/device_manager.dart';
import 'screens/home_screen.dart';
import 'screens/open_history.dart';
import 'screens/warning_history.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'screens/loginScreen.dart';
import 'screens/signupScreen.dart';


void main() async {
  // Khởi động Firebase
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SignUp(),
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
