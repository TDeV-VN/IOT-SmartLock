import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    fontFamily: 'Roboto', 
    primaryColor: Color(0xFF0F0F0F),
    scaffoldBackgroundColor: Colors.white,
    textTheme: TextTheme(
      headlineMedium: TextStyle( 
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Color(0xFF0F0F0F),
      ),
      bodyMedium: TextStyle( 
        fontSize: 16,
        color: Color(0xFF0F0F0F),
      ),
      bodyLarge: TextStyle( 
        fontSize: 18,
        color: Color(0xFF0F0F0F),
      ),
    ),
  );
}
