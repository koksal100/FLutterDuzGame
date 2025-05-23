import 'dart:convert';
import 'dart:io';
import 'package:tictactoegame/Common/widgets/TextBoxWidget.dart';
import 'package:flutter/material.dart';
import 'package:tictactoegame/Common/colors.dart';
import 'package:tictactoegame/Common/widgets/BackButtonWidget.dart';
import 'package:tictactoegame/main.dart';

class DuzGameGrid extends StatefulWidget {

  DuzGameGrid();

  @override
  _GameGridState createState() => _GameGridState();
}

class _GameGridState extends State<DuzGameGrid> {
  @override
  late double bigRectangleWidth;
  late double bigRectangleHeight;
  late double xDifferenceBetweenBigAndMiddle;
  late double yDifferenceBetweenBigAndMiddle;
  late double xDifferenceBetweenMiddleAndSmall;
  late double yDifferenceBetweenMiddleAndSmall;
  late Map<Offset, List<List<Offset>>> possibleControls = {};
  late Map<Offset, List<Offset>> possibleMovePoints = {};
  late Map<Offset, double> nodeScales = {};
  bool timeToTakeNode = false;
  bool timeToPutNodes = true;
  bool timeToMoveNodes = true;
  int tapIndex = 0;
  List<Offset> points = [];
  List<Offset> pointsDividedBy1_4 = [];
  List<Offset> pointsDividedBy2_4 = [];
  Map<Offset, Color> nodeColorDict = {};
  int counterToGetNodesFromOpponent = 0;

  void checkWin(Offset point) {
    Color startingColor = nodeColorDict[point] ?? Colors.white;
    int counter = 0;
    List<List<Offset>> possibleControllList = possibleControls[point]!;
    for (List<Offset> offsets in possibleControllList) {
      bool allMatch = true;
      for (Offset offset in offsets) {
        if (nodeColorDict[offset] != startingColor) {
          allMatch = false;
          break;
        }
      }
      if (allMatch) {
        counterToGetNodesFromOpponent++;
        counter++;
        offsets.add(point);
        updateScalesOfOffsets(offsets);
        startingColor == RetroColors.lightBlueAccent ? xScore++ : oScore++;
        setState(() {});
      }
    }
    print("Matched Count: $counter");
  }

