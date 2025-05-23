import 'package:flutter/cupertino.dart';

abstract class Player {
  final double riskCoefficient;
  final double opportunityCoefficient;
  final double oneStepRiskCoefficient;
  final double oneStepOpportunityCoefficient;

  List<List<String>> grid = [];
  List<List<double>> riskGrid = [];
  List<List<double>> opportunityGrid = [];
  List<List<double>> totalGrid = [];
  double riskMax = 0;
  double opportunityMax = 0;
  double totalMax = 0;
  List<int> riskMaxLoc = [0, 0];
  List<int> opportunityMaxLoc = [0, 0];
  List<int> totalMaxLoc = [0, 0];

  Player(
    this.grid, {
    this.riskCoefficient = 2.0,
    this.opportunityCoefficient = 2.1,
    this.oneStepRiskCoefficient = 1.0,
    this.oneStepOpportunityCoefficient = 1.0,
  }) {
    if (grid.isEmpty || grid.any((row) => row.isEmpty)) {
      throw ArgumentError("Grid cannot be empty or have empty rows.");
    }

    int gridSize = grid.length;
    riskGrid = List.generate(gridSize, (_) => List.filled(gridSize, 0));
    opportunityGrid = List.generate(gridSize, (_) => List.filled(gridSize, 0));
    totalGrid = List.generate(gridSize, (_) => List.filled(gridSize, 0));
  }

  void CalculateRisk();

  void CalculateOpportunity();

  List<int> tap() {
    bool isDecisionChanged = false;
    CalculateRisk();
    CalculateOpportunity();
    for (int rowIndex = 0; rowIndex < grid.length; rowIndex++) {
      for (int colIndex = 0; colIndex < grid.length; colIndex++) {
        totalGrid[rowIndex][colIndex] =
            riskGrid[rowIndex][colIndex] + opportunityGrid[rowIndex][colIndex];
      }
    }
    print(opportunityGrid);
    print(riskGrid);

    for (int rowIndex = 0; rowIndex < grid.length; rowIndex++) {
      for (int colIndex = 0; colIndex < grid.length; colIndex++) {
        if (opportunityGrid[rowIndex][colIndex] > opportunityMax) {
          opportunityMax = opportunityGrid[rowIndex][colIndex];
          opportunityMaxLoc = [rowIndex, colIndex];
        }
        if (riskGrid[rowIndex][colIndex] > riskMax) {
          riskMax = riskGrid[rowIndex][colIndex];
          riskMaxLoc = [rowIndex, colIndex];
        }
        if (totalGrid[rowIndex][colIndex] >= totalMax &&
            grid[rowIndex][colIndex] == "") {
          totalMax = totalGrid[rowIndex][colIndex];
          totalMaxLoc = [rowIndex, colIndex];
          isDecisionChanged = true;
        }
      }
    }

    for (int rowIndex = 0; rowIndex < grid.length; rowIndex++) {
      for (int colIndex = 0; colIndex < grid.length; colIndex++) {
        riskGrid[rowIndex][colIndex] = 0;
        opportunityGrid[rowIndex][colIndex] = 0;
        totalGrid[rowIndex][colIndex] = 0;
      }
    }
    totalMax = 0;
    opportunityMax = 0;
    riskMax = 0;
    return totalMaxLoc;
  }
}

class EasyPlayer extends Player {
  EasyPlayer(List<List<String>> grid, double riskCoefficient,
      double opportunityCoefficient,
      double oneStepRiskCoefficient,
      double oneStepOpportunityCoefficient)
      : super(
          grid,
          riskCoefficient: riskCoefficient,
          opportunityCoefficient: opportunityCoefficient,
    oneStepRiskCoefficient: oneStepRiskCoefficient,
    oneStepOpportunityCoefficient: oneStepOpportunityCoefficient
        );

