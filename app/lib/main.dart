import 'screens/device_manager.dart';
import 'screens/home_screen.dart';
import 'screens/open_history.dart';
import 'screens/warning_history.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'screens/loginScreen.dart';
import 'screens/signupScreen.dart';

void main() async {
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
