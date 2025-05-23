import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tictactoegame/Presentation/GameGrid/GameGrid.dart';
import '../../Common/colors.dart';
import '../../Common/widgets/BackButtonWidget.dart';
import '../../Common/widgets/HourglassWidget.dart';
import '../../Common/widgets/RetroButton.dart';
import '../../Common/widgets/TextBoxWidget.dart';
import '../../main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OnlineGameGrid extends StatefulWidget {
  const OnlineGameGrid({super.key});

  @override
  State<OnlineGameGrid> createState() => _OnlineGameGridState();
}

class _OnlineGameGridState extends State<OnlineGameGrid> {
  final Image backgroundImage = returnRandomImage();
  @override
  int myScore = 0;
  int opponentScore = 0;
  String mySymbol = "";
  String opponentSymbol = "";
  List<List<String>> gameGrid = [];
  List<List<int>> winningTriplets = [];
  List<List<double>> scaleGrid = [];
  bool readyToGame = false;
  bool myTurn = false;
  String myRole = "";
  String myRoomId = "";
  String? myOpponentId = "";
  late DocumentReference roomDoc;
  bool canGridTaken = true;

  @override
  void initState() {
    gameGrid = List.generate(
      8,
      (_) => List.generate(8, (_) => ''),
    );

    scaleGrid = List.generate(
      8,
      (_) => List.generate(8, (_) => 1),
    );
    doOnlineThings(MyHomePageState.userId ?? "defaultUserId");
    super.initState();
  }

  void dispose() {
    super.dispose();
    try {
      DocumentReference userDoc =
          FirebaseFirestore.instance.collection('users').doc('users');

      // Sadece belirli kullanıcıyı güncelle
      userDoc.update({
        'listOfUsers.${MyHomePageState.userId}': FieldValue.delete(),
      });
    } catch (e) {
      print('Hata: $e');
    }
  }

  Future<void> countUsersWithSameTimestamp(String userId) async {
    final stopwatch = Stopwatch()..start(); // Zaman ölçümünü başlatıyoruz

    try {
      // Firestore'da 'users' koleksiyonundaki 'users' dokümanını alıyoruz
      DocumentReference userDoc =
          FirebaseFirestore.instance.collection('users').doc('users');
      DocumentSnapshot userSnapshot = await userDoc.get();

      if (!userSnapshot.exists) {
        print('Kullanıcı verisi bulunamadı!');
        return;
      }

      // 'listOfUsers' içerisindeki userId'nin timestamp'ını alıyoruz
      Map<String, dynamic> listOfUsers = userSnapshot['listOfUsers'];
      if (listOfUsers == null || !listOfUsers.containsKey(userId)) {
        print('Bu userId\'ye sahip kullanıcı bulunamadı!');
        return;
      }

      // userId'ye ait timestamp'ı alıyoruz
      int userTimestamp = listOfUsers[userId]['timeStamp'];

      // Aynı timestamp'a sahip kullanıcıları sayıyoruz
      int sameTimestampCount = 0;

      listOfUsers.forEach((key, value) {
        if (value['timeStamp'] == userTimestamp) {
          sameTimestampCount++;
        }
      });

      // Sonucu yazdırıyoruz
      print('UserId: $userId, Timestamp: $userTimestamp');
      print('Aynı timestamp\'a sahip kullanıcı sayısı: $sameTimestampCount');
    } catch (e) {
      print('Hata: $e');
    }
    stopwatch.stop();
    print('Tüm istekler başarıyla tamamlandı!');
    print('Toplam süre: ${stopwatch.elapsed.inMilliseconds / 1000} saniye');
  }