  void CalculateRisk() {
    for (int rowIndex = 0; rowIndex < grid.length; rowIndex++) {
      for (int colIndex = 0; colIndex < grid.length; colIndex++) {
        String currentCell = grid[rowIndex][colIndex];
        if (currentCell != '') continue;

        // Yatay kontrol
        if (colIndex + 2 < grid.length &&
            'X' == grid[rowIndex][colIndex + 1] &&
            'X' == grid[rowIndex][colIndex + 2]) {
          riskGrid[rowIndex][colIndex] += riskCoefficient;
        }

        if (colIndex - 2 >= 0 &&
            'X' == grid[rowIndex][colIndex - 1] &&
            'X' == grid[rowIndex][colIndex - 2]) {
          riskGrid[rowIndex][colIndex] += riskCoefficient;
        }

        if (colIndex != 0 &&
            colIndex + 1 < grid.length &&
            'X' == grid[rowIndex][colIndex + 1] &&
            'X' == grid[rowIndex][colIndex - 1]) {
          riskGrid[rowIndex][colIndex] += riskCoefficient;
        }

        // Dikey kontrol
        if (rowIndex + 2 < grid.length &&
            'X' == grid[rowIndex + 1][colIndex] &&
            'X' == grid[rowIndex + 2][colIndex]) {
          riskGrid[rowIndex][colIndex] += riskCoefficient;
        }

        if (rowIndex >= 2 &&
            'X' == grid[rowIndex - 1][colIndex] &&
            'X' == grid[rowIndex - 2][colIndex]) {
          riskGrid[rowIndex][colIndex] += riskCoefficient;
        }

        if (rowIndex != 0 &&
            rowIndex + 1 < grid.length &&
            colIndex + 1 < grid.length &&
            'X' == grid[rowIndex - 1][colIndex] &&
            'X' == grid[rowIndex + 1][colIndex]) {
          riskGrid[rowIndex][colIndex] += riskCoefficient;
        }

        // Sağ üst çapraz kontrol
        if (rowIndex + 2 < grid.length &&
            colIndex + 2 < grid.length &&
            'X' == grid[rowIndex + 1][colIndex + 1] &&
            'X' == grid[rowIndex + 2][colIndex + 2]) {
          riskGrid[rowIndex][colIndex] += riskCoefficient;
        }

        if (rowIndex >= 2 &&
            colIndex >= 2 &&
            'X' == grid[rowIndex - 1][colIndex - 1] &&
            'X' == grid[rowIndex - 2][colIndex - 2]) {
          riskGrid[rowIndex][colIndex] += riskCoefficient;
        }

        if (rowIndex != 0 &&
            colIndex != 0 &&
            colIndex + 1 < grid.length &&
            rowIndex + 1 < grid.length &&
            'X' == grid[rowIndex - 1][colIndex - 1] &&
            'X' == grid[rowIndex + 1][colIndex + 1]) {
          riskGrid[rowIndex][colIndex] += riskCoefficient;
        }

        // Sağ alt çapraz kontrol
        if (rowIndex - 2 >= 0 &&
            colIndex + 2 < grid.length &&
            'X' == grid[rowIndex - 1][colIndex + 1] &&
            'X' == grid[rowIndex - 2][colIndex + 2]) {
          riskGrid[rowIndex][colIndex] += riskCoefficient;
        }

        if (rowIndex + 2 < grid.length &&
            colIndex >= 2 &&
            'X' == grid[rowIndex + 1][colIndex - 1] &&
            'X' == grid[rowIndex + 2][colIndex - 2]) {
          riskGrid[rowIndex][colIndex] += riskCoefficient;
        }

        if (rowIndex != 0 &&
            colIndex != 0 &&
            colIndex + 1 < grid.length &&
            rowIndex + 1 < grid.length &&
            'X' == grid[rowIndex - 1][colIndex + 1] &&
            'X' == grid[rowIndex + 1][colIndex - 1]) {
          riskGrid[rowIndex][colIndex] += riskCoefficient;
        }
      }
    }
  }

