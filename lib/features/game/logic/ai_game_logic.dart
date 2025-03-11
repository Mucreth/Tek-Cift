// lib/features/game/logic/ai_game_logic.dart

import 'dart:async';
import 'dart:math';
import 'package:handclash/features/game/game_enums.dart';
import 'package:handclash/features/game/game_state.dart';
import 'package:handclash/features/game/game_ai_service.dart';
import 'package:handclash/features/game/services/game_joker_handler.dart';
import 'package:handclash/features/game/services/game_feedback_service.dart';
import 'package:handclash/features/game/services/game_move_handler.dart';

/// AI oyun mantığını yöneten sınıf.
/// AI modunda oyun akışını, karar verme mekanizmalarını ve sonuçları yönetir.
class AIGameLogic {
  final Random _random = Random();
  final GameAIService _aiService;
  final GameJokerHandler _jokerHandler;
  final GameFeedbackService _feedbackService;
  final GameMoveHandler _moveHandler;
  final String gameType;
  final int targetScore;
  
  final Function(GameState) _onStateUpdate;
  final Function(TimerStatus) _onTimerStatusUpdate;
  final Function(Map<String, dynamic>)? _onGameEnd;
  
  AIGameLogic({
    required this.gameType,
    required this.targetScore,
    required GameJokerHandler jokerHandler,
    required GameFeedbackService feedbackService,
    required GameMoveHandler moveHandler,
    required Function(GameState) onStateUpdate,
    required Function(TimerStatus) onTimerStatusUpdate,
    Function(Map<String, dynamic>)? onGameEnd,
  }) : _jokerHandler = jokerHandler,
       _feedbackService = feedbackService,
       _moveHandler = moveHandler,
       _onStateUpdate = onStateUpdate,
       _onTimerStatusUpdate = onTimerStatusUpdate,
       _onGameEnd = onGameEnd,
       _aiService = GameAIService();
  
  /// AI oyununu başlat
  void startGame(GameState initialState) {
    print('AI oyunu başlatılıyor...');
    
    // Hazırlık fazını atla, direkt everyoneReady fazına geç
    final updatedState = initialState.copyWith(
      currentPhase: GamePhase.everyoneReady,
      isPlayerReady: true,
      isOpponentReady: true,
      currentRound: 0, // İlk round başlayacak
    );
    
    _onTimerStatusUpdate(TimerStatus.everyoneReady);
    _onStateUpdate(updatedState);
    
    // Oyun başlama sesi
    _feedbackService.playGameStartSound();
    
    // 2 saniye sonra ilk roundu başlat
    Future.delayed(Duration(seconds: 2), () {
      startNewRound(updatedState);
    });
  }
  
  /// Yeni round başlat
  void startNewRound(GameState state) {
    // Round sayacını artır
    final nextRound = state.currentRound + 1;
    
    // Yeni state oluştur
    final updatedState = state.copyWith(
      currentRound: nextRound,
      currentPhase: GamePhase.cardSelect,
      selectedMove: null,
      opponentMove: null,
      selectedJoker: null,
      opponentJoker: null,
      blockedMoves: state.nextRoundBlockedMoves, // Bir önceki roundun nextBlockedMoves'ı
      nextRoundBlockedMoves: [], // Yeni round için temizle
      isRoundActive: true,
      preparationTimeLeft: 8, // Varsayılan süre
    );
    
    // Kart seçim fazına geç
    _onTimerStatusUpdate(TimerStatus.cardSelect);
    _onStateUpdate(updatedState);
    
    // Kart yerleştirme sesi
    _feedbackService.playCardPlaceSound();
    
    // AI'nın hamle yapması için zaman tanı
    makeAIMove(updatedState);
  }
  
