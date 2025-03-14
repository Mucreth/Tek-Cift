// lib/features/game/game_view_model.dart
// 
// GameViewModel sınıfı, oyun mantığını ve durumunu yöneten ana koordinatör sınıftır.
// Oyun akışını ve durumunu yöneterek UI ve iş mantığı arasında aracılık yapar.
// Hem çevrimiçi hem de AI modunda oyun oynamayı destekler.

import 'package:flutter/material.dart';
import 'package:handclash/features/game/game_enums.dart';
import 'package:handclash/features/game/game_state.dart';
import 'package:handclash/features/game/services/game_joker_handler.dart';
import 'package:handclash/features/game/services/game_phase_manager.dart';
import 'package:handclash/features/game/services/game_feedback_service.dart';
import 'package:handclash/features/game/services/game_move_handler.dart';
import 'package:handclash/features/game/services/game_socket_handler.dart';
import 'package:handclash/features/game/services/game_timer_manager.dart';
import 'package:handclash/features/game/logic/ai_game_logic.dart';
import 'package:handclash/features/game/logic/online_game_logic.dart';
import 'package:handclash/features/game/logic/game_result_processor.dart';

class GameViewModel extends ChangeNotifier {
  // Oyun Yapılandırması
  final int targetScore;
  final String gameType;
  final bool isGreenTeam;
  final int betAmount;
  final bool isAIGame;

  // Servisler ve mantık sınıfları
  late final GameMoveHandler _moveHandler;
  late final GameJokerHandler _jokerHandler;
  late final GamePhaseManager _phaseManager;
  late final GameFeedbackService _feedbackService;
  late final GameTimerManager _timerManager;
  late final GameResultProcessor _resultProcessor;
  
  // Oyun modu spesifik mantık
  late final OnlineGameLogic? _onlineLogic;
  late final AIGameLogic? _aiLogic;

  // Durum
  late GameState _state;
  GameState get state => _state;

  // Timer Durumu
  TimerStatus _timerStatus = TimerStatus.preparation;
  TimerStatus get timerStatus => _timerStatus;

  // Eşleşme durumu
  final ValueNotifier<GameMatchState> matchState = ValueNotifier(GameMatchState.searching);
  
  // Yardımcı getter'lar
  String? get currentGameId => _onlineLogic?.currentGameId;
  String? get opponentName => _state.opponentName;
  bool get hasActiveGame => _onlineLogic?.hasActiveGame ?? false;

  // Callback'ler
  Function(Map<String, dynamic>)? onOpponentFound;
  Function(Map<String, dynamic>)? onGameEnd;

  // Timer metinlerini formatla
String get timerText {
  switch (_timerStatus) {
    case TimerStatus.preparation:
      return "Hazırlık: ${_state.preparationTimeLeft} sn";
    case TimerStatus.everyoneReady:
      return "Herkes Hazır!";
    case TimerStatus.cardSelect:
      if (_state.preparationTimeLeft >= 10) {
        return "Kart Seçme Zamanı!";
      } else {
        return "Kart Seç: ${_state.preparationTimeLeft} sn";
      }
    case TimerStatus.countdown:
      return "${_state.preparationTimeLeft}";
    case TimerStatus.revealing:
      return "Kartlar Açılıyor...";
    case TimerStatus.roundResult:
      return _moveHandler.getRoundResultText(_state);
    case TimerStatus.jokerTime:
      return "Joker: ${_state.preparationTimeLeft} sn";
    case TimerStatus.jokerReveal:
      if (_state.jokerUsageStatus == 'none') {
        return "Joker Kullanılmadı!";
      } else if (_state.jokerUsageStatus == 'both') {
        return "İki Taraf da Joker Kullandı!";
      } else if (_state.jokerUsageStatus == 'green') {
        return _state.isGreenTeam 
            ? "Takımınız Joker Kullandı!" 
            : "Rakip Joker Kullandı!";
      } else if (_state.jokerUsageStatus == 'red') {
        return _state.isGreenTeam 
            ? "Rakip Joker Kullandı!" 
            : "Takımınız Joker Kullandı!";
      }
      return "Jokerler Kontrol Ediliyor...";
    case TimerStatus.jokerSkipped: // Yeni durum
      return "Joker Hakkı Kalmadı!";
    case TimerStatus.jokerResult:
      return _moveHandler.getJokerResultText(_state);
    case TimerStatus.roundEnd:
      return "Round ${_state.currentRound} Bitti";
    case TimerStatus.gameOver:
      return "Oyun Bitti!";
  }
}

