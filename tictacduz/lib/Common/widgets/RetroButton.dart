import 'package:flutter/material.dart';
import '../colors.dart';

class RetroButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color glowColor;
  final Color textColor;

  const RetroButton({
    Key? key,
    required this.text,
    required this.onPressed,
    required this.glowColor,
    this.textColor=RetroColors.background,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 250,
        height: 60,
        decoration: BoxDecoration(
          color: RetroColors.background, // İç rengi sabit siyah
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: glowColor, width: 2), // Kenar rengi parametre
          boxShadow: [
            BoxShadow(
              color: glowColor, // Glow efekti parametreye bağlı
              offset: Offset(4, 4),
              blurRadius: 25,
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Courier',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 5.2,
              color: this.textColor,
              shadows: [
                Shadow(
                  color: Colors.black,
                  offset: Offset(2, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