  void simulateConcurrentRequests() async {
    Future<void> updateUserInMap(String userId) async {
      try {
        DocumentReference userDoc =
            FirebaseFirestore.instance.collection('users').doc('users');

        // Firestore'da Map yapısı
        Map<String, dynamic> updateMap = {
          'timeStamp': DateTime.now().millisecondsSinceEpoch,
          "isMatched": false
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

    final stopwatch = Stopwatch()..start(); // Zaman ölçümünü başlatıyoruz

    List<Future<void>> requests = [];

    // 2000 kaynağı simüle etmek için 2000 istek
    for (int i = 0; i < 200; i++) {
      // Farklı kaynaklardan gelen istekler
      requests.add(updateUserInMap('user_${i}'));
    }

    // Tüm işlemleri paralel olarak başlatıyoruz
    await Future.wait(requests);

    // İşlemlerin bitiş zamanını alıyoruz
    stopwatch.stop();
    print('Tüm istekler başarıyla tamamlandı!');
    print('Toplam süre: ${stopwatch.elapsed.inMilliseconds / 1000} saniye');
  }

  Future<void> doOnlineThings(String myUserName) async {
    print("kullanıcı adı ${myUserName}");
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
        listenNextMove([99, 99]);
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
            mySymbol = playerSymbols[MyHomePageState.userId ?? ""] ?? "";
            if (mySymbol == "X") {
              opponentSymbol = "O";
            } else {
              opponentSymbol = "X";
            }
          });
          print('Kendi sembolünüz: $mySymbol');
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
          FirebaseFirestore.instance.collection('users').doc('users');
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
          FirebaseFirestore.instance.collection('users').doc('users');
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
              FirebaseFirestore.instance.collection('users').doc('users');
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
      DocumentReference userDoc = firestore.collection('users').doc('users');
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
              MyHomePageState.userId ?? "": 'X',
              opponentId: 'O',
            },
            'turnCount': 0,
            'attendanceNumber': 0
          });

          // Kullanıcıların oda ID'sini güncelle
          DocumentReference userDoc =
              FirebaseFirestore.instance.collection('users').doc('users');
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

  void listenNextMove(List<int> MyMove) async {
    print("karşı tarafı dinliyorum");
    StreamSubscription<DocumentSnapshot>? subscription;
    // Dinlemeyi başlat
    subscription = roomDoc.snapshots().listen((documentSnapshot) {
      if (documentSnapshot.exists) {
        Map<String, dynamic> data =
            documentSnapshot.data() as Map<String, dynamic>;

        // nextMove field'ını kontrol et
        if (data.containsKey('nextMove')) {
          List<int> nextMove = List<int>.from(data['nextMove']);
          // Eğer nextMove ile MyMove farklıysa, işlemi yap ve dinlemeyi durdur
          if (!ListEquality().equals(nextMove, MyMove)) {
            print("nextMove: $nextMove, MyMove: $MyMove");
            print(
                "row:${nextMove[0]} ve column:${nextMove[1]} ve opponentSymbol: ${opponentSymbol}");
            setState(() {
              gameGrid[nextMove[0]][nextMove[1]] = opponentSymbol;
              myTurn = true;
              _checkWin();
            });
            subscription?.cancel();
          }
        }
      } else {
        print('Belge bulunamadı.');
      }
    });
  }

  void updateOnlineGridAndGiveTurnToTheOpponent(
      List<int> moveCoordinate) async {
    try {
      DocumentSnapshot roomSnapshot = await roomDoc.get();
      if (roomSnapshot.exists) {
        await roomDoc.update({'nextMove': moveCoordinate});
        print("onlineDaki move'u güncelledim");
        giveTurnToOpponent(moveCoordinate);
      } else {
        print("Belge bulunamadı.");
      }
    } catch (error) {
      print("Hata HAMLEMİ GÜNCELLEME İŞLEMİ: $error");
    }
  }

  void giveTurnToOpponent(List<int> moveCoordinate) async {
    try {
      await roomDoc.update({"currentTurn": myOpponentId});
      print("rakibe sıramı verdim");
      listenNextMove(moveCoordinate);
    } catch (error) {
      print("Hata RAKİBA SIRA VERME İŞLEMİ: $error");
    }
  }

  void _handleTap(int rowIndex, int colIndex) async {
    if (myTurn == false) return;
    myTurn = false;
    if (gameGrid[rowIndex][colIndex] == '') {
      setState(() {
        gameGrid[rowIndex][colIndex] = mySymbol;
      });
      print("başarılı bir şekilde localde değiştirildi");
      _checkWin();
      updateOnlineGridAndGiveTurnToTheOpponent([rowIndex, colIndex]);
    } else {
      print("yanlış yere tıkladın");
      myTurn = true;
      return;
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

  Future<void> _updateScaleGrid(List<int> triplet) async {
    for (int i = 0; i < 3; i++) {
      setState(() {
        for (int j = 0; j < triplet.length; j += 2) {
          int row = triplet[j];
          int col = triplet[j + 1];
          scaleGrid[row][col] = 0.4;
        }
      });

      await Future.delayed(Duration(milliseconds: 200));

      setState(() {
        // Tripletteki hücreleri tekrar 1 yap (normal boyut)
        for (int j = 0; j < triplet.length; j += 2) {
          int row = triplet[j];
          int col = triplet[j + 1];
          scaleGrid[row][col] = 1.0;
        }
      });

      await Future.delayed(Duration(milliseconds: 200));
    }
  }

  void _checkWin() {
    for (int rowIndex = 0; rowIndex < 8; rowIndex++) {
      for (int colIndex = 0; colIndex < 8; colIndex++) {
        String currentCell = gameGrid[rowIndex][colIndex];
        if (currentCell == '') continue; // Eğer boşsa devam et

        // Yatay kontrol
        if (colIndex + 2 < 8 &&
            currentCell == gameGrid[rowIndex][colIndex + 1] &&
            currentCell == gameGrid[rowIndex][colIndex + 2]) {
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
            if (currentCell == mySymbol) {
              setState(() {
                myScore++;
              });
            } else {
              setState(() {
                opponentScore++;
              });
            }
            print(
                "Yatay kazanan: $currentCell (Row: $rowIndex, Col: $colIndex)");
            _updateScaleGrid(triplet);
          }
        }

        // Dikey kontrol
        if (rowIndex + 2 < 8 &&
            currentCell == gameGrid[rowIndex + 1][colIndex] &&
            currentCell == gameGrid[rowIndex + 2][colIndex]) {
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
            if (currentCell == mySymbol) {
              setState(() {
                myScore++;
              });
            } else {
              setState(() {
                opponentScore++;
              });
            }
            print(
                "Dikey kazanan: $currentCell (Row: $rowIndex, Col: $colIndex)");
            // Kazanan üçlüdeki hücrelerin scaleGrid değerini değiştir
            _updateScaleGrid(triplet);
          }
        }

        // Sağ üst çapraz kontrol
        if (rowIndex + 2 < 8 &&
            colIndex + 2 < 8 &&
            currentCell == gameGrid[rowIndex + 1][colIndex + 1] &&
            currentCell == gameGrid[rowIndex + 2][colIndex + 2]) {
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
            if (currentCell == mySymbol) {
              setState(() {
                myScore++;
              });
            } else {
              setState(() {
                opponentScore++;
              });
            }
            print(
                "Sağ üst çapraz kazanan: $currentCell (Row: $rowIndex, Col: $colIndex)");
            // Kazanan üçlüdeki hücrelerin scaleGrid değerini değiştir
            _updateScaleGrid(triplet);
          }
        }

        // Sağ alt çapraz kontrol
        if (rowIndex - 2 >= 0 &&
            colIndex + 2 < 8 &&
            currentCell == gameGrid[rowIndex - 1][colIndex + 1] &&
            currentCell == gameGrid[rowIndex - 2][colIndex + 2]) {
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
            if (currentCell == mySymbol) {
              setState(() {
                myScore++;
              });
            } else {
              setState(() {
                opponentScore++;
              });
            }
            print(
                "Sağ alt çapraz kazanan: $currentCell (Row: $rowIndex, Col: $colIndex)");
            // Kazanan üçlüdeki hücrelerin scaleGrid değerini değiştir
            _updateScaleGrid(triplet);
          }
        }
      }
    }
  }

  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: backgroundImage,
          ),
          Positioned(
            top: screenHeight / 15,
            left: screenWidth / 20,
            child: BackButtonWidget(),
          ),
          !readyToGame
              ? Positioned(
                  top: screenHeight / 3,
                  left: screenWidth / 20,
                  child: TextBoxWidget(
                    heightRatio: 1 / 5,
                    widthRatio: 9 / 10,
                    text: "Waiting for an opponent",
                    animatedWidget: HourglassFillWidget(),
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        TextBoxWidget(
                          text: "${myScore}",
                          height: 50,
                          width: 50,
                          color: RetroColors.greenAccent,
                          borderColor: RetroColors.background,
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
                    SizedBox(
                      height: 20,
                    ),
                    AspectRatio(
                      aspectRatio: 0.8,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          8,
                          (rowIndex) => Expanded(
                            child: Row(
                              children: List.generate(
                                8,
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
                                            scale: scaleGrid[rowIndex]
                                                [colIndex],
                                            duration:
                                                Duration(milliseconds: 300),
                                            curve: Curves.easeInOut,
                                            child: Text(
                                              gameGrid[rowIndex][colIndex],
                                              // "X" veya "O"
                                              style: TextStyle(
                                                fontFamily: "Georgia",
                                                color: gameGrid[rowIndex]
                                                            [colIndex] ==
                                                        mySymbol
                                                    ? RetroColors.greenAccent
                                                    : RetroColors.redAccent,
                                                // Yazı rengi
                                                fontSize: 200 / 8,
                                                // Hücre boyutuna göre yazı boyutu
                                                fontWeight: FontWeight.bold,
                                                // Yazıyı kalın yap
                                                shadows: [
                                                  Shadow(
                                                    blurRadius: 1.0,
                                                    color: RetroColors.white,
                                                  ),
                                                ], // Yazıya gölge efekti ekleyin
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
                )
        ],
      ),
    );
  }
}