  void CalculateOpportunity() {
    for (int rowIndex = 0; rowIndex < grid.length; rowIndex++) {
      for (int colIndex = 0; colIndex < grid.length; colIndex++) {
        String currentCell = grid[rowIndex][colIndex];
        if (currentCell != '') continue;

        // Yatay kontrol
        if (colIndex + 2 < grid.length &&
            'O' == grid[rowIndex][colIndex + 1] &&
            'O' == grid[rowIndex][colIndex + 2]) {
          opportunityGrid[rowIndex][colIndex] += opportunityCoefficient;
        }

        if (colIndex - 2 >= 0 &&
            'O' == grid[rowIndex][colIndex - 1] &&
            'O' == grid[rowIndex][colIndex - 2]) {
          opportunityGrid[rowIndex][colIndex] += opportunityCoefficient;
        }

        if (colIndex != 0 &&
            colIndex + 1 < grid.length &&
            'O' == grid[rowIndex][colIndex + 1] &&
            'O' == grid[rowIndex][colIndex - 1]) {
          opportunityGrid[rowIndex][colIndex] += opportunityCoefficient;
        }

        // Dikey kontrol
        if (rowIndex + 2 < grid.length &&
            'O' == grid[rowIndex + 1][colIndex] &&
            'O' == grid[rowIndex + 2][colIndex]) {
          opportunityGrid[rowIndex][colIndex] += opportunityCoefficient;
        }

        if (rowIndex >= 2 &&
            'O' == grid[rowIndex - 1][colIndex] &&
            'O' == grid[rowIndex - 2][colIndex]) {
          opportunityGrid[rowIndex][colIndex] += opportunityCoefficient;
        }

        if (rowIndex != 0 &&
            rowIndex + 1 < grid.length &&
            'O' == grid[rowIndex - 1][colIndex] &&
            'O' == grid[rowIndex + 1][colIndex]) {
          opportunityGrid[rowIndex][colIndex] += opportunityCoefficient;
        }

        // Sağ üst çapraz kontrol
        if (rowIndex + 2 < grid.length &&
            colIndex + 2 < grid.length &&
            'O' == grid[rowIndex + 1][colIndex + 1] &&
            'O' == grid[rowIndex + 2][colIndex + 2]) {
          opportunityGrid[rowIndex][colIndex] += opportunityCoefficient;
        }

        if (rowIndex >= 2 &&
            colIndex >= 2 &&
            'O' == grid[rowIndex - 1][colIndex - 1] &&
            'O' == grid[rowIndex - 2][colIndex - 2]) {
          opportunityGrid[rowIndex][colIndex] += opportunityCoefficient;
        }

        if (rowIndex != 0 &&
            colIndex != 0 &&
            colIndex + 1 < grid.length &&
            rowIndex + 1 < grid.length &&
            'O' == grid[rowIndex - 1][colIndex - 1] &&
            'O' == grid[rowIndex + 1][colIndex + 1]) {
          opportunityGrid[rowIndex][colIndex] += opportunityCoefficient;
        }

        // Sağ alt çapraz kontrol
        if (rowIndex - 2 >= 0 &&
            colIndex + 2 < grid.length &&
            'O' == grid[rowIndex - 1][colIndex + 1] &&
            'O' == grid[rowIndex - 2][colIndex + 2]) {
          opportunityGrid[rowIndex][colIndex] += opportunityCoefficient;
        }

        if (rowIndex + 2 < grid.length &&
            colIndex >= 2 &&
            'O' == grid[rowIndex + 1][colIndex - 1] &&
            'O' == grid[rowIndex + 2][colIndex - 2]) {
          opportunityGrid[rowIndex][colIndex] += opportunityCoefficient;
        }

        if (rowIndex != 0 &&
            colIndex != 0 &&
            colIndex + 1 < grid.length &&
            rowIndex + 1 < grid.length &&
            'O' == grid[rowIndex - 1][colIndex + 1] &&
            'O' == grid[rowIndex + 1][colIndex - 1]) {
          opportunityGrid[rowIndex][colIndex] += opportunityCoefficient;
        }
      }
    }
  }
}

class MediumPlayer extends Player {
  MediumPlayer(List<List<String>> grid, double riskCoefficient,
      double opportunityCoefficient,
      double oneStepRiskCoefficient,
      double oneStepOpportunityCoefficient)
      : super(
      grid,
      riskCoefficient: riskCoefficient,
      opportunityCoefficient: opportunityCoefficient,
      oneStepRiskCoefficient: oneStepRiskCoefficient,
      oneStepOpportunityCoefficient: oneStepOpportunityCoefficient
  );

