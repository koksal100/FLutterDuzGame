import 'package:flutter/material.dart';
import 'colors.dart';

class RetroTheme {
  static ThemeData get theme {
    return ThemeData(
      scaffoldBackgroundColor: RetroColors.background,
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontFamily: 'Courier',
          fontSize: 30,
          fontWeight: FontWeight.bold,
          color: RetroColors.greenAccent,
          shadows: [
            Shadow(
              color: RetroColors.greenAccent.withOpacity(0.8),
              blurRadius: 10,
              offset: Offset(2, 2),
            ),
          ],
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Courier',
          fontSize: 16,
          color: RetroColors.white,
        ),
      ),
      buttonTheme: ButtonThemeData(
        buttonColor: RetroColors.greenAccent,
        textTheme: ButtonTextTheme.primary,
      ),
    );
  }
}
