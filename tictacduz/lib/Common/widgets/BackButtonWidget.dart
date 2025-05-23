import 'package:flutter/material.dart';
import 'package:tictactoegame/Common/colors.dart';

class BackButtonWidget extends StatelessWidget {
  final VoidCallback? onTap;

  BackButtonWidget({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: RetroColors.background, // İç renk
          border: Border.all(color: RetroColors.greenAccent, width: 2.0), // Çerçeve
          borderRadius: BorderRadius.circular(8.0), // Köşeleri yuvarlat
        ),
        child: const Icon(
          Icons.arrow_back, // Geri işareti
          color: RetroColors.greenAccent, // Renk
          size: 24.0,
        ),
      ),
    );
  }
}