  void CalculateRisk() {
    for (int rowIndex = 0; rowIndex < grid.length; rowIndex++) {
      for (int colIndex = 0; colIndex < grid.length; colIndex++) {
        String currentCell = grid[rowIndex][colIndex];
        if (currentCell != '') continue;

        // Yatay kontrol
        if (colIndex + 2 < grid.length &&
            'X' == grid[rowIndex][colIndex + 1] &&
            'X' == grid[rowIndex][colIndex + 2]) {
          riskGrid[rowIndex][colIndex] += 2;
        }

        if (colIndex - 2 >= 0 &&
            'X' == grid[rowIndex][colIndex - 1] &&
            'X' == grid[rowIndex][colIndex - 2]) {
          riskGrid[rowIndex][colIndex] += 2;
        }

        if (colIndex != 0 &&
            colIndex + 1 < grid.length &&
            'X' == grid[rowIndex][colIndex + 1] &&
            'X' == grid[rowIndex][colIndex - 1]) {
          riskGrid[rowIndex][colIndex] += 2;
        }

        // Dikey kontrol
        if (rowIndex + 2 < grid.length &&
            'X' == grid[rowIndex + 1][colIndex] &&
            'X' == grid[rowIndex + 2][colIndex]) {
          riskGrid[rowIndex][colIndex] += 2;
        }

        if (rowIndex >= 2 &&
            'X' == grid[rowIndex - 1][colIndex] &&
            'X' == grid[rowIndex - 2][colIndex]) {
          riskGrid[rowIndex][colIndex] += 2;
        }

        if (rowIndex != 0 &&
            rowIndex + 1 < grid.length &&
            colIndex + 1 < grid.length &&
            'X' == grid[rowIndex - 1][colIndex] &&
            'X' == grid[rowIndex + 1][colIndex]) {
          riskGrid[rowIndex][colIndex] += 2;
        }

        // Sağ üst çapraz kontrol
        if (rowIndex + 2 < grid.length &&
            colIndex + 2 < grid.length &&
            'X' == grid[rowIndex + 1][colIndex + 1] &&
            'X' == grid[rowIndex + 2][colIndex + 2]) {
          riskGrid[rowIndex][colIndex] += 2;
        }

        if (rowIndex >= 2 &&
            colIndex >= 2 &&
            'X' == grid[rowIndex - 1][colIndex - 1] &&
            'X' == grid[rowIndex - 2][colIndex - 2]) {
          riskGrid[rowIndex][colIndex] += 2;
        }

        if (rowIndex != 0 &&
            colIndex != 0 &&
            colIndex + 1 < grid.length &&
            rowIndex + 1 < grid.length &&
            'X' == grid[rowIndex - 1][colIndex - 1] &&
            'X' == grid[rowIndex + 1][colIndex + 1]) {
          riskGrid[rowIndex][colIndex] += 2;
        }

        // Sağ alt çapraz kontrol
        if (rowIndex - 2 >= 0 &&
            colIndex + 2 < grid.length &&
            'X' == grid[rowIndex - 1][colIndex + 1] &&
            'X' == grid[rowIndex - 2][colIndex + 2]) {
          riskGrid[rowIndex][colIndex] += 2;
        }

        if (rowIndex + 2 < grid.length &&
            colIndex >= 2 &&
            'X' == grid[rowIndex + 1][colIndex - 1] &&
            'X' == grid[rowIndex + 2][colIndex - 2]) {
          riskGrid[rowIndex][colIndex] += 2;
        }

        if (rowIndex != 0 &&
            colIndex != 0 &&
            colIndex + 1 < grid.length &&
            rowIndex + 1 < grid.length &&
            'X' == grid[rowIndex - 1][colIndex + 1] &&
            'X' == grid[rowIndex + 1][colIndex - 1]) {
          riskGrid[rowIndex][colIndex] += 2;
        }
      }
    }
  }

