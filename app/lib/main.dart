import 'screens/open_history.dart';
import 'screens/warning_history.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';


void main() async {
  // Khởi động Firebase
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Lock',
      theme: ThemeData(
        fontFamily: 'Roboto',
        primaryColor: Color(0xFF0F0F0F),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFF0F0F0F)),
          titleTextStyle: TextStyle(
            color: Color(0xFF0F0F0F),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: WarningHistoryScreen(),
      routes: {
        '/home': (context) => HomeScreen(),
        '/open_history': (context) => OpenHistoryScreen(),
        '/warning_history': (context) => WarningHistoryScreen(),
      },
    );
  }
}