  GameViewModel({
  required this.targetScore,
  required this.gameType,
  required this.isGreenTeam,
  required this.betAmount,
  this.isAIGame = false,
}) : _state = GameState(
     targetScore: targetScore,
     isGreenTeam: isGreenTeam,
     betAmount: betAmount,
     availableJokers: {
       JokerType.block: targetScore == 3 ? 1 : 2,
       JokerType.blind: targetScore == 3 ? 1 : 2,
       JokerType.bet: targetScore == 3 ? 1 : 2,
     },
   ) {
  // Servisleri oluştur
  _moveHandler = GameMoveHandler(gameType: gameType);
  _jokerHandler = GameJokerHandler(gameType: gameType);
  _feedbackService = GameFeedbackService();
  
  // Timer Manager oluştur
  _timerManager = GameTimerManager(
    onTimerUpdate: (updatedState) {
      _state = updatedState;
      notifyListeners();
    },
  );
  
  // Faz Manager oluştur
  _phaseManager = GamePhaseManager(
    jokerHandler: _jokerHandler,
    onStateUpdate: (updatedState) {
      _state = updatedState;
      notifyListeners();
    },
    onTimerStatusUpdate: (status) {
      _timerStatus = status;
      notifyListeners();
    },
  );
  
  // Sonuç İşlemcisi oluştur
  _resultProcessor = GameResultProcessor(
    feedbackService: _feedbackService,
    onGameEnd: (data) {
      if (onGameEnd != null) {
        onGameEnd!(data);
      }
    },
  );
  
  // AI veya Online oyun mantığı oluştur
  if (isAIGame) {
    _aiLogic = AIGameLogic(
      gameType: gameType,
      targetScore: targetScore,
      jokerHandler: _jokerHandler,
      feedbackService: _feedbackService,
      moveHandler: _moveHandler,
      onStateUpdate: (updatedState) {
        _state = updatedState;
        notifyListeners();
      },
      onTimerStatusUpdate: (status) {
        _timerStatus = status;
        notifyListeners();
      },
      onGameEnd: (data) {
        if (onGameEnd != null) {
          onGameEnd!(data);
        }
      },
    );
    _onlineLogic = null;
  } else {
    // Socket Handler oluştur
    final socketHandler = GameSocketHandler(
      matchState: matchState,
      onGameMatched: _handleGameMatched,
      onPreparationPhase: _handlePreparationPhase,
      onCardSelectPhase: _handleCardSelectPhase,
      onRevealingPhase: _handleRevealingPhase,
      onRoundResultPhase: _handleRoundResultPhase,
      onJokerSelectPhase: _handleJokerSelectPhase,
      onJokerRevealPhase: _handleJokerRevealPhase,
      onRoundEndPhase: _handleRoundEndPhase,
      onRoundStart: _handleRoundStart,
      onJokerPhase: _handleJokerPhase,
      onJokerUsed: _handleJokerUsed,
      onRoundResult: _handleRoundResult,
      onFinalRoundResult: _handleFinalRoundResult,
      onGameEnd: _handleGameEnd,
      onError: _handleError,
      onJokerPhaseSkipped: _handleJokerPhaseSkipped, // Yeni: Joker fazı atlamayı işleyecek metod
    );
    
    _onlineLogic = OnlineGameLogic(
      gameType: gameType,
      targetScore: targetScore,
      betAmount: betAmount,
      socketHandler: socketHandler,
      jokerHandler: _jokerHandler,
      feedbackService: _feedbackService,
      matchState: matchState,
      onOpponentFound: (data) {
        if (onOpponentFound != null) {
          onOpponentFound!(data);
        }
      },
      onGameEnd: (data) {
        if (onGameEnd != null) {
          onGameEnd!(data);
        }
      },
    );
    _aiLogic = null;
  }
}

  //------------------------------------------------------------------------------
  // OYUN BAŞLATMA VE KULLANICI ETKİLEŞİM METOTLARI
  //------------------------------------------------------------------------------
  
