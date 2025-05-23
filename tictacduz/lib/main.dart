import 'dart:math';

import 'package:flutter/material.dart';
import 'package:tictactoegame/Presentation/HomePage/HomaPage.dart';
import 'package:tictactoegame/Presentation/Splash/splash.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'Common/themes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
  );
  runApp(MyApp());
}

final Image globalBackgroundImage = Image.asset(
  "assets/background.png",
  fit: BoxFit.cover,
);

Image returnRandomImage() {

  int randomNumber=Random().nextInt(7) + 1;
  return Image.asset(
    "assets/random_background_${randomNumber}.${(randomNumber==1||randomNumber==2)?"png":"jpg"}",
    fit: BoxFit.fill, width: double.infinity, // Ekran genişliği
    height: double.infinity,
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  bool showSplashPage = true;
  double opacity = 0;
  double redOpacity = 0;
  static String? userId;

  Future<void> _initializeUser() async {
    final prefs = await SharedPreferences.getInstance();
    final firestore = FirebaseFirestore.instance;

    // Check if user_id exists in SharedPreferences
    userId = prefs.getString('user_id');
    if (userId == null) {
      // Generate a new UUID
      userId = const Uuid().v4();

      // Save the UUID to SharedPreferences
      await prefs.setString('user_id', userId!);

      // Save the UUID to Firestore (user_infos document)
      await firestore.collection('users').doc('user_infos').set({
        'user_id': userId,
      }, SetOptions(merge: true));
    }

    setState(() {
      // Update the UI with the user_id
    });
  }

  @override
  void initState() {
    super.initState();
    _initializeUser();
    Future.delayed(Duration(seconds: 7)).then((onValue) {
      setState(() {
        showSplashPage = false;
      });
    });

    Future.delayed(Duration(milliseconds: 10)).then((onValue) {
      setState(() {
        opacity = 1;
      });
    });

    Future.delayed(Duration(milliseconds: 4500)).then((onValue) {
      setState(() {
        redOpacity = 1;
      });
    });

    Future.delayed(Duration(seconds: 5)).then((onValue) {
      setState(() {
        opacity = 0;
      });
    });

    Future.delayed(Duration(seconds: 6)).then((onValue) {
      setState(() {
        redOpacity = 0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Stack(
        children: [
          showSplashPage
              ? Stack(children: [
                  AnimatedOpacity(
                    opacity: opacity,
                    duration: Duration(milliseconds: 2000),
                    child: splashPage(),
                  ),

                  Positioned(
                    top: screenHeight * 0.404, // %40.4
                    left: screenWidth * 0.367, // %36.7
                    child: AnimatedOpacity(
                      opacity: redOpacity,
                      duration: Duration(seconds: 1),
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.redAccent,
                              blurRadius: 20, // Gölge bulanıklığı
                              offset: Offset(2, 2), // Gölgenin konumu
                            ),
                          ],
                        ),
                        child: Text(
                          ".",
                          style: TextStyle(fontSize: 40, color: Colors.red),
                        ),
                      ),
                    ),
                  ),
                  // İkinci Positioned
                  Positioned(
                    top: screenHeight * 0.404, // %40.4
                    left: screenWidth * 0.578, // %57.8
                    child: AnimatedOpacity(
                      opacity: redOpacity,
                      duration: Duration(seconds: 1),
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.redAccent, // Gölge rengi
                              blurRadius: 20, // Gölge bulanıklığı
                              offset: Offset(2, 2), // Gölgenin konumu
                            ),
                          ],
                        ),
                        child: Text(
                          ".",
                          style: TextStyle(fontSize: 40, color: Colors.red),
                        ),
                      ),
                    ),
                  ),
                ])
              : HomePage()
        ],
      ),
    );
  }
}