  /// AI hamlesi yap
  void makeAIMove(GameState state) {
    // AI'ya biraz düşünme süresi ver (500-1500ms arası)
    Future.delayed(Duration(milliseconds: _random.nextInt(1000) + 500), () {
      if (state.currentPhase != GamePhase.cardSelect) return;
      
      // AI'nın hamlesini hesapla
      final aiMove = _aiService.predictNextMove(gameType, state.blockedMoves);
      
      // State'i güncelle
      final updatedState = state.copyWith(opponentMove: aiMove);
      _onStateUpdate(updatedState);
      
      // Eğer oyuncu da hamlesini yaptıysa, revealing fazına geç
      if (updatedState.selectedMove != null) {
        handleRevealingPhase(updatedState);
      }
    });
  }
  
  /// Oyuncu hamle yaptığında
  void handlePlayerMove(GameState state, String move) {
    // Hamleyi kaydet
    final updatedState = state.copyWith(selectedMove: move);
    
    // Kart yerleştirme sesi
    _feedbackService.playCardPlaceSound();
    
    // State'i güncelle
    _onStateUpdate(updatedState);
    
    // Eğer AI da hamlesini yaptıysa, revealing fazına geç
    if (updatedState.opponentMove != null) {
      handleRevealingPhase(updatedState);
    }
  }
  
  /// Kart açılma fazını işle
  void handleRevealingPhase(GameState state) {
    // Kart çevirme fazına geç
    final updatedState = state.copyWith(currentPhase: GamePhase.revealing);
    
    // Timer statusu güncelle
    _onTimerStatusUpdate(TimerStatus.revealing);
    
    // State'i güncelle
    _onStateUpdate(updatedState);
    
    // Kart çevirme sesi
    _feedbackService.playCardFlipSound();
    
    // 2 saniye sonra sonuç fazına geç
    Future.delayed(Duration(seconds: 2), () {
      handleRoundResultPhase(updatedState);
    });
  }
  
  /// Round sonuç fazını işle
  void handleRoundResultPhase(GameState state) {
    // Kazananı belirle
    // NOT: _moveHandler.calculateWinner sadece iki parametre almalı, 
    // çünkü gameType zaten constructor'da belirtilmiş olmalı
    final result = _moveHandler.calculateWinner(
      state.selectedMove,
      state.opponentMove
    );
    
    // Skor değerlerini güncelle
    int playerScore = state.playerScore;
    int opponentScore = state.opponentScore;
    bool playerWin = false;
    
    if (result == 'player') {
      playerScore++;
      playerWin = true;
    } else if (result == 'opponent') {
      opponentScore++;
    }
    
    // Sonuç fazına geç
    final updatedState = state.copyWith(
      currentPhase: GamePhase.roundResult,
      playerScore: playerScore,
      opponentScore: opponentScore,
      isRoundActive: false
    );
    
    // Timer statusu güncelle
    _onTimerStatusUpdate(TimerStatus.roundResult);
    
    // State'i güncelle
    _onStateUpdate(updatedState);
    
    // Sonuç sesi ve titreşimi
    _feedbackService.provideFeedbackForGameResult(playerWin);
    
    // Oyuncunun hamlesini AI'nin hafızasına ekle
    if (state.selectedMove != null) {
      _aiService.recordPlayerMove(state.selectedMove!);
    }
    
    // 3 saniye sonra joker seçim fazına geç
    Future.delayed(Duration(seconds: 3), () {
      handleJokerSelectPhase(updatedState);
    });
  }
  
