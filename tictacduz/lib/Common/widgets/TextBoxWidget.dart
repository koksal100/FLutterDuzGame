import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tictactoegame/Common/colors.dart';

class TextBoxWidget extends StatelessWidget {
  final String text; // Metin parametresi
  final double heightRatio; // Yükseklik oranı
  final double widthRatio; // Genişlik oranı
  final double? height; // Opsiyonel yükseklik parametresi
  final double? width; // Opsiyonel genişlik parametresi
  final Widget? animatedWidget; // Opsiyonel animasyonlu widget
  final Color color;
  final Color borderColor; // Renk parametresi
  final Color backgroundColor; // Arka plan rengi
  final double fontSize;
  const TextBoxWidget({
    Key? key,
    required this.text,
    this.fontSize=20,
    this.heightRatio = 1 / 3, // Varsayılan: ekranın 1/3'ü
    this.widthRatio = 0.9,   // Varsayılan: ekranın %90'ı
    this.height,             // Opsiyonel yükseklik parametresi
    this.width,              // Opsiyonel genişlik parametresi
    this.animatedWidget,     // Opsiyonel widget
    this.color = RetroColors.greenAccent,
    this.borderColor = RetroColors.greenAccent,
    this.backgroundColor = RetroColors.transparentBlack, // Şeffaf siyah
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double finalHeight = height ?? MediaQuery.of(context).size.height * heightRatio;
    double finalWidth = width ?? MediaQuery.of(context).size.width * widthRatio;

    return Container(
      alignment: Alignment.center,
      height: finalHeight,
      width: finalWidth,
      decoration: BoxDecoration(
        color: backgroundColor,
        //border: Border.all(color: borderColor, width: 3.0), // Kullanıcı renk parametresi
        borderRadius: BorderRadius.circular(20),

      ),
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              text,
              style: TextStyle(
                letterSpacing: 4,
                color: color,
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none, // Alt çizgiyi kaldırır

              ),
              textAlign: TextAlign.center,

            ),
            if (animatedWidget != null) ...[
              SizedBox(height: 40 * heightRatio),
              animatedWidget!
            ]
          ],
        ),
      ),
    );
  }
}