  void CalculateOpportunity() {
    for (int rowIndex = 0; rowIndex < grid.length; rowIndex++) {
      for (int colIndex = 0; colIndex < grid.length; colIndex++) {
        String currentCell = grid[rowIndex][colIndex];
        if (currentCell != '') continue;

        // Yatay kontrol
        if (colIndex + 2 < grid.length &&
            'O' == grid[rowIndex][colIndex + 1] &&
            'O' == grid[rowIndex][colIndex + 2]) {
          opportunityGrid[rowIndex][colIndex] += 2.1;
        }

        if (colIndex - 2 >= 0 &&
            'O' == grid[rowIndex][colIndex - 1] &&
            'O' == grid[rowIndex][colIndex - 2]) {
          opportunityGrid[rowIndex][colIndex] += 2.1;
        }

        if (colIndex != 0 &&
            colIndex + 1 < grid.length &&
            'O' == grid[rowIndex][colIndex + 1] &&
            'O' == grid[rowIndex][colIndex - 1]) {
          opportunityGrid[rowIndex][colIndex] += 2.1;
        }

        // Dikey kontrol
        if (rowIndex + 2 < grid.length &&
            'O' == grid[rowIndex + 1][colIndex] &&
            'O' == grid[rowIndex + 2][colIndex]) {
          opportunityGrid[rowIndex][colIndex] += 2.1;
        }

        if (rowIndex >= 2 &&
            'O' == grid[rowIndex - 1][colIndex] &&
            'O' == grid[rowIndex - 2][colIndex]) {
          opportunityGrid[rowIndex][colIndex] += 2.1;
        }

        if (rowIndex != 0 &&
            rowIndex + 1 < grid.length &&
            'O' == grid[rowIndex - 1][colIndex] &&
            'O' == grid[rowIndex + 1][colIndex]) {
          opportunityGrid[rowIndex][colIndex] += 2.1;
        }

        // Sağ üst çapraz kontrol
        if (rowIndex + 2 < grid.length &&
            colIndex + 2 < grid.length &&
            'O' == grid[rowIndex + 1][colIndex + 1] &&
            'O' == grid[rowIndex + 2][colIndex + 2]) {
          opportunityGrid[rowIndex][colIndex] += 2.1;
        }

        if (rowIndex >= 2 &&
            colIndex >= 2 &&
            'O' == grid[rowIndex - 1][colIndex - 1] &&
            'O' == grid[rowIndex - 2][colIndex - 2]) {
          opportunityGrid[rowIndex][colIndex] += 2.1;
        }

        if (rowIndex != 0 &&
            colIndex != 0 &&
            colIndex + 1 < grid.length &&
            rowIndex + 1 < grid.length &&
            'O' == grid[rowIndex - 1][colIndex - 1] &&
            'O' == grid[rowIndex + 1][colIndex + 1]) {
          opportunityGrid[rowIndex][colIndex] += 2.1;
        }

        // Sağ alt çapraz kontrol
        if (rowIndex - 2 >= 0 &&
            colIndex + 2 < grid.length &&
            'O' == grid[rowIndex - 1][colIndex + 1] &&
            'O' == grid[rowIndex - 2][colIndex + 2]) {
          opportunityGrid[rowIndex][colIndex] += 2.1;
        }

        if (rowIndex + 2 < grid.length &&
            colIndex >= 2 &&
            'O' == grid[rowIndex + 1][colIndex - 1] &&
            'O' == grid[rowIndex + 2][colIndex - 2]) {
          opportunityGrid[rowIndex][colIndex] += 2.1;
        }

        if (rowIndex != 0 &&
            colIndex != 0 &&
            colIndex + 1 < grid.length &&
            rowIndex + 1 < grid.length &&
            'O' == grid[rowIndex - 1][colIndex + 1] &&
            'O' == grid[rowIndex + 1][colIndex - 1]) {
          opportunityGrid[rowIndex][colIndex] += 2.1;
        }
      }
    }
  }
}

class HardPlayer extends Player {
  HardPlayer(List<List<String>> grid, double riskCoefficient,
      double opportunityCoefficient,
      double oneStepRiskCoefficient,
      double oneStepOpportunityCoefficient)
      : super(
      grid,
      riskCoefficient: riskCoefficient,
      opportunityCoefficient: opportunityCoefficient,
      oneStepRiskCoefficient: oneStepRiskCoefficient,
      oneStepOpportunityCoefficient: oneStepOpportunityCoefficient
  );

