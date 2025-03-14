// lib/features/game/services/game_phase_manager.dart

import 'package:handclash/features/game/game_enums.dart';
import 'package:handclash/features/game/game_state.dart';
import 'package:handclash/features/game/services/game_joker_handler.dart';

/// Oyun fazlarını yöneten sınıf.
/// Farklı oyun fazları arasında geçişleri ve faz bazlı işlemleri yönetir.
class GamePhaseManager {
  final GameJokerHandler _jokerHandler;
  final Function(GameState) _onStateUpdate;
  final Function(TimerStatus) _onTimerStatusUpdate;

  GamePhaseManager({
    required GameJokerHandler jokerHandler,
    required Function(GameState) onStateUpdate,
    required Function(TimerStatus) onTimerStatusUpdate,
  }) : _jokerHandler = jokerHandler,
       _onStateUpdate = onStateUpdate,
       _onTimerStatusUpdate = onTimerStatusUpdate;

  /// Hazırlık fazını işle
  void handlePreparationPhase(GameState state, Map<String, dynamic> data) {
    // Hazırlık süresi
    final timeLimit = data['timeLimit'] ?? 10;

    // Güncellenen durumu oluştur
    final updatedState = state.copyWith(
      currentPhase: GamePhase.preparation,
      preparationTimeLeft: timeLimit,
      isPlayerReady: false,
      isOpponentReady: false,
    );

    // Yeni timer status'u belirle
    _onTimerStatusUpdate(TimerStatus.preparation);

    // State güncelleme callback'i çağır
    _onStateUpdate(updatedState);
  }

  /// Kart seçim fazını işle
  void handleCardSelectPhase(GameState state, Map<String, dynamic> data) {
    // Debug için
    print("Kart seçim fazına geçiliyor. Önceki seçim: ${state.selectedMove}");

    // Kart seçim süresi
    final timeLimit = data['timeLimit'] ?? 12;

    // Round numarası
    final roundNumber = data['roundNumber'] ?? state.currentRound;

    // Bahis çarpanı
    final betMultiplier = data['betMultiplier']?.toDouble() ?? 1.0;

    // Bloklanmış hamleleri hesapla
    final blockedMoves = _jokerHandler.calculateBlockedMovesFromServerData(
      data,
      state.isGreenTeam,
    );

    // Güncellenen durumu oluştur - Yeni round için selectedMove sıfırlanmalı
    final updatedState = state.copyWith(
      currentPhase: GamePhase.cardSelect,
      isRoundActive: true,
      currentRound: roundNumber,
      blockedMoves: blockedMoves,
      preparationTimeLeft: timeLimit,
      betMultiplier: betMultiplier,
      selectedMove: null, // Her round başında seçim sıfırla
    );

    // Debug için
    print(
      "Kart seçim fazına geçildi. Yeni durum: selectedMove=${updatedState.selectedMove}",
    );

    // Yeni timer status'u belirle
    _onTimerStatusUpdate(TimerStatus.cardSelect);

    // State güncelleme callback'i çağır
    _onStateUpdate(updatedState);
  }

  /// Kart açılma fazını işle
  void handleRevealingPhase(GameState state, Map<String, dynamic> data) {
    // Hamleleri belirle
    final movesData = data['moves'];
    if (movesData == null) {
      _onStateUpdate(state.copyWith(currentPhase: GamePhase.revealing));
      _onTimerStatusUpdate(TimerStatus.revealing);
      return;
    }

    String? playerMove;
    String? opponentMove;

    // Yeşil/kırmızı takım durumuna göre hamleleri belirle
    if (state.isGreenTeam) {
      playerMove = movesData['player1'];
      opponentMove = movesData['player2'];
    } else {
      playerMove = movesData['player2'];
      opponentMove = movesData['player1'];
    }

    // Timeout durumunu kontrol et
    if (opponentMove == 'timeout') {
      opponentMove = null;
    }

    // Güncellenen durumu oluştur
    final updatedState = state.copyWith(
      currentPhase: GamePhase.revealing,
      selectedMove: playerMove,
      opponentMove: opponentMove,
    );

    // Yeni timer status'u belirle
    _onTimerStatusUpdate(TimerStatus.revealing);

    // State güncelleme callback'i çağır
    _onStateUpdate(updatedState);
  }

