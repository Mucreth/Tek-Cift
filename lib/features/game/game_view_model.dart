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
  
  /// Hamle yap
  void makeMove(String move) {
    // Hamle yapma durumunu kontrol et
    if (!_state.isRoundActive ||
        (_state.currentPhase != GamePhase.playing && 
         _state.currentPhase != GamePhase.cardSelect)) {
      return;
    }
    
    // Bloke durumunu kontrol et
    if (_state.blockedMoves.contains(move)) {
      return;
    }
    
    // Kart yerleştirme sesi
    _feedbackService.playCardPlaceSound();
    
    if (isAIGame) {
      // AI modunda, hamle AI'ye iletilir
      _aiLogic?.handlePlayerMove(_state, move);
    } else {
      // Çevrimiçi modda, hamleyi sunucuya gönder
      
      // Önce state'i güncelle
      _state = _state.copyWith(selectedMove: move);
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
    print('Oyun eşleşti. ID: ${data['gameId']}');
    
    // Eşleşme olayını OnlineGameLogic'e ilet
    _onlineLogic?.handleGameMatched(_state, data);
    
    // Önceki zamanayıcıları temizle
    _timerManager.clearAllTimers();
    
    // Eşleşme durumunu güncelle
    matchState.value = GameMatchState.opponentFound;
    
    // Takım rengi ve rakip adı bilgilerini al
    bool isGreenTeam = data['isGreenTeam'] == 1 || data['isGreenTeam'] == true;
    String? opponentNickname = data['opponentNickname'] ?? 'Rakip';
    
    // State'i güncelle
    _state = _state.copyWith(
      currentPhase: GamePhase.preparation,
      preparationTimeLeft: 10,
      isPlayerReady: false,
      isOpponentReady: false,
      betAmount: data['betAmount'] ?? 1000,
      isGreenTeam: isGreenTeam,
      opponentName: opponentNickname,
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
    
    // Faz yöneticisine ilet
    _phaseManager.handleCardSelectPhase(_state, data);
    
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