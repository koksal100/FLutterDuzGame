import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tictactoegame/Common/colors.dart';
import 'package:collection/collection.dart';
import 'package:tictactoegame/Common/widgets/BackButtonWidget.dart';
import 'package:tictactoegame/Common/widgets/TextBoxWidget.dart';
import 'package:tictactoegame/Presentation/GameGrid/OpponentlPlayer.dart';
import 'package:tictactoegame/main.dart';

class GameGrid extends StatefulWidget {
  final int gridSize;
  final String opponentDifficulty;

  GameGrid({required this.gridSize, required this.opponentDifficulty});

  @override
  _GameGridState createState() => _GameGridState();
}

class _GameGridState extends State<GameGrid> {
  List<List<String>> grid = [];
  List<List<int>> winningTriplets = [];
  List<List<double>> scaleGrid = [];
  int tapIndex = 0;
  int xScore = 0;
  int oScore = 0;
  late Player p;
  bool myTurn = true;
  List<dynamic> results = [];
  Map<List<double>, List<int>> resultMap = {};

  @override
  void initState() {
    super.initState();
    grid = List.generate(
      widget.gridSize,
      (_) => List.generate(widget.gridSize, (_) => ''),
    );

    scaleGrid = List.generate(
      widget.gridSize,
      (_) => List.generate(widget.gridSize, (_) => 1),
    );

    switch (widget.opponentDifficulty) {
      case ("Hard"):
        p = HardPlayer(grid, 2, 2.1, 1, 1);
      case ("Medium"):
        p = MediumPlayer(grid, 2, 2, 1, 1);
      case ("Easy"):
        p = EasyPlayer(grid, 2, 2, 1, 1);
    }
    //startSimulation(HardPlayer(grid, 2, 2.1, 1, 1), HardPlayer(grid, 2, 2.1, 1, 2.1/2));
  }

  Future<List<double>> startSimulation(Player p1, Player p2) async {
    tapIndex = 0;
    xScore = 0;
    oScore = 0;
    for (int i = 0; i < (grid.length * grid.length) / 2; i++) {
      await Future.delayed(Duration(milliseconds: 500));
      List<int> Decision = p1.tap();
      setState(() {
        if (grid[Decision[0]][Decision[1]] == '') {
          grid[Decision[0]][Decision[1]] = tapIndex++ % 2 == 0 ? 'X' : 'O';
        }
      });
      _checkWin();
      Decision = p2.tap();
      print("opponent decision : ${Decision}");
      setState(() {
        if (grid[Decision[0]][Decision[1]] == '') {
          grid[Decision[0]][Decision[1]] = tapIndex++ % 2 == 0 ? 'X' : 'O';
        }
      });
      _checkWin();
    }
    return [xScore.toDouble(), oScore.toDouble()];
  }

  void _handleTap(int rowIndex, int colIndex) async {
    if (myTurn == false) return;
    if (grid[rowIndex][colIndex] == '') {
      grid[rowIndex][colIndex] = tapIndex++ % 2 == 0 ? 'X' : 'O';
      setState(() {
        myTurn = false;
      });
    } else {
      print("yanlış yere tıkladın");
      return;
    }
    _checkWin();
    List<int> opponentDecision = p.tap();
    await Future.delayed(Duration(seconds: 1));
    print("opponent decision : ${opponentDecision}");
    setState(() {
      if (grid[opponentDecision[0]][opponentDecision[1]] == '') {
        grid[opponentDecision[0]][opponentDecision[1]] =
            tapIndex++ % 2 == 0 ? 'X' : 'O';
      }
    });
    _checkWin();
    setState(() {
      myTurn = true;
    });
  }

