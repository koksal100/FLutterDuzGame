import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  List<Offset> points = [];
  List<Offset> pointsDividedBy1_4 = [];
  List<Offset> pointsDividedBy2_4 = [];
  Map<Offset, Color> nodeColorDict = {};
  int counterToGetNodesFromOpponent = 0;
  String myColor="";
  String opponentColor="";
  int myScore = 0;
  int opponentScore = 0;
  //////////////////////////
  bool readyToGame = false;
  bool myTurn = false;
  String myRole = "";
  String myRoomId = "";
  String? myOpponentId = "";
  late DocumentReference roomDoc;
  ////////////////////////////////

  void listenNextMove(Offset MyMove) async {
    print("karşı tarafı dinliyorum");
    StreamSubscription<DocumentSnapshot>? subscription;
    // Dinlemeyi başlat
    subscription = roomDoc.snapshots().listen((documentSnapshot) {
      if (documentSnapshot.exists) {
        Map<String, dynamic> data =
        documentSnapshot.data() as Map<String, dynamic>;

        // nextMove field'ını kontrol et
        if (data.containsKey('nextMove')) {
          Offset nextMove = data['nextMove'];
          // Eğer nextMove ile MyMove farklıysa, işlemi yap ve dinlemeyi durdur
          if (nextMove!=MyMove) {
           setState(() {
              nodeColorDict[nextMove]=opponentColor=="red"?Colors.red:Colors.blue;
              myTurn = true;
              checkWin(nextMove);
            });
            subscription?.cancel();
          }
        }
      } else {
        print('Belge bulunamadı.');
      }
    });
  }

  Future<void> doOnlineThings(String myUserName) async {
    void listenToRoom(String roomId) async {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      roomDoc = firestore.collection('rooms').doc(roomId);

      try {
        await firestore.runTransaction((transaction) async {
          // Belgeyi önce al
          DocumentSnapshot snapshot = await transaction.get(roomDoc);
          if (!snapshot.exists) {
            throw Exception('Belge bulunamadı.');
          }
          // Belge verisini al
          Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;

          // attendanceNumber'ı arttır
          int attendanceNumber = data["attendanceNumber"] ?? 0;
          transaction
              .update(roomDoc, {"attendanceNumber": attendanceNumber + 1});

          // Eğer attendanceNumber 2 olduysa readyToGame'i true yap
          if (attendanceNumber + 1 == 2) {
            transaction.update(roomDoc, {"readyToGame": true});
          }
        });
        print('Transaction başarılı!');
      } catch (error) {
        print('Transaction başarısız: $error');
      }

      if (myRole == "guest") {
        listenNextMove(Offset(9000, 9000));
      }

      roomDoc.snapshots().listen((DocumentSnapshot snapshot) {
        if (!snapshot.exists) {
          print('Oda bulunamadı.');
          return;
        }
        Map<String, dynamic> roomData = snapshot.data() as Map<String, dynamic>;
        List<dynamic>? players = roomData['players'];

        if (players != null) {
          // 'players' listesinde gez ve myUserName'e eşit olmayan oyuncuyu bul
          myOpponentId;
          for (var player in players) {
            if (player != myUserName) {
              myOpponentId = player;
              break; // Eşleşen opponent bulunduğunda döngüden çık
            }
          }
          // Eğer opponentId bulunduysa, setState içinde myOpponentId'yi güncelle
          if (myOpponentId != null) {
            setState(() {
              myOpponentId = myOpponentId;
            });
          }
        }

        setState(() {
          readyToGame = roomData['readyToGame'];
        });

        Map<String, dynamic>? playerSymbolsDynamic = roomData['playerSymbols'];
        if (playerSymbolsDynamic != null) {
          Map<String, String> playerSymbols = playerSymbolsDynamic
              .map((key, value) => MapEntry(key, value as String));
          setState(() {
            myColor = playerSymbols[MyHomePageState.userId ?? ""] ?? "";
            if (myColor == "red") {
              opponentColor = "blue";
            } else {
              opponentColor = "red";
            }
          });
          print('Kendi sembolünüz: $myColor');
        }

        // Kazanan bilgisi
        String? winner = roomData['winner'];
        if (winner != null) {
          print('Kazanan oyuncu: $winner');
          // Kazananı göster
        }
      });
    }

    void listenRole() {
      if (myRole.isNotEmpty) {
        return; // Rol zaten atanmışsa dinlemeyi başlatma
      }
      DocumentReference userDoc =
      FirebaseFirestore.instance.collection('users').doc('DuzUsers');
      // StreamSubscription'ı dinle
      userDoc.snapshots().listen((DocumentSnapshot snapshot) {
        Map<String, dynamic> roomData = snapshot.data() as Map<String, dynamic>;
        // Eğer role "guest" ise
        if (roomData["listOfUsers"][myUserName]["role"] == "guest" && mounted) {
          setState(() {
            myRole = "guest";
            myTurn = false;
          });

          return;
        }
        // Eğer role "owner" ise
        else if (roomData["listOfUsers"][myUserName]["role"] == "owner" &&
            mounted) {
          setState(() {
            myRole = "owner";
            myTurn = true;
          });
          // Rol atandıktan sonra dinlemeyi durdur
          return;
        }
      });
    }

    Future<String> waitMyRoomId() async {
      Completer<String> completer = Completer<String>();

      DocumentReference userDoc =
      FirebaseFirestore.instance.collection('users').doc('DuzUsers');
      userDoc.snapshots().listen((DocumentSnapshot snapshot) {
        try {
          Map<String, dynamic> roomData =
          snapshot.data() as Map<String, dynamic>;
          String? roomId = roomData["listOfUsers"][myUserName]["currentRoomId"];

          if (roomId != null && !completer.isCompleted) {
            completer
                .complete(roomId); // Oda ID'si bulunduğunda tamamlama yapılır
          }
        } catch (e) {
          if (!completer.isCompleted) {
            completer.completeError('Hata: $e'); // Hata durumunda tamamlanır
          }
        }
      });

      return completer.future; // Bekleyen tamamlanmayı döndürür
    }

    Future<String?> findMatchingUserWithTransaction(String userId) async {
      String? matchingUserId;
      Future<void> updateUserInMap(String userId) async {
        try {
          DocumentReference userDoc =
          FirebaseFirestore.instance.collection('users').doc('DuzUsers');
          // Firestore'da Map yapısı
          Map<String, dynamic> updateMap = {
            'timeStamp': DateTime.now().millisecondsSinceEpoch,
            "isMatched": false,
            'role': ""
          };

          // Sadece belirli kullanıcıyı güncelle
          await userDoc.update({
            'listOfUsers.$userId': updateMap,
          });
          print('$userId başarıyla güncellendi!');
        } catch (e) {
          print('Hata: $e');
        }
      }

      await updateUserInMap(userId);
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      // Firestore'dan kullanıcıların listesi alınıyor
      DocumentReference userDoc = firestore.collection('users').doc('DuzUsers');
      try {
        await firestore.runTransaction((transaction) async {
          // Kullanıcıların listesi
          DocumentSnapshot userSnapshot = await transaction.get(userDoc);

          if (!userSnapshot.exists) {
            throw Exception('Kullanıcı verisi bulunamadı!');
          }

          // 'listOfUsers' içerisindeki tüm kullanıcılar
          Map<String, dynamic> listOfUsers = userSnapshot['listOfUsers'];

          if (listOfUsers == null || !listOfUsers.containsKey(userId)) {
            throw Exception('Bu userId\'ye sahip kullanıcı bulunamadı!');
          }

          // Kendi alanlarınızı kontrol edin
          if (listOfUsers[userId]['isMatched'] == true) {
            throw Exception('Bu kullanıcı zaten eşleşmiş!');
          }
          // 'listOfUsers' içerisinde o anki userId dışında bir kullanıcıyı eşleştiriyoruz
          listOfUsers.forEach((key, value) {
            if (value is Map<String, dynamic>) {
              if (key != userId &&
                  value['isMatched'] == false &&
                  matchingUserId == null) {
                matchingUserId = key;
              }
            } else {
              print('Beklenmeyen veri tipi:$key $value');
            }
          });
          if (matchingUserId == null) {
            throw Exception('Eşleşebilecek başka bir kullanıcı bulunamadı.');
          }
          // Başka bir işlem veri değiştirmişse bu noktada hata oluşur ve transaction yeniden başlar
          transaction.update(userDoc, {
            'listOfUsers.$matchingUserId.isMatched': true,
            'listOfUsers.$matchingUserId.matchedId': userId,
            'listOfUsers.$matchingUserId.role': "guest",
            'listOfUsers.$userId.isMatched': true,
            'listOfUsers.$userId.matchedId': matchingUserId,
            'listOfUsers.$userId.role': "owner",
          });
          // Eşleşme başarıyla yapıldı
          print('UserId: $userId ile eşleşen kullanıcı: $matchingUserId');
          return matchingUserId;
        });
      } catch (e) {
        print('Hata: $e');
      }

      await Future.delayed(Duration(seconds: 2));
      return matchingUserId;
    }

    Future<String> createRoom(String? opponentId) async {
      print("create rooom başladı  $myRole");
      setState(() {
        myOpponentId = opponentId;
      });
      if (myRole == "guest") {
        print("ben misafirim");
        return await waitMyRoomId(); // waitMyRoomId'nin Future<String> döndürdüğünü varsayıyoruz
      } else if (myRole == "owner") {
        print("ben ownerım kurabilirim");
        FirebaseFirestore firestore = FirebaseFirestore.instance;
        try {
          DocumentReference roomDoc = firestore.collection('rooms').doc();

          // Odaya eklemek için oyuncuların ID'lerini bir listeye koy
          List<String> players = [
            MyHomePageState.userId ?? "",
            opponentId ?? ""
          ];

          // Yeni oda verisini oluştur ve Firestore'a yaz
          await roomDoc.set({
            'players': players,
            'createdAt': FieldValue.serverTimestamp(),
            'readyToGame': false,
            "nextMove": [],
            'currentTurn': MyHomePageState.userId ?? "",
            'winner': null,
            'gameState': 'waiting',
            'playerSymbols': {
              MyHomePageState.userId ?? "": 'red',
              opponentId: 'O',
            },
            'turnCount': 0,
            'attendanceNumber': 0
          });

          // Kullanıcıların oda ID'sini güncelle
          DocumentReference userDoc =
          FirebaseFirestore.instance.collection('users').doc('DuzUsers');
          await userDoc.update({
            'listOfUsers.${MyHomePageState.userId}.currentRoomId': roomDoc.id,
            'listOfUsers.${opponentId}.currentRoomId': roomDoc.id,
          });

          print('Oda başarıyla oluşturuldu: ${roomDoc.id}');
          return roomDoc.id; // Başarılı bir şekilde oda ID'si döndürülür
        } catch (e) {
          print('Hata: Oda oluşturulurken bir sorun oluştu: $e');
          return 'Hata: $e'; // Hata durumunda bir mesaj döndürülür
        }
      } else {
        print("ben misafirim");
        return await waitMyRoomId();
      }
    }

    listenRole();

    findMatchingUserWithTransaction(MyHomePageState.userId ?? "defaultUserId")
        .then((onValue) {
      createRoom(onValue).then((onValue) {
        listenToRoom(onValue);
      });
    });
  }

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
        startingColor == myColor ? myScore++ : opponentScore++;
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

  void handleTap(Offset point) {
    if (counterToGetNodesFromOpponent > 0 && nodeColorDict[point] == opponentColor && isTripplesSuitableToGetNode(point)) {
      setState(() {
        nodeColorDict[point] = Colors.white;
        getNodeOnline(point);
        counterToGetNodesFromOpponent--;
      });
    } else if (counterToGetNodesFromOpponent > 0 && nodeColorDict[point] != opponentColor) {
      giveWarningToGetNode();
    } else if (myTurn && nodeColorDict[point] == Colors.white) {
      setState(() {
        nodeColorDict[point] = myColor == "red" ? Colors.red : Colors.blue;
        checkWin(point);
        updateOnlineDuz(point);
      });
    }
  }

  void giveWarningToGetNode(){

  }

  Future<void> getNodeOnline(Offset point) async {
    try {
      DocumentSnapshot roomSnapshot = await roomDoc.get();
      if (roomSnapshot.exists) {
        await roomDoc.update({'nextMoveToGetNode': point});
        print("onlineDaki move'u güncelledim");
      } else {
        print("Belge bulunamadı.");
      }
    } catch (error) {
      print("Hata HAMLEMİ GÜNCELLEME İŞLEMİ: $error");
    }

    if(counterToGetNodesFromOpponent==0){
      void giveTurnToOpponent(Offset point) async {
        try {
          await roomDoc.update({"currentTurn": myOpponentId});
          print("rakibe sıramı verdim");
          listenNextMove(point);
        } catch (error) {
          print("Hata RAKİBA SIRA VERME İŞLEMİ: $error");
        }
      }
      giveTurnToOpponent(point);
    }
  }

  Future<void> updateOnlineDuz(Offset point)async{
    try {
      DocumentSnapshot roomSnapshot = await roomDoc.get();
      if (roomSnapshot.exists) {
        await roomDoc.update({'nextMove': point});
        print("onlineDaki move'u güncelledim");
      } else {
        print("Belge bulunamadı.");
      }
    } catch (error) {
      print("Hata HAMLEMİ GÜNCELLEME İŞLEMİ: $error");
    }
    if(counterToGetNodesFromOpponent==0){
      void giveTurnToOpponent(Offset point) async {
        try {
          await roomDoc.update({"currentTurn": myOpponentId});
          print("rakibe sıramı verdim");
          listenNextMove(point);
        } catch (error) {
          print("Hata RAKİBA SIRA VERME İŞLEMİ: $error");
        }
      }
      giveTurnToOpponent(point);
    }
  }

  void handleDrag(DraggableDetails details, Offset point,BuildContext context) {
    if (myTurn&&
        nodeColorDict[point] ==
            (myColor=="red"?Colors.red:Colors.blue)) {
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
        if ((opponentScore) >= 9 &&
            closestPoint != null&& closestPoint!=point) {
          myTurn=false;
          Color tempColor = nodeColorDict[point] ?? Colors.white;
          nodeColorDict[point] = nodeColorDict[closestPoint] ?? Colors.white;
          nodeColorDict[closestPoint] = tempColor;
          checkWin(closestPoint);
          return;
        }
        List<Offset> possibleMovePointsOfPoint = possibleMovePoints[point]!;
        bool allmatch = true;
        for (int i = 0; i < possibleMovePointsOfPoint.length; i++) {
          nodeColorDict[possibleMovePointsOfPoint[i]] != Colors.white;
          allmatch = false;
          break;
        }
        if (allmatch) {
          if (counterToGetNodesFromOpponent == 0 &&
              closestPoint != null &&
              nodeColorDict[closestPoint] == Colors.white) {
            myTurn=false;
            Color tempColor = nodeColorDict[point] ?? Colors.white;
            nodeColorDict[point] = nodeColorDict[closestPoint] ?? Colors.white;
            nodeColorDict[closestPoint] = tempColor;
            checkWin(closestPoint);
          }
        } else if (counterToGetNodesFromOpponent == 0 &&
            closestPoint != null &&
            nodeColorDict[closestPoint] == Colors.white &&
            possibleMovePoints[point]!.contains(closestPoint)) {
          myTurn=false;
          Color tempColor = nodeColorDict[point] ?? Colors.white;
          nodeColorDict[point] = nodeColorDict[closestPoint] ?? Colors.white;
          nodeColorDict[closestPoint] = tempColor;
          checkWin(closestPoint);
        }
      });
    }
  }

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
                    text: "${myScore}",
                    height: 50,
                    width: 50,
                    color: RetroColors.lightBlueAccent,
                    borderColor: RetroColors.background,
                  ),
                  if (counterToGetNodesFromOpponent != 0)
                    TextBoxWidget(
                      text: "${counterToGetNodesFromOpponent} ",
                      height: 50,
                      width: 90,
                    ),
                  TextBoxWidget(
                    text: "${opponentScore}",
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