  /// Oyunu başlat
  void startGame() {
    if (isAIGame) {
      _aiLogic?.startGame(_state);
    } else {
      _setupSocketListeners();
      _onlineLogic?.startGame();
    }
  }
  
  /// Socket dinleyicilerini ayarla
  void _setupSocketListeners() {
    if (_onlineLogic == null) return;
    
    // Socket handler üzerinden socket bağlantılarını hazırla
    // Bu işlem OnlineGameLogic içinde yapılıyor
  }
  
  /// Hazır olduğunu bildir
  void markPlayerReady() {
    if (isAIGame) return;
    
    // Hazırlık durumunu kontrol et
    if (_state.currentPhase != GamePhase.preparation) {
      print('Hazır olmak için yanlış faz');
      return;
    }
    
    if (!hasActiveGame) {
      print('Aktif oyun yok');
      return;
    }
    
    // State'i güncelle
    _state = _state.copyWith(isPlayerReady: true);
    notifyListeners();
    
    // Sunucuya bildir
    _onlineLogic?.markPlayerReady();
  }
  
void makeMove(String move) {
  // Debug log ekleyin
  print("makeMove çağrıldı. Hamle: $move, Mevcut faz: ${_state.currentPhase}");
  
  // Hamle yapma durumunu kontrol et
  if (!_state.isRoundActive ||
      (_state.currentPhase != GamePhase.playing && 
       _state.currentPhase != GamePhase.cardSelect)) {
    print("Hamle yapılamaz, faz uygun değil: ${_state.currentPhase}");
    return;
  }
  
  // Bloke durumunu kontrol et
  if (_state.blockedMoves.contains(move)) {
    print("Hamle bloke edilmiş: $move");
    return;
  }
  
  // Kart yerleştirme sesi
  _feedbackService.playCardPlaceSound();
  
  if (isAIGame) {
    // AI modunda, hamle AI'ye iletilir
    _aiLogic?.handlePlayerMove(_state, move);
  } else {
    // Çevrimiçi modda, hamleyi sunucuya gönder
    
    // Önce mevcut seçimi kaydet
    final oldMove = _state.selectedMove;
    
    // State'i güncelle
    _state = _state.copyWith(
      selectedMove: move,
    );
    
    // Debug log
    print("State güncellendi. Yeni seçim: ${_state.selectedMove}, Eski seçim: $oldMove");
    
    // UI'ı güncelle
    notifyListeners();
    
    // Sonra sunucuya gönder
    _onlineLogic?.makeMove(move);
  }
}
  
  
  /// Joker kullan
  void useJoker(JokerType type) {
    // Joker kullanma durumunu kontrol et
    if (_state.currentPhase != GamePhase.jokerSelect ||
        !_state.canUseJoker ||
        _state.usedJokers.contains(type)) {
      _feedbackService.playJokerSound();
      _feedbackService.vibrateShort();
      return;
    }
    
    // Joker sayısını azalt
    Map<JokerType, int> updatedJokers = Map.from(_state.availableJokers);
    int currentCount = updatedJokers[type] ?? 0;
    if (currentCount > 0) {
      updatedJokers[type] = currentCount - 1;
    }
    
    // Kullanılan jokerlere ekle
    Set<JokerType> newUsedJokers = Set.from(_state.usedJokers)..add(type);
    
    // State'i güncelle
    _state = _state.copyWith(
      availableJokers: updatedJokers,
      selectedJoker: type,
      usedJokers: newUsedJokers,
    );
    notifyListeners();
    
    if (isAIGame) {
      // AI modunda, joker AI'ye iletilir
      _aiLogic?.handlePlayerJoker(_state, type);
    } else {
      // Çevrimiçi modda, jokeri sunucuya gönder
      _onlineLogic?.useJoker(type);
    }
  }
  
  /// Eşleşmeyi iptal et
  void cancelMatchmaking(BuildContext context) {
    if (isAIGame) {
      // AI modunda sadece ana sayfaya dön
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      // Çevrimiçi modda sunucuya da bildir
      _onlineLogic?.cancelMatchmaking(context);
    }
  }
  