  void updateScalesOfOffsets(List<Offset> offsets) async {
    for (int i = 0; i < 3; i++) {
      for (Offset point in offsets) {
        setState(() {
          nodeScales[point] = 0.3;
        });
      }
      await Future.delayed(Duration(milliseconds: 300));
      for (Offset point in offsets) {
        setState(() {
          nodeScales[point] = 1;
        });
      }
      await Future.delayed(Duration(milliseconds: 300));
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initializePoints();
    });
  }

  void initializePoints() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    bigRectangleWidth = screenWidth - 50;
    bigRectangleHeight = screenHeight * 0.7;

    // Büyük dikdörtgenin noktaları
    points = [
      Offset(7, 7), // Sol üst 0
      Offset(bigRectangleWidth / 2, 7), // Üst orta 1
      Offset(bigRectangleWidth - 7, 7), // Sağ üst 2
      Offset(7, bigRectangleHeight - 7), // Sol alt 3
      Offset(bigRectangleWidth - 7, bigRectangleHeight - 7), // Sağ alt 4
      Offset(bigRectangleWidth / 2, bigRectangleHeight - 7), // Alt orta 5
      Offset(7, bigRectangleHeight / 2 - 7), // Sol orta 6
      Offset(bigRectangleWidth - 7, bigRectangleHeight / 2 - 7), // Sağ orta 7
    ];

    // Orta büyüklükteki dikdörtgenin hesaplamaları
    xDifferenceBetweenBigAndMiddle =
        (bigRectangleWidth - bigRectangleWidth / 1.4) / 2;
    yDifferenceBetweenBigAndMiddle =
        (bigRectangleHeight - bigRectangleHeight / 1.4) / 2;

    pointsDividedBy1_4 = [
      Offset(7 + xDifferenceBetweenBigAndMiddle,
          7 + yDifferenceBetweenBigAndMiddle),
      // Sol üst
      Offset(bigRectangleWidth / 2, 7 + yDifferenceBetweenBigAndMiddle),
      // Üst orta
      Offset(bigRectangleWidth - 7 - xDifferenceBetweenBigAndMiddle,
          7 + yDifferenceBetweenBigAndMiddle),
      // Sağ üst
      Offset(7 + xDifferenceBetweenBigAndMiddle,
          bigRectangleHeight - 7 - yDifferenceBetweenBigAndMiddle),
      // Sol alt
      Offset(bigRectangleWidth - 7 - xDifferenceBetweenBigAndMiddle,
          bigRectangleHeight - 7 - yDifferenceBetweenBigAndMiddle),
      // Sağ alt
      Offset(bigRectangleWidth / 2,
          bigRectangleHeight - yDifferenceBetweenBigAndMiddle),
      // Alt orta
      Offset(7 + xDifferenceBetweenBigAndMiddle, bigRectangleHeight / 2 - 7),
      // Sol orta
      Offset(bigRectangleWidth - 7 - xDifferenceBetweenBigAndMiddle,
          bigRectangleHeight / 2 - 7),
      // Sağ orta
    ];

    // Küçük dikdörtgenin hesaplamaları
    xDifferenceBetweenMiddleAndSmall =
        (bigRectangleWidth / 1.4 - bigRectangleWidth / 2.4) / 2;
    yDifferenceBetweenMiddleAndSmall =
        (bigRectangleHeight / 1.4 - bigRectangleHeight / 2.4) / 2;

    pointsDividedBy2_4 = [
      Offset(
          7 + xDifferenceBetweenBigAndMiddle + xDifferenceBetweenMiddleAndSmall,
          7 +
              yDifferenceBetweenBigAndMiddle +
              yDifferenceBetweenMiddleAndSmall), // Sol üst
      Offset(
          bigRectangleWidth / 2,
          7 +
              yDifferenceBetweenBigAndMiddle +
              yDifferenceBetweenMiddleAndSmall), // Üst orta
      Offset(
          bigRectangleWidth -
              7 -
              xDifferenceBetweenBigAndMiddle -
              xDifferenceBetweenMiddleAndSmall,
          7 +
              yDifferenceBetweenBigAndMiddle +
              yDifferenceBetweenMiddleAndSmall), // Sağ üst
      Offset(
          7 + xDifferenceBetweenBigAndMiddle + xDifferenceBetweenMiddleAndSmall,
          bigRectangleHeight -
              7 -
              yDifferenceBetweenBigAndMiddle -
              yDifferenceBetweenMiddleAndSmall), // Sol alt
      Offset(
          bigRectangleWidth -
              7 -
              xDifferenceBetweenBigAndMiddle -
              xDifferenceBetweenMiddleAndSmall,
          bigRectangleHeight -
              7 -
              yDifferenceBetweenBigAndMiddle -
              yDifferenceBetweenMiddleAndSmall), // Sağ alt
      Offset(
          bigRectangleWidth / 2,
          bigRectangleHeight -
              7 -
              yDifferenceBetweenBigAndMiddle -
              yDifferenceBetweenMiddleAndSmall), // Alt orta
      Offset(
          7 + xDifferenceBetweenBigAndMiddle + xDifferenceBetweenMiddleAndSmall,
          bigRectangleHeight / 2 - 7), // Sol orta
      Offset(
          bigRectangleWidth -
              7 -
              xDifferenceBetweenBigAndMiddle -
              xDifferenceBetweenMiddleAndSmall,
          bigRectangleHeight / 2 - 7), // Sağ orta
    ];
    points.addAll(pointsDividedBy1_4);
    points.addAll(pointsDividedBy2_4);
    // Tüm offsetleri ve renklerini map'e atama
    nodeColorDict = {
      for (var point in points) point: Colors.white,
      for (var point in pointsDividedBy1_4) point: Colors.white,
      for (var point in pointsDividedBy2_4) point: Colors.white,
    };

    possibleControls[points[0]] = [
      [points[1], points[2]],
      [points[6], points[3]],
      [pointsDividedBy1_4[0], pointsDividedBy2_4[0]]
    ];
    possibleControls[points[1]] = [
      [points[0], points[2]],
      [pointsDividedBy1_4[1], pointsDividedBy2_4[1]]
    ];
    possibleControls[points[2]] = [
      [points[0], points[1]],
      [points[7], points[4]],
      [pointsDividedBy1_4[2], pointsDividedBy2_4[2]]
    ];
    possibleControls[points[3]] = [
      [points[0], points[6]],
      [points[4], points[5]],
      [pointsDividedBy1_4[3], pointsDividedBy2_4[3]]
    ];
    possibleControls[points[4]] = [
      [points[2], points[7]],
      [points[5], points[3]],
      [pointsDividedBy2_4[4], pointsDividedBy1_4[4]]
    ];
    possibleControls[points[5]] = [
      [points[3], points[4]],
      [pointsDividedBy1_4[5], pointsDividedBy2_4[5]]
    ];
    possibleControls[points[6]] = [
      [points[0], points[3]],
      [pointsDividedBy2_4[6], pointsDividedBy1_4[6]]
    ];
    possibleControls[points[7]] = [
      [points[4], points[2]],
      [pointsDividedBy2_4[7], pointsDividedBy1_4[7]]
    ];
    possibleControls[pointsDividedBy1_4[0]] = [
      [pointsDividedBy1_4[1], pointsDividedBy1_4[2]],
      [pointsDividedBy1_4[6], pointsDividedBy1_4[3]],
      [points[0], pointsDividedBy2_4[0]]
    ];
    possibleControls[pointsDividedBy1_4[1]] = [
      [pointsDividedBy1_4[0], pointsDividedBy1_4[2]],
      [points[1], pointsDividedBy2_4[1]]
    ];
    possibleControls[pointsDividedBy1_4[2]] = [
      [pointsDividedBy1_4[0], pointsDividedBy1_4[1]],
      [pointsDividedBy1_4[7], pointsDividedBy1_4[4]],
      [points[2], pointsDividedBy2_4[2]]
    ];
    possibleControls[pointsDividedBy1_4[3]] = [
      [pointsDividedBy1_4[0], pointsDividedBy1_4[6]],
      [pointsDividedBy1_4[4], pointsDividedBy1_4[5]],
      [points[3], pointsDividedBy2_4[3]]
    ];
    possibleControls[pointsDividedBy1_4[4]] = [
      [pointsDividedBy1_4[2], pointsDividedBy1_4[7]],
      [pointsDividedBy1_4[5], pointsDividedBy1_4[3]],
      [points[4], pointsDividedBy2_4[4]]
    ];
    possibleControls[pointsDividedBy1_4[5]] = [
      [pointsDividedBy1_4[3], pointsDividedBy1_4[4]],
      [points[5], pointsDividedBy2_4[5]]
    ];
    possibleControls[pointsDividedBy1_4[6]] = [
      [pointsDividedBy1_4[0], pointsDividedBy1_4[3]],
      [points[6], pointsDividedBy2_4[6]]
    ];
    possibleControls[pointsDividedBy1_4[7]] = [
      [pointsDividedBy1_4[4], pointsDividedBy1_4[2]],
      [points[7], pointsDividedBy2_4[7]]
    ];
    possibleControls[pointsDividedBy2_4[0]] = [
      [pointsDividedBy2_4[1], pointsDividedBy2_4[2]],
      [pointsDividedBy2_4[6], pointsDividedBy2_4[3]],
      [points[0], pointsDividedBy1_4[0]]
    ];
    possibleControls[pointsDividedBy2_4[1]] = [
      [pointsDividedBy2_4[0], pointsDividedBy2_4[2]],
      [points[1], pointsDividedBy1_4[1]]
    ];
    possibleControls[pointsDividedBy2_4[2]] = [
      [pointsDividedBy2_4[0], pointsDividedBy2_4[1]],
      [pointsDividedBy2_4[7], pointsDividedBy2_4[4]],
      [points[2], pointsDividedBy1_4[2]]
    ];
    possibleControls[pointsDividedBy2_4[3]] = [
      [pointsDividedBy2_4[0], pointsDividedBy2_4[6]],
      [pointsDividedBy2_4[4], pointsDividedBy2_4[5]],
      [points[3], pointsDividedBy1_4[3]]
    ];
    possibleControls[pointsDividedBy2_4[4]] = [
      [pointsDividedBy2_4[2], pointsDividedBy2_4[7]],
      [pointsDividedBy2_4[5], pointsDividedBy2_4[3]],
      [points[4], pointsDividedBy1_4[4]]
    ];
    possibleControls[pointsDividedBy2_4[5]] = [
      [pointsDividedBy2_4[3], pointsDividedBy2_4[4]],
      [points[5], pointsDividedBy1_4[5]]
    ];
    possibleControls[pointsDividedBy2_4[6]] = [
      [pointsDividedBy2_4[0], pointsDividedBy2_4[3]],
      [points[6], pointsDividedBy1_4[6]]
    ];
    possibleControls[pointsDividedBy2_4[7]] = [
      [pointsDividedBy2_4[4], pointsDividedBy2_4[2]],
      [points[7], pointsDividedBy1_4[7]]
    ];

    possibleMovePoints[points[0]] = [
      points[1],
      points[6],
      pointsDividedBy1_4[0]
    ];
    possibleMovePoints[points[1]] = [
      points[0],
      points[2],
      pointsDividedBy1_4[1]
    ];
    possibleMovePoints[points[2]] = [
      points[1],
      points[7],
      pointsDividedBy1_4[2]
    ];
    possibleMovePoints[points[3]] = [
      points[6],
      points[5],
      pointsDividedBy1_4[3]
    ];
    possibleMovePoints[points[4]] = [
      points[5],
      points[7],
      pointsDividedBy1_4[4]
    ];
    possibleMovePoints[points[5]] = [
      points[3],
      points[4],
      pointsDividedBy1_4[5]
    ];
    possibleMovePoints[points[6]] = [
      points[0],
      points[3],
      pointsDividedBy1_4[6]
    ];
    possibleMovePoints[points[7]] = [
      points[2],
      points[4],
      pointsDividedBy1_4[7]
    ];

    possibleMovePoints[pointsDividedBy1_4[0]] = [
      pointsDividedBy1_4[1],
      pointsDividedBy1_4[6],
      pointsDividedBy2_4[0],
      points[0]
    ];
    possibleMovePoints[pointsDividedBy1_4[1]] = [
      pointsDividedBy1_4[0],
      pointsDividedBy1_4[2],
      pointsDividedBy2_4[1],
      points[1]
    ];
    possibleMovePoints[pointsDividedBy1_4[2]] = [
      pointsDividedBy1_4[1],
      pointsDividedBy1_4[7],
      pointsDividedBy2_4[2],
      points[2]
    ];
    possibleMovePoints[pointsDividedBy1_4[3]] = [
      pointsDividedBy1_4[6],
      pointsDividedBy1_4[5],
      pointsDividedBy2_4[3],
      points[3]
    ];
    possibleMovePoints[pointsDividedBy1_4[4]] = [
      pointsDividedBy1_4[5],
      pointsDividedBy1_4[7],
      pointsDividedBy2_4[4],
      points[4]
    ];
    possibleMovePoints[pointsDividedBy1_4[5]] = [
      pointsDividedBy1_4[3],
      pointsDividedBy1_4[4],
      pointsDividedBy2_4[5],
      points[5]
    ];
    possibleMovePoints[pointsDividedBy1_4[6]] = [
      pointsDividedBy1_4[0],
      pointsDividedBy1_4[3],
      pointsDividedBy2_4[6],
      points[6]
    ];
    possibleMovePoints[pointsDividedBy1_4[7]] = [
      pointsDividedBy1_4[2],
      pointsDividedBy1_4[4],
      pointsDividedBy2_4[7],
      points[7]
    ];

    possibleMovePoints[pointsDividedBy2_4[0]] = [
      pointsDividedBy2_4[1],
      pointsDividedBy2_4[6],
      pointsDividedBy1_4[0]
    ];
    possibleMovePoints[pointsDividedBy2_4[1]] = [
      pointsDividedBy2_4[0],
      pointsDividedBy2_4[2],
      pointsDividedBy1_4[1]
    ];
    possibleMovePoints[pointsDividedBy2_4[2]] = [
      pointsDividedBy2_4[1],
      pointsDividedBy2_4[7],
      pointsDividedBy1_4[2]
    ];
    possibleMovePoints[pointsDividedBy2_4[3]] = [
      pointsDividedBy2_4[6],
      pointsDividedBy2_4[5],
      pointsDividedBy1_4[3]
    ];
    possibleMovePoints[pointsDividedBy2_4[4]] = [
      pointsDividedBy2_4[5],
      pointsDividedBy2_4[7],
      pointsDividedBy1_4[4]
    ];
    possibleMovePoints[pointsDividedBy2_4[5]] = [
      pointsDividedBy2_4[3],
      pointsDividedBy2_4[4],
      pointsDividedBy1_4[5]
    ];
    possibleMovePoints[pointsDividedBy2_4[6]] = [
      pointsDividedBy2_4[0],
      pointsDividedBy2_4[3],
      pointsDividedBy1_4[6]
    ];
    possibleMovePoints[pointsDividedBy2_4[7]] = [
      pointsDividedBy2_4[2],
      pointsDividedBy2_4[4],
      pointsDividedBy1_4[7]
    ];

    for (Offset point in points) {
      nodeScales[point] = 1;
    }
    setState(() {});
  }

  bool isTripplesSuitableToGetNode(Offset point) {
    Color startingColor = nodeColorDict[point] ?? Colors.white;
    print(startingColor);

    bool allMatch = true;

    if (!isInTripple(point)) return true;
    for (int i = 0; i < points.length; i++) {
      if (nodeColorDict[points[i]] == startingColor &&
          (!isInTripple(points[i]))) {
        allMatch = false;
        break;
      }
    }
    if (allMatch) return true;
    return !isInTripple(point);
  }

  bool isInTripple(Offset point) {
    Color startingColor = nodeColorDict[point] ?? Colors.white;
    List<List<Offset>> possibleControllList = possibleControls[point]!;
    for (List<Offset> offsets in possibleControllList) {
      bool allMatch = true;
      for (Offset offset in offsets) {
        if (nodeColorDict[offset] != startingColor) {
          allMatch = false;
          break;
        }
      }
      if (allMatch) {
        return true;
      }
    }
    return false;
  }

  void handleTap(Offset point) {
    (counterToGetNodesFromOpponent > 0 &&
        nodeColorDict[point] ==
            (tapIndex % 2 == 0
                ? RetroColors.lightBlueAccent
                : RetroColors.redAccent) &&
        (isTripplesSuitableToGetNode(point)))
        ? setState(() {
      nodeColorDict[point] = Colors.white;
      counterToGetNodesFromOpponent--;
    })
        : (counterToGetNodesFromOpponent > 0 &&
        nodeColorDict[point] !=
            (tapIndex % 2 == 0
                ? RetroColors.lightBlueAccent
                : RetroColors.redAccent))
        ? print(
        "you should choose one of the ${tapIndex % 2 == 0 ? "blue" : "red"} ones to get your opponent's node")
        : (tapIndex < 24 && nodeColorDict[point] == Colors.white)
        ? setState(() {
      nodeColorDict[point] = tapIndex++ % 2 == 0
          ? RetroColors.lightBlueAccent
          : RetroColors.redAccent;
      checkWin(point);
    })
        : null;
  }

  void handleDrag(DraggableDetails details, Offset point,BuildContext context) {
    if (tapIndex > 23 &&
        nodeColorDict[point] ==
            (tapIndex % 2 == 0
                ? RetroColors.lightBlueAccent
                : RetroColors.redAccent)) {
      print(counterToGetNodesFromOpponent);
      setState(() {
        Offset draggedPosition = details.offset;
        draggedPosition =
            Offset(draggedPosition.dx - 10, draggedPosition.dy -  (MediaQuery.of(context).size.height/7+50+20));
        print(draggedPosition);

        Offset? closestPoint;
        double closestDistance = double.infinity;

        for (var nodePoint in points) {
          double distance = (nodePoint.dx - draggedPosition.dx).abs() +
              (nodePoint.dy - draggedPosition.dy).abs();
          if (distance < closestDistance) {
            closestDistance = distance;
            closestPoint = nodePoint;
          }
        }
        print(closestPoint);
        if(closestPoint==point) return;
        if (((tapIndex % 2 == 0 ? oScore : xScore)) >= 9 &&
            closestPoint != null&& closestPoint!=point) {
          tapIndex++;
          Color tempColor = nodeColorDict[point] ?? Colors.white;
          nodeColorDict[point] = nodeColorDict[closestPoint] ?? Colors.white;
          nodeColorDict[closestPoint] = tempColor;
          checkWin(closestPoint);
          return;
        }
        List<Offset> possibleMovePointsOfPoint = possibleMovePoints[point]!;
        bool allmatch = true;
        for (int i = 0; i < possibleMovePointsOfPoint.length; i++) {
          if(nodeColorDict[possibleMovePointsOfPoint[i]] == Colors.white){
            allmatch = false;
            break;
          }
        }
        if (allmatch) {
          if (counterToGetNodesFromOpponent == 0 &&
              closestPoint != null &&
              nodeColorDict[closestPoint] == Colors.white) {
            tapIndex++;
            Color tempColor = nodeColorDict[point] ?? Colors.white;
            nodeColorDict[point] = nodeColorDict[closestPoint] ?? Colors.white;
            nodeColorDict[closestPoint] = tempColor;
            checkWin(closestPoint);
          }
        } else if (counterToGetNodesFromOpponent == 0 &&
            closestPoint != null &&
            nodeColorDict[closestPoint] == Colors.white &&
            possibleMovePoints[point]!.contains(closestPoint)) {
          tapIndex++;
          Color tempColor = nodeColorDict[point] ?? Colors.white;
          nodeColorDict[point] = nodeColorDict[closestPoint] ?? Colors.white;
          nodeColorDict[closestPoint] = tempColor;
          checkWin(closestPoint);
        }
      });
    }
  }

  void giveDetails(DragUpdateDetails details,Offset point){

  }

  int xScore = 0;
  int oScore = 0;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Stack(
      children: [
        Positioned.fill(
          child: globalBackgroundImage,
        ),
        Positioned(
          top: screenHeight / 15,
          left: 20,
          child: BackButtonWidget(),
        ),
        Positioned(
          top: screenHeight / 7,
          width: screenWidth,
          child: Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  TextBoxWidget(
                    text: "${xScore}",
                    height: 50,
                    width: 50,
                    color: RetroColors.lightBlueAccent,
                    borderColor: RetroColors.background,
                  ),
                  if (tapIndex <24)
                    TextBoxWidget(
                      fontSize: 12,
                      text: "LEFT\nTOUR\n${(-tapIndex/2).truncate()+12} ",
                      height: 50,
                      width: 90,
                    ),
                  if (counterToGetNodesFromOpponent != 0)
                    TextBoxWidget(
                      text: "${counterToGetNodesFromOpponent} ",
                      height: 50,
                      width: 90,
                    ),
                  TextBoxWidget(
                    text: "${oScore}",
                    height: 50,
                    width: 50,
                    color: RetroColors.redAccent,
                    borderColor: RetroColors.background,
                  ),
                ],
              ),
              Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Container(
                      width: bigRectangleWidth,
                      height: bigRectangleHeight,
                      decoration: BoxDecoration(
                          border: Border.all(
                              color: RetroColors.greenAccent, width: 4),
                          color: RetroColors.transparentBlack),
                      child: Stack(
                        children: [
                          Center(
                            child: Container(
                              width: bigRectangleWidth / 1.4,
                              height: bigRectangleHeight / 1.4,
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: RetroColors.greenAccent, width: 4),
                              ),
                              child: Stack(
                                children: [
                                  Center(
                                    child: Container(
                                      width: bigRectangleWidth / 2.4,
                                      height: bigRectangleHeight / 2.4,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: RetroColors.greenAccent,
                                            width: 4),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ...points.map((point) {
                    return Positioned(
                      left: point.dx,
                      top: point.dy,
                      child: AnimatedScale(
                        scale: nodeScales[point]!,
                        duration: Duration(milliseconds: 400),
                        child: GestureDetector(
                          onTap: () {
                            handleTap(point);
                          },
                          child: Draggable(
                            feedback: Container(
                              width: 75,
                              height: 75,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    nodeColorDict[point] ?? Colors.white,
                                    (nodeColorDict[point] ?? Colors.white)
                                        .withOpacity(0.8),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: (nodeColorDict[point] ?? Colors.grey)
                                        .withOpacity(0.5),
                                    blurRadius: 8,
                                    offset: Offset(2, 2), // Hafif gölge
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.circle,
                                  size: 15,
                                  color: Colors.white
                                      .withOpacity(0.7), // Hafif simge
                                ),
                              ),
                            ),
                            child: Container(
                              width: 45,
                              height: 45,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    nodeColorDict[point] ?? Colors.white,
                                    (nodeColorDict[point] ?? Colors.white)
                                        .withOpacity(0.8),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: (nodeColorDict[point] ?? Colors.grey)
                                        .withOpacity(0.5),
                                    blurRadius: 8,
                                    offset: Offset(2, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.circle,
                                  size: 18,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                            ),
                            onDragUpdate: (details)=>giveDetails(details,point),
                            childWhenDragging: SizedBox(),
                            onDragEnd: (details) => handleDrag(details, point,context),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class LinePainter extends CustomPainter {
  final Offset start;
  final Offset end;

  LinePainter(this.start, this.end);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = RetroColors.greenAccent
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(start, end, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