  /// Round sonuç fazını işle
  void handleRoundResultPhase(GameState state, Map<String, dynamic> data) {
    // Debug için veriyi yazdır
    print("Round Result Phase Data: $data");
    print(
      "State before update: isGreenTeam=${state.isGreenTeam}, playerScore=${state.playerScore}, opponentScore=${state.opponentScore}",
    );

    // Kazananı belirle
    final result = data['result'];
    if (result == null) {
      _onStateUpdate(state.copyWith(currentPhase: GamePhase.roundResult));
      _onTimerStatusUpdate(TimerStatus.roundResult);
      return;
    }

    // Hamleleri belirle
    final movesData = data['moves'];

    // Skor değerlerini belirle
    int playerWins = state.playerScore;
    int opponentWins = state.opponentScore;

    // Yeşil/kırmızı takım durumuna göre skor değerlerini güncelle
    if (state.isGreenTeam) {
      playerWins = data['player1Wins'] ?? state.playerScore;
      opponentWins = data['player2Wins'] ?? state.opponentScore;
    } else {
      playerWins = data['player2Wins'] ?? state.playerScore;
      opponentWins = data['player1Wins'] ?? state.opponentScore;
    }

    // Debug için skor güncellemesini yazdır
    print("Score update - isGreenTeam: ${state.isGreenTeam}");
    print(
      "Score update - data values: player1Wins=${data['player1Wins']}, player2Wins=${data['player2Wins']}",
    );
    print(
      "Score update - calculated: playerWins=$playerWins, opponentWins=$opponentWins",
    );

    // Rakibin hamlesini belirle
    String? opponentMove = null;
    if (movesData != null) {
      opponentMove =
          state.isGreenTeam ? movesData['player2'] : movesData['player1'];
    }

    // Güncellenen durumu oluştur
    final updatedState = state.copyWith(
      currentPhase: GamePhase.roundResult,
      isRoundActive: false,
      playerScore: playerWins,
      opponentScore: opponentWins,
      opponentMove: opponentMove,
    );

    // Yeni timer status'u belirle
    _onTimerStatusUpdate(TimerStatus.roundResult);

    // Debug için son durumu yazdır
    print(
      "Final state: playerScore=${updatedState.playerScore}, opponentScore=${updatedState.opponentScore}",
    );

    // State güncelleme callback'i çağır
    _onStateUpdate(updatedState);
  }

  /// Joker seçim fazını işle
  void handleJokerSelectPhase(GameState state, Map<String, dynamic> data) {
    // Joker seçim süresi
    final timeLimit = data['timeLimit'] ?? 10;

    // Kullanılabilir jokerleri belirle
    Map<JokerType, int> updatedJokers = Map.from(state.availableJokers);

    final availableJokersData = data['availableJokers'];
    if (availableJokersData != null) {
      final playerJokersData =
          state.isGreenTeam
              ? availableJokersData['player1']
              : availableJokersData['player2'];

      if (playerJokersData != null) {
        updatedJokers[JokerType.block] = playerJokersData['block'] ?? 0;
        updatedJokers[JokerType.blind] =
            playerJokersData['hook'] ?? 0; // Server'da 'hook'
        updatedJokers[JokerType.bet] = playerJokersData['bet'] ?? 0;
      }
    }

    // Güncellenen durumu oluştur
    final updatedState = state.copyWith(
      currentPhase: GamePhase.jokerSelect,
      isRoundActive: false,
      preparationTimeLeft: timeLimit,
      availableJokers: updatedJokers,
      selectedJoker: null, // Yeni round için joker seçimi sıfırla
    );

    // Yeni timer status'u belirle
    _onTimerStatusUpdate(TimerStatus.jokerTime);

    // State güncelleme callback'i çağır
    _onStateUpdate(updatedState);
  }