  //------------------------------------------------------------------------------
  // ONLİNE OYUN EVENT HANDLER'LARI
  //------------------------------------------------------------------------------
  
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
  
  /// Hazırlık aşaması
  void _handlePreparationPhase(Map<String, dynamic> data) {
    // Faz yöneticisine ilet
    _phaseManager.handlePreparationPhase(_state, data);
    
    // Eşleşme durumunu güncelle
    matchState.value = GameMatchState.ready;
    
    // Hazırlık aşaması için timer başlat
    _timerManager.startPreparationTimer(_state, data['timeLimit'] ?? 10);
  }
  
  /// Kart seçim aşaması
void _handleCardSelectPhase(Map<String, dynamic> data) {
  // Önceki zamanayıcıları temizle
  _timerManager.clearAllTimers();
  
  // Debug için
  print("KART SEÇİM FAZINA GEÇİLDİ - Önceki seçim: ${_state.selectedMove}");
  
  // Faz yöneticisine ilet
  _phaseManager.handleCardSelectPhase(_state, data);
  
  // Debug için - sonrası
  print("KART SEÇİM FAZINDAN SONRA - Güncel seçim: ${_state.selectedMove}");
  
  // Süre sonunda otomatik olarak seçilen hamleyi gönderecek
  _timerManager.startCardSelectTimer(
    _state, 
    data['timeLimit'] ?? 8, 
    gameType, 
    _onlineLogic?.makeMove ?? ((move) {})
  );
}
  
  /// Kart açılma aşaması
  void _handleRevealingPhase(Map<String, dynamic> data) {
    // Önceki zamanayıcıları temizle
    _timerManager.clearAllTimers();
    
    // Faz yöneticisine ilet
    _phaseManager.handleRevealingPhase(_state, data);
  }
  
  /// Round sonuç aşaması
  void _handleRoundResultPhase(Map<String, dynamic> data) {
    // Önceki zamanayıcıları temizle
    _timerManager.clearAllTimers();
    
      print("Round Result Phase Data: $data");
  print("State: isGreenTeam=${state.isGreenTeam}, playerScore=${state.playerScore}, opponentScore=${state.opponentScore}");
  
    // Sonucu hesapla
    final result = data['result'];
    bool isWin = false;
    
    if (_state.isGreenTeam) {
      isWin = result == 'player1';
    } else {
      isWin = result == 'player2';
    }
    
    // Sonuç sesi ve titreşimi
    _feedbackService.provideFeedbackForGameResult(isWin);
    
    // Faz yöneticisine ilet
    _phaseManager.handleRoundResultPhase(_state, data);
  }
  
  /// Joker seçim aşaması
  void _handleJokerSelectPhase(Map<String, dynamic> data) {
    // Önceki zamanayıcıları temizle
    _timerManager.clearAllTimers();
    
    // Faz yöneticisine ilet
    _phaseManager.handleJokerSelectPhase(_state, data);
    
    // Joker timer'ı başlat
    _timerManager.startJokerTimer(_state, data['timeLimit'] ?? 5);
  }
  
  /// Joker gösterim aşaması
  void _handleJokerRevealPhase(Map<String, dynamic> data) {
    // Önceki zamanayıcıları temizle
    _timerManager.clearAllTimers();
    
    // Joker kullanımı kontrolü
    final jokersMap = _jokerHandler.extractJokersFromServerData(data, _state.isGreenTeam);
    final playerJoker = jokersMap['playerJoker'];
    final opponentJoker = jokersMap['opponentJoker'];
    
    // Joker sesi (eğer en az bir joker kullanıldıysa)
    if (playerJoker != JokerType.none || opponentJoker != JokerType.none) {
      _feedbackService.playJokerSound();
      _feedbackService.vibrateMedium();
    }
    
    // Faz yöneticisine ilet
    _phaseManager.handleJokerRevealPhase(_state, data);
  }
  