  void CalculateRisk() {
    for (int rowIndex = 0; rowIndex < grid.length; rowIndex++) {
      for (int colIndex = 0; colIndex < grid.length; colIndex++) {
        String currentCell = grid[rowIndex][colIndex];
        if (currentCell != '') continue;

        // Yatay kontrol
        if (colIndex + 2 < grid.length &&
            'X' == grid[rowIndex][colIndex + 1] &&
            'X' == grid[rowIndex][colIndex + 2]) {
          riskGrid[rowIndex][colIndex] += riskCoefficient;
        }

        if (colIndex - 2 >= 0 &&
            'X' == grid[rowIndex][colIndex - 1] &&
            'X' == grid[rowIndex][colIndex - 2]) {
          riskGrid[rowIndex][colIndex] += riskCoefficient;
        }

        if (colIndex != 0 &&
            colIndex + 1 < grid.length &&
            'X' == grid[rowIndex][colIndex + 1] &&
            'X' == grid[rowIndex][colIndex - 1]) {
          riskGrid[rowIndex][colIndex] += riskCoefficient;
        }

        // Dikey kontrol
        if (rowIndex + 2 < grid.length &&
            'X' == grid[rowIndex + 1][colIndex] &&
            'X' == grid[rowIndex + 2][colIndex]) {
          riskGrid[rowIndex][colIndex] += riskCoefficient;
        }

        if (rowIndex >= 2 &&
            'X' == grid[rowIndex - 1][colIndex] &&
            'X' == grid[rowIndex - 2][colIndex]) {
          riskGrid[rowIndex][colIndex] += riskCoefficient;
        }

        if (rowIndex != 0 &&
            rowIndex + 1 < grid.length &&
            colIndex + 1 < grid.length &&
            'X' == grid[rowIndex - 1][colIndex] &&
            'X' == grid[rowIndex + 1][colIndex]) {
          riskGrid[rowIndex][colIndex] += riskCoefficient;
        }

        // Sağ üst çapraz kontrol
        if (rowIndex + 2 < grid.length &&
            colIndex + 2 < grid.length &&
            'X' == grid[rowIndex + 1][colIndex + 1] &&
            'X' == grid[rowIndex + 2][colIndex + 2]) {
          riskGrid[rowIndex][colIndex] += riskCoefficient;
        }

        if (rowIndex >= 2 &&
            colIndex >= 2 &&
            'X' == grid[rowIndex - 1][colIndex - 1] &&
            'X' == grid[rowIndex - 2][colIndex - 2]) {
          riskGrid[rowIndex][colIndex] += riskCoefficient;
        }

        if (rowIndex != 0 &&
            colIndex != 0 &&
            colIndex + 1 < grid.length &&
            rowIndex + 1 < grid.length &&
            'X' == grid[rowIndex - 1][colIndex - 1] &&
            'X' == grid[rowIndex + 1][colIndex + 1]) {
          riskGrid[rowIndex][colIndex] += riskCoefficient;
        }

        // Sağ alt çapraz kontrol
        if (rowIndex - 2 >= 0 &&
            colIndex + 2 < grid.length &&
            'X' == grid[rowIndex - 1][colIndex + 1] &&
            'X' == grid[rowIndex - 2][colIndex + 2]) {
          riskGrid[rowIndex][colIndex] += riskCoefficient;
        }

        if (rowIndex + 2 < grid.length &&
            colIndex >= 2 &&
            'X' == grid[rowIndex + 1][colIndex - 1] &&
            'X' == grid[rowIndex + 2][colIndex - 2]) {
          riskGrid[rowIndex][colIndex] += riskCoefficient;
        }

        if (rowIndex != 0 &&
            colIndex != 0 &&
            colIndex + 1 < grid.length &&
            rowIndex + 1 < grid.length &&
            'X' == grid[rowIndex - 1][colIndex + 1] &&
            'X' == grid[rowIndex + 1][colIndex - 1]) {
          riskGrid[rowIndex][colIndex] += riskCoefficient;
        }
      }
    }
  }