  /// Joker gösterim fazını işle
  void handleJokerRevealPhase(GameState state, Map<String, dynamic> data) {
    // Joker tiplerini belirle
    final jokersMap = _jokerHandler.extractJokersFromServerData(
      data,
      state.isGreenTeam,
    );

    final playerJoker = jokersMap['playerJoker'];
    final opponentJoker = jokersMap['opponentJoker'];

    // Sonraki roundda bloke edilecek hamleleri belirle
    List<String> nextRoundBlocked = [];
    final nextRoundBlockedData = data['nextRoundBlockedMoves'];

    if (nextRoundBlockedData != null) {
      if (state.isGreenTeam) {
        nextRoundBlocked = List<String>.from(
          nextRoundBlockedData['player1'] ?? [],
        );
      } else {
        nextRoundBlocked = List<String>.from(
          nextRoundBlockedData['player2'] ?? [],
        );
      }
    }

    // Joker kullanım durumunu al (yeni özellik)
    final String jokerUsageStatus = data['jokerUsageStatus'] ?? 'none';

    // Debug log
    print('Joker gösterim fazı - Joker kullanım durumu: $jokerUsageStatus');

    // Joker etkilerini uygula
    final updatedState = _jokerHandler
        .applyJokerEffects(
          state: state,
          playerJoker: playerJoker,
          opponentJoker: opponentJoker,
        )
        .copyWith(
          currentPhase: GamePhase.jokerReveal,
          selectedJoker: playerJoker,
          opponentJoker: opponentJoker,
          nextRoundBlockedMoves: nextRoundBlocked,
          betMultiplier:
              data['betMultiplier']?.toDouble() ?? state.betMultiplier,
          jokerUsageStatus: jokerUsageStatus, // Joker kullanım durumunu ekle
        );

    // Yeni timer status'u belirle
    _onTimerStatusUpdate(TimerStatus.jokerReveal);

    // State güncelleme callback'i çağır
    _onStateUpdate(updatedState);
  }

  /// Round sonu fazını işle
  void handleRoundEndPhase(GameState state, Map<String, dynamic> data) {
    // Debug için veriyi yazdır
    print("Round End Phase Data: $data");
    print(
      "State before update: isGreenTeam=${state.isGreenTeam}, playerScore=${state.playerScore}, opponentScore=${state.opponentScore}",
    );

    // Skor değerlerini belirle
    int playerWins = state.playerScore;
    int opponentWins = state.opponentScore;

    // Yeşil/kırmızı takım durumuna göre skor değerlerini güncelle
    if (state.isGreenTeam) {
      playerWins = data['player1Wins'] ?? state.playerScore;
      opponentWins = data['player2Wins'] ?? state.opponentScore;
    } else {
      playerWins = data['player2Wins'] ?? state.playerScore;
      opponentWins = data['player1Wins'] ?? state.opponentScore;
    }

    // Debug için skor güncellemesini yazdır
    print("Score update - isGreenTeam: ${state.isGreenTeam}");
    print(
      "Score update - data values: player1Wins=${data['player1Wins']}, player2Wins=${data['player2Wins']}",
    );
    print(
      "Score update - calculated: playerWins=$playerWins, opponentWins=$opponentWins",
    );

    // Güncellenen durumu oluştur
    GameState updatedState = state.copyWith(
      currentPhase: GamePhase.roundEnd,
      playerScore: playerWins,
      opponentScore: opponentWins,
      betMultiplier: data['betMultiplier']?.toDouble() ?? state.betMultiplier,
      jokerUsageStatus:
          'none', // Round sonu ile joker kullanım durumunu sıfırla
      selectedMove: null, // Round sonunda seçili hamleyi temizle
    );

    // Oyun bitti mi kontrol et
    if (playerWins >= state.targetScore || opponentWins >= state.targetScore) {
      updatedState = updatedState.copyWith(currentPhase: GamePhase.gameOver);
      _onTimerStatusUpdate(TimerStatus.gameOver);
    } else {
      _onTimerStatusUpdate(TimerStatus.roundEnd);
    }

    // Debug için son durumu yazdır
    print(
      "Final state: playerScore=${updatedState.playerScore}, opponentScore=${updatedState.opponentScore}",
    );

    // State güncelleme callback'i çağır
    _onStateUpdate(updatedState);
  }
}