  /// Round sonu aşaması
  void _handleRoundEndPhase(Map<String, dynamic> data) {
    // Önceki zamanayıcıları temizle
    _timerManager.clearAllTimers();
    
    // Oyun durumunu al
    bool isGameOver = false;
    
    // Skor değerlerini belirle
    int playerWins = 0;
    int opponentWins = 0;
    
    // Yeşil/kırmızı takım durumuna göre skor değerlerini güncelle
    if (_state.isGreenTeam) {
      playerWins = data['player1Wins'] ?? _state.playerScore;
      opponentWins = data['player2Wins'] ?? _state.opponentScore;
    } else {
      playerWins = data['player2Wins'] ?? _state.playerScore;
      opponentWins = data['player1Wins'] ?? _state.opponentScore;
    }
    
    // Oyun bitti mi kontrol et
    isGameOver = playerWins >= _state.targetScore || opponentWins >= _state.targetScore;
    
    // Round sonu titreşimi
    _feedbackService.provideFeedbackForRoundEnd(isGameOver);
    
    // Faz yöneticisine ilet
    _phaseManager.handleRoundEndPhase(_state, data);
  }
  
  /// Oyun sonu
  void _handleGameEnd(Map<String, dynamic> data) {
    // Önceki zamanayıcıları temizle
    _timerManager.clearAllTimers();
    
    // Sonuç işleme sınıfına ilet
    _resultProcessor.processOnlineGameEnd(_state, data).then((updatedState) {
      _state = updatedState;
      notifyListeners();
    });
  }

  void _handleJokerPhaseSkipped(Map<String, dynamic> data) {
  // Önceki zamanayıcıları temizle
  _timerManager.clearAllTimers();
  
  // Mesajı al
  final String message = data['message'] ?? 'Joker fazı atlandı.';
  
  // State'i güncelle - özel bir durum için
  _state = _state.copyWith(
    currentPhase: GamePhase.jokerSkipped, // Özel joker atlandı fazı
    jokerUsageStatus: 'none', // Joker kullanılmadı
  );
  
  // Kullanıcıya bilgi ver
  _timerStatus = TimerStatus.jokerSkipped;
  notifyListeners();
  
  // Debug log
  print('Joker fazı atlandı: $message');
  
  // 2 saniye sonra round sonuna geç
  Future.delayed(const Duration(seconds: 2), () {
    // Round sonu fazına geçmek için round end handler'ı çağır
    _handleRoundEndPhase({
      'roundNumber': _state.currentRound,
      'player1Wins': _state.isGreenTeam ? _state.playerScore : _state.opponentScore,
      'player2Wins': _state.isGreenTeam ? _state.opponentScore : _state.playerScore,
    });
  });
}
  
  //------------------------------------------------------------------------------
  // ESKİ API UYUMLULUĞU (LEGACY) METOTLARI
  //------------------------------------------------------------------------------
  
  /// Eski API: Round başlangıcı
  void _handleRoundStart(Map<String, dynamic> data) {
    // Bu artık cardSelectPhase ile ele alınıyor
    print('Eski API: Round başlangıcı');
  }
  
  /// Eski API: Joker seçim aşaması
  void _handleJokerPhase(Map<String, dynamic> data) {
    // Bu artık jokerSelectPhase ile ele alınıyor
    print('Eski API: Joker fazı');
  }
  
  /// Eski API: Joker kullanım
  void _handleJokerUsed(Map<String, dynamic> data) {
    // Bu artık jokerRevealPhase ile ele alınıyor
    print('Eski API: Joker kullanıldı');
  }
  
  /// Eski API: Round sonucu
  void _handleRoundResult(Map<String, dynamic> data) {
    // Bu artık roundResultPhase ve roundEndPhase ile ele alınıyor
    print('Eski API: Round sonucu');
  }
  
  /// Eski API: Nihai round sonucu
  void _handleFinalRoundResult(Map<String, dynamic> data) {
    // Bu artık roundEndPhase ile ele alınıyor
    print('Eski API: Final round sonucu');
  }
  
  /// Hata işleme
  void _handleError(Map<String, dynamic> data) {
    print('Oyun hatası: ${data['message']}');
  }
  
  //------------------------------------------------------------------------------
  // KAYNAKLAR TEMİZLEME
  //------------------------------------------------------------------------------
  
  @override
  void dispose() {
    _timerManager.dispose();
    
    // AI/Online moduna göre kaynakları temizle
    if (isAIGame) {
      // AI kaynakları temizlenir
    } else {
      _onlineLogic?.dispose();
    }
    
    matchState.dispose();
    super.dispose();
  }
}