  void CalculateOpportunity() {
    for (int rowIndex = 0; rowIndex < grid.length; rowIndex++) {
      for (int colIndex = 0; colIndex < grid.length; colIndex++) {
        String currentCell = grid[rowIndex][colIndex];
        if (currentCell != '') continue;

        // Yatay kontrol
        if (colIndex + 2 < grid.length &&
            'O' == grid[rowIndex][colIndex + 1] &&
            'O' == grid[rowIndex][colIndex + 2]) {
          opportunityGrid[rowIndex][colIndex] += opportunityCoefficient;
        }

        if (colIndex - 2 >= 0 &&
            'O' == grid[rowIndex][colIndex - 1] &&
            'O' == grid[rowIndex][colIndex - 2]) {
          opportunityGrid[rowIndex][colIndex] += opportunityCoefficient;
        }

        if (colIndex != 0 &&
            colIndex + 1 < grid.length &&
            'O' == grid[rowIndex][colIndex + 1] &&
            'O' == grid[rowIndex][colIndex - 1]) {
          opportunityGrid[rowIndex][colIndex] += opportunityCoefficient;
        }

        // Dikey kontrol
        if (rowIndex + 2 < grid.length &&
            'O' == grid[rowIndex + 1][colIndex] &&
            'O' == grid[rowIndex + 2][colIndex]) {
          opportunityGrid[rowIndex][colIndex] += opportunityCoefficient;
        }

        if (rowIndex >= 2 &&
            'O' == grid[rowIndex - 1][colIndex] &&
            'O' == grid[rowIndex - 2][colIndex]) {
          opportunityGrid[rowIndex][colIndex] += opportunityCoefficient;
        }

        if (rowIndex != 0 &&
            rowIndex + 1 < grid.length &&
            'O' == grid[rowIndex - 1][colIndex] &&
            'O' == grid[rowIndex + 1][colIndex]) {
          opportunityGrid[rowIndex][colIndex] += opportunityCoefficient;
        }

        // Sağ üst çapraz kontrol
        if (rowIndex + 2 < grid.length &&
            colIndex + 2 < grid.length &&
            'O' == grid[rowIndex + 1][colIndex + 1] &&
            'O' == grid[rowIndex + 2][colIndex + 2]) {
          opportunityGrid[rowIndex][colIndex] += opportunityCoefficient;
        }

        if (rowIndex >= 2 &&
            colIndex >= 2 &&
            'O' == grid[rowIndex - 1][colIndex - 1] &&
            'O' == grid[rowIndex - 2][colIndex - 2]) {
          opportunityGrid[rowIndex][colIndex] += opportunityCoefficient;
        }

        if (rowIndex != 0 &&
            colIndex != 0 &&
            colIndex + 1 < grid.length &&
            rowIndex + 1 < grid.length &&
            'O' == grid[rowIndex - 1][colIndex - 1] &&
            'O' == grid[rowIndex + 1][colIndex + 1]) {
          opportunityGrid[rowIndex][colIndex] += opportunityCoefficient;
        }

        // Sağ alt çapraz kontrol
        if (rowIndex - 2 >= 0 &&
            colIndex + 2 < grid.length &&
            'O' == grid[rowIndex - 1][colIndex + 1] &&
            'O' == grid[rowIndex - 2][colIndex + 2]) {
          opportunityGrid[rowIndex][colIndex] += opportunityCoefficient;
        }

        if (rowIndex + 2 < grid.length &&
            colIndex >= 2 &&
            'O' == grid[rowIndex + 1][colIndex - 1] &&
            'O' == grid[rowIndex + 2][colIndex - 2]) {
          opportunityGrid[rowIndex][colIndex] += opportunityCoefficient;
        }

        if (rowIndex != 0 &&
            colIndex != 0 &&
            colIndex + 1 < grid.length &&
            rowIndex + 1 < grid.length &&
            'O' == grid[rowIndex - 1][colIndex + 1] &&
            'O' == grid[rowIndex + 1][colIndex - 1]) {
          opportunityGrid[rowIndex][colIndex] += opportunityCoefficient;
        }
      }
    }
  }

  void calculateTwoStepRisk() {}

  void oneStepUpdateOpportunityMatrix(List<List<String>> grid) {
    int n = grid.length; // Grid'in boyutu (kare şeklinde olduğu varsayılıyor)

    // Yön vektörleri: yukarı, aşağı, sağ, sol ve dört çapraz yön
    List<List<int>> directions = [
      [-2, 0],
      [2, 0],
      [0, 2],
      [0, -2],
      // Yukarı, aşağı, sağ, sol
      [-2, 2],
      [-2, -2],
      [2, 2],
      [2, -2]
      // Sağ üst çapraz, sol üst çapraz, sağ alt çapraz, sol alt çapraz
    ];

    for (int i = 0; i < n; i++) {
      for (int j = 0; j < n; j++) {
        if (grid[i][j] == "O") {
          for (int k = 0; k < directions.length; k++) {
            int x1 = i + directions[k][0];
            int y1 = j + directions[k][1];
            int x2 = i + ((directions[k][0]) / 2).toInt();
            int y2 = i + ((directions[k][1]) / 2).toInt();

            // İlk noktanın grid sınırları içinde olup olmadığını kontrol et
            if ((x1 >= 0 && x1 < n && y1 >= 0 && y1 < n) &&
                (x2 >= 0 && x2 < n && y2 >= 0 && y2 < n)) {
              if ((grid[x1][y1] == "") && (grid[x2][y2] == "")) {
                print("iki adımlı fırsat tespit edildi");
                opportunityGrid[x1][y1] += oneStepOpportunityCoefficient;
                opportunityGrid[x2][y2] += oneStepOpportunityCoefficient;
              }
            }
          }
        }
      }
    }
  }

