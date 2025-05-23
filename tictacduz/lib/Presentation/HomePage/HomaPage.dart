import 'package:flutter/material.dart';
import 'package:tictactoegame/Presentation/GameGrid/GameGrid.dart';
import 'package:tictactoegame/Presentation/OnlineGameGrid/OnlineGameGrid.dart';
import 'package:tictactoegame/Presentation/duzGameGrid/duzGameGrid.dart';
import '../../Common/colors.dart';
import '../../Common/widgets/BackButtonWidget.dart';
import '../../Common/widgets/HourglassWidget.dart';
import '../../Common/widgets/RetroButton.dart';
import '../../Common/widgets/TextBoxWidget.dart';
import '../../main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String chosenGameType = "";
  int selectedGridSize = 3; // For grid size selection
  String selectedDifficulty = "Easy";
  String selectedMode = "Tic-Tac-Toe";

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

  Future<String?> findMatchingUserWithTransaction(String userId) async {
    String? matchingUserId;

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

    await updateUserInMap(MyHomePageState.userId ?? "defaultUserId");

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
          if (key != userId &&
              value['isMatched'] == false &&
              matchingUserId == null) {
            matchingUserId = key;
          }
        });

        if (matchingUserId == null) {
          throw Exception('Eşleşebilecek başka bir kullanıcı bulunamadı.');
        }

        // Başka bir işlem veri değiştirmişse bu noktada hata oluşur ve transaction yeniden başlar
        transaction.update(userDoc, {
          'listOfUsers.$matchingUserId.isMatched': true,
          'listOfUsers.$matchingUserId.matchedId': userId,
          'listOfUsers.$userId.isMatched': true,
          'listOfUsers.$userId.matchedId': matchingUserId,
        });

        // Eşleşme başarıyla yapıldı
        print('UserId: $userId ile eşleşen kullanıcı: $matchingUserId');
        return matchingUserId;
      });
    } catch (e) {
      print('Hata: $e');
    }
    return matchingUserId;
  }

  Future<void> createRoom(String? opponentId) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      // Yeni bir oda için rastgele bir belge ID'si oluştur
      DocumentReference roomDoc = firestore.collection('rooms').doc();

      // Odaya eklemek için oyuncuların ID'lerini bir listeye koy
      List<String> players = [MyHomePageState.userId ?? "", opponentId ?? ""];

      // Yeni oda verisini oluştur ve Firestore'a yaz
      await roomDoc.set({
        'players': players,
        // Oyuncu ID'leri listesi
        'createdAt': FieldValue.serverTimestamp(),
        // Oda oluşturulma zamanı
        'readyToGame': false,
        // Her iki oyuncunun hazır olduğunu işaretlemek için
        'gameGrid': [],
        // Oyun ızgarası (3x3)
        'currentTurn': MyHomePageState.userId ?? "",
        // Sıranın hangi oyuncuda olduğunu belirtir
        'winner': null,
        // Oyunun galibini tutar (null: devam ediyor, playerId: kazanan, 'draw': beraberlik)
        'gameState': 'waiting',
        // Oyun durumu: 'waiting', 'inProgress', 'finished'
        'lastMove': null,
        // Son hamlenin bilgisi (örneğin: {playerId: "user123", x: 1, y: 2})
        'playerSymbols': {
          MyHomePageState.userId ?? "": 'X',
          opponentId: 'O',
        },
        // Oyuncu sembollerini (X ve O) belirtir
        'turnCount': 0,
        // Kaç tur geçtiğini takip etmek için
      });

      print('Oda başarıyla oluşturuldu: ${roomDoc.id}');
    } catch (e) {
      print('Hata: Oda oluşturulurken bir sorun oluştu: $e');
    }
  }

  Future<void> doOnlineThings(String myUserName) async {
    findMatchingUserWithTransaction(MyHomePageState.userId ?? "defaultUserId")
        .then((onValue) {
      createRoom(onValue);
    });
  }

  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    Widget buildInitialOptions() {
      return Positioned(
        left: screenWidth * 0.2,
        top: screenHeight * 0.3,
        child: Column(
          children: [
            RetroButton(
              textColor: RetroColors.mainScreenColor,
              text: "MULTIPLAYER",
              glowColor: RetroColors.background,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => OnlineGameGrid()),
                );
              },
            ),
            const SizedBox(height: 20),
            RetroButton(
              textColor: RetroColors.mainScreenColor,
              text: "SINGLEPLAYER",
              glowColor: RetroColors.background,
              onPressed: () {
                setState(() {
                  chosenGameType = "SingleplayerChooseSize";
                });
              },
            ),
          ],
        ),
      );
    }

    Widget buildSingleplayerScreen() {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Stack(
          children: [
            Positioned(
              top: screenHeight / 25,
              left: screenWidth / 100,
              child: BackButtonWidget(
                onTap: () {
                  setState(() {
                    chosenGameType = "";
                  });
                },
              ),
            ),
            Center(
              child: GameGrid(
                  gridSize: selectedGridSize,
                  opponentDifficulty: selectedDifficulty),
            ),
          ],
        ),
      );
    }

    Widget buildSingleplayerChooseSizeScreen() {
      return Stack(children: [
        Positioned(
          top: screenHeight / 25,
          left: screenWidth / 100,
          child: BackButtonWidget(
            onTap: () {
              setState(() {
                chosenGameType = "";
              });
            },
          ),
        ),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24.0),
                margin:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                decoration: BoxDecoration(
                  color: RetroColors.transparentBlack,
                  borderRadius: BorderRadius.circular(20.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 4), // Shadow position
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "Choose game",
                      style: TextStyle(
                        color: RetroColors.greenAccent,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButton<String>(
                      value: selectedMode,
                      dropdownColor: Colors.grey[850],
                      style: const TextStyle(
                          color: RetroColors.greenAccent,
                          fontSize: 17,
                          fontWeight: FontWeight.bold),
                      onChanged: (String? value) {
                        setState(() {
                          selectedMode = value!;
                        });
                      },
                      items: const [
                        DropdownMenuItem(
                            value: "Tic-Tac-Toe", child: Text("Tic-Tac-Toe")),
                        DropdownMenuItem(value: "Duz", child: Text("Duz")),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20,),
              if (selectedMode == "Tic-Tac-Toe")
                Container(
                  padding: const EdgeInsets.all(24.0),
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: RetroColors.transparentBlack,
                    borderRadius: BorderRadius.circular(20.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset: const Offset(0, 4), // Shadow position
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        "Choose Grid Size",
                        style: TextStyle(
                          color: RetroColors.greenAccent,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButton<int>(
                        value: selectedGridSize,
                        dropdownColor: Colors.grey[850],
                        style: const TextStyle(
                            color: RetroColors.greenAccent,
                            fontSize: 17,
                            fontWeight: FontWeight.bold),
                        onChanged: (int? value) {
                          setState(() {
                            selectedGridSize = value!;
                          });
                        },
                        items: const [
                          DropdownMenuItem(value: 3, child: Text("3")),
                          DropdownMenuItem(value: 4, child: Text("4")),
                          DropdownMenuItem(value: 5, child: Text("5")),
                          DropdownMenuItem(value: 6, child: Text("6")),
                          DropdownMenuItem(value: 7, child: Text("7")),
                          DropdownMenuItem(value: 8, child: Text("8")),
                        ],
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              if (selectedMode == "Tic-Tac-Toe")
                Container(
                  padding: const EdgeInsets.all(24.0),
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: RetroColors.transparentBlack,
                    borderRadius: BorderRadius.circular(20.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset: const Offset(0, 4), // Shadow position
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        "Choose Difficulty",
                        style: TextStyle(
                          color: RetroColors.greenAccent,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButton<String>(
                        value: selectedDifficulty,
                        dropdownColor: Colors.grey[850],
                        style: const TextStyle(
                            color: RetroColors.greenAccent,
                            fontSize: 17,
                            fontWeight: FontWeight.bold),
                        onChanged: (String? value) {
                          setState(() {
                            selectedDifficulty = value!;
                          });
                        },
                        items: const [
                          DropdownMenuItem(value: "Easy", child: Text("Easy")),
                          DropdownMenuItem(
                              value: "Medium", child: Text("Medium")),
                          DropdownMenuItem(value: "Hard", child: Text("Hard")),
                        ],
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => selectedMode == "Tic-Tac-Toe"
                            ? (GameGrid(
                                gridSize: selectedGridSize,
                                opponentDifficulty: selectedDifficulty))
                            : DuzGameGrid()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: RetroColors.greenAccent,
                  foregroundColor: RetroColors.background,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 50.0, vertical: 20.0),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  shadowColor: Colors.black,
                  elevation: 5,
                ),
                child: const Text("Next"),
              ),
            ],
          ),
        ),
      ]);
    }

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: globalBackgroundImage,
          ),
          if (chosenGameType == "") buildInitialOptions(),
          if (chosenGameType == "SingleplayerChooseSize")
            buildSingleplayerChooseSizeScreen(),
        ],
      ),
    );
  }
}
