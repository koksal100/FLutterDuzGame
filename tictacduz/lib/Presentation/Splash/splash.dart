import 'package:flutter/material.dart';

class splashPage extends StatefulWidget {
  State<splashPage> createState() => _splashPageState();
}

class _splashPageState extends State<splashPage> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
          Image.asset(
            'assets/bear.png',
            fit: BoxFit.contain,
          ),
          SizedBox(height: 30,),
        ]),
      ),
    );
  }
}