  void oneStepUpdateRiskMatrix(List<List<String>> grid) {
    int n = grid.length; // Grid'in boyutu (kare şeklinde olduğu varsayılıyor)

    // Yön vektörleri: yukarı, aşağı, sağ, sol ve dört çapraz yön
    List<List<int>> directions = [
      [-2, 0],
      [2, 0],
      [0, 2],
      [0, -2],
      // Yukarı, aşağı, sağ, sol
      [-2, 2],
      [-2, -2],
      [2, 2],
      [2, -2]
      // Sağ üst çapraz, sol üst çapraz, sağ alt çapraz, sol alt çapraz
    ];

    for (int i = 0; i < n; i++) {
      for (int j = 0; j < n; j++) {
        if (grid[i][j] == "X") {
          for (int k = 0; k < directions.length; k++) {
            int x1 = i + directions[k][0];
            int y1 = j + directions[k][1];
            int x2 = i + ((directions[k][0]) / 2).toInt();
            int y2 = i + ((directions[k][1]) / 2).toInt();

            // İlk noktanın grid sınırları içinde olup olmadığını kontrol et
            if ((x1 >= 0 && x1 < n && y1 >= 0 && y1 < n) &&
                (x2 >= 0 && x2 < n && y2 >= 0 && y2 < n)) {
              if ((grid[x1][y1] == "") && (grid[x2][y2] == "")) {
                print("iki adımlı risk tespit edildi");
                riskGrid[x1][y1] += oneStepRiskCoefficient;
                riskGrid[x2][y2] += oneStepRiskCoefficient;
              }
            }
          }
        }
      }
    }
  }

  List<int> tap() {
    bool isDecisionChanged = false;
    CalculateRisk();
    CalculateOpportunity();
    oneStepUpdateOpportunityMatrix(grid);
    oneStepUpdateRiskMatrix(grid);
    for (int rowIndex = 0; rowIndex < grid.length; rowIndex++) {
      for (int colIndex = 0; colIndex < grid.length; colIndex++) {
        totalGrid[rowIndex][colIndex] =
            riskGrid[rowIndex][colIndex] + opportunityGrid[rowIndex][colIndex];
      }
    }
    print(opportunityGrid);
    print(riskGrid);

    for (int rowIndex = 0; rowIndex < grid.length; rowIndex++) {
      for (int colIndex = 0; colIndex < grid.length; colIndex++) {
        if (opportunityGrid[rowIndex][colIndex] > opportunityMax) {
          opportunityMax = opportunityGrid[rowIndex][colIndex];
          opportunityMaxLoc = [rowIndex, colIndex];
        }
        if (riskGrid[rowIndex][colIndex] > riskMax) {
          riskMax = riskGrid[rowIndex][colIndex];
          riskMaxLoc = [rowIndex, colIndex];
        }
        if (totalGrid[rowIndex][colIndex] >= totalMax &&
            grid[rowIndex][colIndex] == "") {
          totalMax = totalGrid[rowIndex][colIndex];
          totalMaxLoc = [rowIndex, colIndex];
          isDecisionChanged = true;
        }
      }
    }

    for (int rowIndex = 0; rowIndex < grid.length; rowIndex++) {
      for (int colIndex = 0; colIndex < grid.length; colIndex++) {
        riskGrid[rowIndex][colIndex] = 0;
        opportunityGrid[rowIndex][colIndex] = 0;
        totalGrid[rowIndex][colIndex] = 0;
      }
    }

    totalMax = 0;
    opportunityMax = 0;
    riskMax = 0;
    return totalMaxLoc;
  }
}
