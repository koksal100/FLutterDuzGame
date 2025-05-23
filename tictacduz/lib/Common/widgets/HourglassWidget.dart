import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:tictactoegame/Common/colors.dart';

class HourglassFillWidget extends StatefulWidget {
  @override
  _HourglassFillWidgetState createState() => _HourglassFillWidgetState();
}

class _HourglassFillWidgetState extends State<HourglassFillWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 12),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SpinKitPouringHourGlass(
        color: RetroColors.greenAccent,
        size: 80.0,
        controller: _controller,
      ),
    );
  }
}
