// lib/features/game/game_view_model.dart
// _handleGameMatched metoduna debug printleri ekliyoruz

  /// Oyun eşleşme olayı
  void _handleGameMatched(Map<String, dynamic> data) {
    print('DEBUG_VM: Oyun eşleşti. Tüm gelen veriler: $data');
    
    // Eşleşme olayını OnlineGameLogic'e ilet
    _onlineLogic?.handleGameMatched(_state, data);
    
    // Önceki zamanayıcıları temizle
    _timerManager.clearAllTimers();
    
    // Eşleşme durumunu güncelle
    matchState.value = GameMatchState.opponentFound;
    
    // Takım rengi ve rakip bilgilerini al
    bool isGreenTeam = data['isGreenTeam'] == 1 || data['isGreenTeam'] == true;
    print('DEBUG_VM: isGreenTeam değeri: $isGreenTeam');
    
    // ÖNEMLİ! Server.js içinde kullanılan alan adlarını al ve kullan
    // Genelde player1Id, player2Id gönderildiğinden bunu kontrol edelim
    String currentUserId = "";
    try {
      // AuthService'den gelen user ID bilgisini al (GlobalData gibi bir yerden)
      // Bu sadece örnek - projenize göre düzenleyin
      currentUserId = currentGameId ?? ""; // Bu sadece örnek
      print("DEBUG_VM: Aktif kullanıcı ID: $currentUserId");
    } catch (e) {
      print("DEBUG_VM: Kullanıcı ID alınamadı: $e");
    }
    
    // Player 1 ve Player 2 bilgileri varsa
    String player1Id = data['player1Id'] ?? "";
    String player2Id = data['player2Id'] ?? "";
    print("DEBUG_VM: player1Id: $player1Id, player2Id: $player2Id");
    
    // Rakip bilgilerini oluştur
    Map<String, dynamic> opponentData = {};
    
    // 1. Direkt opponent alanını kontrol et
    if (data.containsKey('opponent')) {
      print('DEBUG_VM: data içinde opponent var: ${data['opponent']}');
      opponentData = data['opponent'] is Map<String, dynamic> ? 
                   data['opponent'] as Map<String, dynamic> : 
                   {'id': 'opponent'};
    } 
    // 2. Opponent yoksa player1 ve player2 bilgilerinden çıkar  
    else if (player1Id.isNotEmpty && player2Id.isNotEmpty) {
      print('DEBUG_VM: opponent yok, player ID bilgilerinden rakibi belirliyoruz');
      // Hangisinin rakip olduğunu belirle
      String opponentId = (currentUserId == player1Id) ? player2Id : player1Id;
      opponentData = {'id': opponentId};
      print('DEBUG_VM: Belirlenen rakip ID: $opponentId');
    }
    
    // Rakip ID'sini kontrol et
    final opponentId = opponentData['id'] ?? opponentData['userId'] ?? opponentData['user_id'] ?? 'rakip_id';
    
    // Verileri hazırla - onOpponentFound callback'ine aktarılacak
    Map<String, dynamic> opponentInfo = {
      'userId': opponentId,
      'nickname': 'Rakip',
      'win_rate': 50.0,
    };
    
    // Server'dan gelen rakip bilgilerini almaya çalış
    if (data.containsKey('opponent_info')) {
      // Tam rakip bilgisi varsa
      print('DEBUG_VM: data içinde opponent_info var: ${data['opponent_info']}');
      opponentInfo = data['opponent_info'] is Map<String, dynamic> ? 
                  data['opponent_info'] as Map<String, dynamic> : 
                  opponentInfo;
    } else if (opponentData.containsKey('nickname')) {
      // Sadece nickname bilgisi varsa
      print('DEBUG_VM: opponentData içinde nickname var: ${opponentData['nickname']}');
      opponentInfo['nickname'] = opponentData['nickname'];
    }
    
    // Win rate bilgisi varsa al
    if (opponentData.containsKey('win_rate')) {
      print('DEBUG_VM: opponentData içinde win_rate var: ${opponentData['win_rate']}');
      opponentInfo['win_rate'] = opponentData['win_rate'];
    } else if (opponentData.containsKey('winRate')) {
      print('DEBUG_VM: opponentData içinde winRate var: ${opponentData['winRate']}');
      opponentInfo['win_rate'] = opponentData['winRate'];
    }
    
    print('DEBUG_VM: onOpponentFound callback\'e gönderilecek veri: $opponentInfo');
    
    // Callback'e gönder - GameScreen bu veriyi alacak
    if (onOpponentFound != null) {
      onOpponentFound!(opponentInfo);
    }
    
    // State'i güncelle
    _state = _state.copyWith(
      currentPhase: GamePhase.preparation,
      preparationTimeLeft: 10,
      isPlayerReady: false,
      isOpponentReady: false,
      betAmount: data['betAmount'] ?? 1000,
      isGreenTeam: isGreenTeam,
      // Rakip adını belirle
      opponentName: opponentData.containsKey('nickname') ? 
                    opponentData['nickname'] : 
                    opponentInfo['nickname'] ?? 'Rakip',
    );
    
    notifyListeners();
  }