  /// Joker seçim fazını işle
void handleJokerSelectPhase(GameState state) {
  // KONTROL EKLE: Her iki tarafın da joker hakkı kalmadı mı?
  // Oyuncunun joker hakları
  bool playerHasJokers = state.availableJokers.values.any((count) => count > 0);
  
  // AI'nın joker hakları (aynı map'i kullanıyor, AI sadece kullanacağını seçiyor)
  bool aiHasJokers = state.availableJokers.values.any((count) => count > 0);
  
  // Eğer iki tarafın da joker hakkı kalmadıysa, joker fazını atla
  if (!playerHasJokers && !aiHasJokers) {
    print('AI modunda joker fazı atlanıyor - joker hakkı kalmadı');
    
    // Joker atlandı fazına geç
    final updatedState = state.copyWith(
      currentPhase: GamePhase.jokerSkipped,
      jokerUsageStatus: 'none', // Joker kullanılmadı
    );
    
    // Timer statusu güncelle
    _onTimerStatusUpdate(TimerStatus.jokerSkipped);
    
    // State'i güncelle
    _onStateUpdate(updatedState);
    
    // Direkt olarak round sonu fazına geç
    Future.delayed(Duration(seconds: 2), () {
      finalizeRound(updatedState);
    });
    
    return; // Joker fazı atlandı, fonksiyonu sonlandır
  }
  
  // Normal joker fazı akışı - joker hakları var
  // Joker seçim fazına geç
  final updatedState = state.copyWith(
    currentPhase: GamePhase.jokerSelect,
    preparationTimeLeft: 10 // Değişiklik burada: 5 -> 10
  );
  
  // Timer statusu güncelle
  _onTimerStatusUpdate(TimerStatus.jokerTime);
  
  // State'i güncelle
  _onStateUpdate(updatedState);
  
  // AI joker kararı için zaman tanı
  makeAIJokerDecision(updatedState);
}
  
  /// AI'nın joker kararını ver
void makeAIJokerDecision(GameState state) {
  // AI'ya biraz düşünme süresi ver (800-1800ms arası)
  Future.delayed(Duration(milliseconds: _random.nextInt(1000) + 800), () {
    if (state.currentPhase != GamePhase.jokerSelect) return;
    
    // AI'nın joker kararını hesapla
    final aiJoker = _aiService.decideJoker(
      state.availableJokers,
      state.usedJokers,
      state.selectedMove ?? '',
      state.currentRound,
      targetScore
    );
    
    // State'i güncelle
    final updatedState = state.copyWith(opponentJoker: aiJoker);
    
    // Joker kullanım durumunu belirle
    String jokerUsageStatus = 'none';
    if (updatedState.selectedJoker != null && aiJoker != null) {
      jokerUsageStatus = 'both'; // Her iki taraf da joker kullandı
    } else if (updatedState.selectedJoker != null) {
      jokerUsageStatus = 'green'; // Sadece yeşil takım (oyuncu) joker kullandı
    } else if (aiJoker != null) {
      jokerUsageStatus = 'red'; // Sadece kırmızı takım (AI) joker kullandı
    }
    
    // Joker kullanım durumunu state'e ekle
    final finalState = updatedState.copyWith(jokerUsageStatus: jokerUsageStatus);
    _onStateUpdate(finalState);
    
    // Eğer oyuncu da joker seçimini yaptıysa veya joker kullanmadıysa, joker reveal fazına geç
    if (finalState.selectedJoker != null || aiJoker == null) {
      handleJokerRevealPhase(finalState);
    }
  });
}

  
  /// Oyuncu joker kullandığında
void handlePlayerJoker(GameState state, JokerType jokerType) {
  // Joker sayısını azalt
  final updatedJokers = Map<JokerType, int>.from(state.availableJokers);
  if (updatedJokers.containsKey(jokerType) && (updatedJokers[jokerType] ?? 0) > 0) {
    updatedJokers[jokerType] = (updatedJokers[jokerType] ?? 0) - 1;
  }
  
  // Kullanılan jokerlere ekle
  Set<JokerType> newUsedJokers = Set.from(state.usedJokers)..add(jokerType);
  
  // Joker kullanım durumu
  String jokerUsageStatus = state.opponentJoker != null ? 'both' : 'green';
  
  // State'i güncelle
  final updatedState = state.copyWith(
    selectedJoker: jokerType,
    availableJokers: updatedJokers,
    usedJokers: newUsedJokers,
    jokerUsageStatus: jokerUsageStatus
  );
  
  // Joker sesi
  _feedbackService.playJokerSound();
  
  // State'i güncelle
  _onStateUpdate(updatedState);
  
  // Eğer AI da joker kararını verdiyse, joker reveal fazına geç
  if (updatedState.opponentJoker != null) {
    handleJokerRevealPhase(updatedState);
  }
}
  