  void _checkWin() {
    for (int rowIndex = 0; rowIndex < widget.gridSize; rowIndex++) {
      for (int colIndex = 0; colIndex < widget.gridSize; colIndex++) {
        String currentCell = grid[rowIndex][colIndex];
        if (currentCell == '') continue; // Eğer boşsa devam et

        // Yatay kontrol
        if (colIndex + 2 < widget.gridSize &&
            currentCell == grid[rowIndex][colIndex + 1] &&
            currentCell == grid[rowIndex][colIndex + 2]) {
          List<int> triplet = [
            rowIndex,
            colIndex,
            rowIndex,
            colIndex + 1,
            rowIndex,
            colIndex + 2
          ];
          if (!_isTripletExists(triplet)) {
            winningTriplets.add(triplet);
            print(
                "Yatay kazanan: $currentCell (Row: $rowIndex, Col: $colIndex)");
            _updateScaleGrid(triplet);
          }
        }

        // Dikey kontrol
        if (rowIndex + 2 < widget.gridSize &&
            currentCell == grid[rowIndex + 1][colIndex] &&
            currentCell == grid[rowIndex + 2][colIndex]) {
          List<int> triplet = [
            rowIndex,
            colIndex,
            rowIndex + 1,
            colIndex,
            rowIndex + 2,
            colIndex
          ];
          if (!_isTripletExists(triplet)) {
            winningTriplets.add(triplet);
            print(
                "Dikey kazanan: $currentCell (Row: $rowIndex, Col: $colIndex)");

            // Kazanan üçlüdeki hücrelerin scaleGrid değerini değiştir
            _updateScaleGrid(triplet);
          }
        }

        // Sağ üst çapraz kontrol
        if (rowIndex + 2 < widget.gridSize &&
            colIndex + 2 < widget.gridSize &&
            currentCell == grid[rowIndex + 1][colIndex + 1] &&
            currentCell == grid[rowIndex + 2][colIndex + 2]) {
          List<int> triplet = [
            rowIndex,
            colIndex,
            rowIndex + 1,
            colIndex + 1,
            rowIndex + 2,
            colIndex + 2
          ];
          if (!_isTripletExists(triplet)) {
            winningTriplets.add(triplet);
            print(
                "Sağ üst çapraz kazanan: $currentCell (Row: $rowIndex, Col: $colIndex)");

            // Kazanan üçlüdeki hücrelerin scaleGrid değerini değiştir
            _updateScaleGrid(triplet);
          }
        }

        // Sağ alt çapraz kontrol
        if (rowIndex - 2 >= 0 &&
            colIndex + 2 < widget.gridSize &&
            currentCell == grid[rowIndex - 1][colIndex + 1] &&
            currentCell == grid[rowIndex - 2][colIndex + 2]) {
          List<int> triplet = [
            rowIndex,
            colIndex,
            rowIndex - 1,
            colIndex + 1,
            rowIndex - 2,
            colIndex + 2
          ];
          if (!_isTripletExists(triplet)) {
            winningTriplets.add(triplet);
            print(
                "Sağ alt çapraz kazanan: $currentCell (Row: $rowIndex, Col: $colIndex)");
            // Kazanan üçlüdeki hücrelerin scaleGrid değerini değiştir
            _updateScaleGrid(triplet);
          }
        }
      }
    }
  }

  Future<void> _updateScaleGrid(List<int> triplet) async {
    tapIndex % 2 == 1 ? xScore++ : oScore++;
    for (int i = 0; i < 3; i++) {
      setState(() {
        for (int j = 0; j < triplet.length; j += 2) {
          int row = triplet[j];
          int col = triplet[j + 1];
          scaleGrid[row][col] = 0.4;
        }
      });

      // 1 saniye bekle
      await Future.delayed(Duration(milliseconds: 200));

      setState(() {
        // Tripletteki hücreleri tekrar 1 yap (normal boyut)
        for (int j = 0; j < triplet.length; j += 2) {
          int row = triplet[j];
          int col = triplet[j + 1];
          scaleGrid[row][col] = 1.0;
        }
      });

      // 1 saniye bekle
      await Future.delayed(Duration(milliseconds: 200));
    }
  }

  bool _isTripletExists(List<int> triplet) {
    for (var existingTriplet in winningTriplets) {
      if (ListEquality().equals(existingTriplet, triplet)) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    final screenHeight = MediaQuery
        .of(context)
        .size
        .height;
    return Stack(
      children: [
        Positioned.fill(
          child: globalBackgroundImage,
        ),
        Positioned(top: screenHeight/15,left: 20,child: BackButtonWidget(),),

        Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              TextBoxWidget(
                text: "${xScore}",
                height: 50,
                width: 50,
                color: RetroColors.greenAccent,
                borderColor: RetroColors.background,
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
          SizedBox(
            height: 20,
          ),
          AspectRatio(
            aspectRatio: widget.gridSize == 8
                ? 0.8
                : widget.gridSize == 7
                    ? 0.9
                    : 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.gridSize,
                (rowIndex) => Expanded(
                  child: Row(
                    children: List.generate(
                      widget.gridSize,
                      (colIndex) => Expanded(
                        child: GestureDetector(
                          onTap: () => _handleTap(rowIndex, colIndex),
                          child: Container(
                            decoration: BoxDecoration(
                              color: RetroColors.transparentBlack,
                              border: Border.all(
                                color: RetroColors.white,
                                width: 2.0,
                              ),
                            ),
                            child: Center(
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: AnimatedScale(
                                  scale: scaleGrid[rowIndex][colIndex],
                                  duration: Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                  child: Text(
                                    grid[rowIndex][colIndex],
                                    // "X" veya "O"
                                    style: TextStyle(
                                      fontFamily: "Georgia",
                                      color: grid[rowIndex][colIndex] == 'X'
                                          ? RetroColors.greenAccent
                                          : RetroColors.redAccent,
                                      // Yazı rengi
                                      fontSize: 200 / widget.gridSize,
                                      // Hücre boyutuna göre yazı boyutu
                                      fontWeight: FontWeight.bold,
                                      // Yazıyı kalın yap
                                      shadows: [
                                        Shadow(
                                          blurRadius: 1.0,
                                          color: RetroColors.white,
                                        ),
                                      ], // Yazıya gölge efekti ekleyin
                                      decoration: TextDecoration.none, // Alt çizgiyi kaldırır

                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),]
    );
  }
}
