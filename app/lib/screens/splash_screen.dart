import 'dart:async';
import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..forward();

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    Timer(Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F0F0F), 
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: _animation,
              child: AnimatedContainer(
                duration: Duration(seconds: 1),
                curve: Curves.elasticOut, 
                child: Image.asset(
                  'assets/images/icons8-secure-50.png',
                  width: 150,
                  height: 150,
                  color: Colors.white, 
                ),
              ),
            ),
            SizedBox(height: 30),

            DefaultTextStyle(
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              child: AnimatedTextKit(
                animatedTexts: [
                  TypewriterAnimatedText("Smart Lock",
                      speed: Duration(milliseconds: 150)),
                ],
                totalRepeatCount: 1,
              ),
            ),
            SizedBox(height: 10),

            AnimatedTextKit(
              animatedTexts: [
                FadeAnimatedText(
                  "Mở khóa thông minh, an toàn & tiện lợi",
                  textAlign: TextAlign.center,
                  textStyle: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[400], 
                  ),
                ),
              ],
              totalRepeatCount: 1,
            ),
            SizedBox(height: 30),

            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white), 
              strokeWidth: 5, 
            ),
          ],
        ),
      ),
    );
  }
}