  /// Joker gösterim fazını işle
  void handleJokerRevealPhase(GameState state) {
  // Joker kullanımlarını kontrol et
  final playerJoker = state.selectedJoker;
  final opponentJoker = state.opponentJoker;
  
  // Joker kullanım durumunu belirle (eğer zaten belirlenmemişse)
  String jokerUsageStatus = state.jokerUsageStatus;
  if (jokerUsageStatus == 'none') {
    if (playerJoker != null && opponentJoker != null) {
      jokerUsageStatus = 'both'; 
    } else if (playerJoker != null) {
      jokerUsageStatus = 'green';
    } else if (opponentJoker != null) {
      jokerUsageStatus = 'red';
    }
  }
  
  // Jokerlerin etkilerini uygula
  final afterJokersState = _jokerHandler.applyJokerEffects(
    state: state,
    playerJoker: playerJoker,
    opponentJoker: opponentJoker,
    isAIMode: true
  );
  
  // Joker gösterim fazına geç
  final updatedState = afterJokersState.copyWith(
    currentPhase: GamePhase.jokerReveal,
    jokerUsageStatus: jokerUsageStatus
  );
  
  // Timer statusu güncelle
  _onTimerStatusUpdate(TimerStatus.jokerReveal);
  
  // State'i güncelle
  _onStateUpdate(updatedState);
  
  // Joker sesi (eğer en az bir joker kullanıldıysa)
  if (playerJoker != null || opponentJoker != null) {
    _feedbackService.playJokerSound();
  }
  
  // Oyuncunun joker kararını AI'ya bildir
  _aiService.recordPlayerJoker(playerJoker);
  
  // 5 saniye sonra round'u tamamla (Değişiklik burada: 2 -> 5)
  Future.delayed(Duration(seconds: 5), () {
    finalizeRound(updatedState);
  });
}
  
  /// Round'u tamamla
  void finalizeRound(GameState state) {
    // Round sonu fazına geç
    final updatedState = state.copyWith(currentPhase: GamePhase.roundEnd);
    
    // Timer statusu güncelle
    _onTimerStatusUpdate(TimerStatus.roundEnd);
    
    // State'i güncelle
    _onStateUpdate(updatedState);
    
    // Oyun bitti mi kontrol et
    final isGameOver = state.playerScore >= targetScore || state.opponentScore >= targetScore;
    
    // Round sonu titreşimi
    _feedbackService.provideFeedbackForRoundEnd(isGameOver);
    
    // Eğer oyun bittiyse, oyun sonu işlemlerini yap
    if (isGameOver) {
      Future.delayed(Duration(seconds: 2), () {
        endGame(updatedState);
      });
    } else {
      // Yeni round başlat
      Future.delayed(Duration(seconds: 2), () {
        startNewRound(updatedState);
      });
    }
  }
  
  /// Oyunu bitir
  void endGame(GameState state) {
    // Kazananı belirle
    final bool isWinner = state.playerScore > state.opponentScore;
    
    // Kazanç hesapla
    final int betAmount = state.betAmount;
    final int goldWon = isWinner ? (betAmount * 2) : 0;
    
    // Oyun sonu fazına geç
    final updatedState = state.copyWith(
      currentPhase: GamePhase.gameOver,
      goldWon: isWinner ? goldWon : 0,
      goldLost: !isWinner ? betAmount : 0
    );
    
    // Timer statusu güncelle
    _onTimerStatusUpdate(TimerStatus.gameOver);
    
    // State'i güncelle
    _onStateUpdate(updatedState);
    
    // Oyun sonu sesi
    _feedbackService.provideFeedbackForGameResult(isWinner);
    
    // Oyun sonu bilgisini callback ile ilet
    if (_onGameEnd != null) {
      _onGameEnd!({
        'isWinner': isWinner,
        'message': isWinner ? "Tebrikler! Kazandınız" : "Maalesef, Kaybettiniz",
        'goldWon': goldWon
      });
    }
    
    // AI geçmişini temizle
    _aiService.resetHistory();
  }
}