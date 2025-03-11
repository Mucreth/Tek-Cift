// lib/features/game/services/game_timer_manager.dart

import 'dart:async';
import 'dart:ui';
import 'dart:math';
import 'package:handclash/features/game/game_state.dart';
import 'package:handclash/core/haptic/feedback_service.dart';

class GameTimerManager {
  Timer? _preparationTimer;
  Timer? _roundTimer;
  Timer? _jokerTimer;
  Timer? _phaseTimer;
  final Random _random = Random();
  final FeedbackService _feedbackService = FeedbackService.instance;
  
  final Function(GameState) onTimerUpdate;
  
  GameTimerManager({
    required this.onTimerUpdate,
  });

  void startPreparationTimer(GameState state, int seconds) {
    _preparationTimer?.cancel();
    GameState updatedState = state.copyWith(preparationTimeLeft: seconds);
    
    _preparationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (updatedState.preparationTimeLeft > 1) {
        updatedState = updatedState.copyWith(
          preparationTimeLeft: updatedState.preparationTimeLeft - 1,
        );
        onTimerUpdate(updatedState);
      } else {
        timer.cancel();
        updatedState = updatedState.copyWith(
          preparationTimeLeft: 0,
        );
        onTimerUpdate(updatedState);
      }
    });
  }

  void startRoundTimer(GameState state, int seconds) {
    _roundTimer?.cancel();
    GameState updatedState = state.copyWith(preparationTimeLeft: seconds);

    _roundTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (updatedState.preparationTimeLeft > 1) {
        updatedState = updatedState.copyWith(
          preparationTimeLeft: updatedState.preparationTimeLeft - 1,
        );
        onTimerUpdate(updatedState);
      } else {
        timer.cancel();
        updatedState = updatedState.copyWith(
          preparationTimeLeft: 0,
        );
        onTimerUpdate(updatedState);
      }
    });
  }
  
  void startJokerTimer(GameState state, int seconds) {
    _jokerTimer?.cancel();
    GameState updatedState = state.copyWith(preparationTimeLeft: seconds);

    _jokerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (updatedState.preparationTimeLeft > 1) {
        updatedState = updatedState.copyWith(
          preparationTimeLeft: updatedState.preparationTimeLeft - 1,
        );
        onTimerUpdate(updatedState);
      } else {
        timer.cancel();
        updatedState = updatedState.copyWith(
          preparationTimeLeft: 0,
        );
        onTimerUpdate(updatedState);
      }
    });
  }

  // Kart seçme timer'ı - İyileştirilmiş sürüm
  // Kart seçim timer'ı - Yeni round için sıfırlanmış seçim ile
  void startCardSelectTimer(GameState state, int seconds, String gameType, Function(String) makeMove) {
    _roundTimer?.cancel();
    
    // Yeni bir round başlarken seçilen hamleyi sıfırla (kart seçim ekranında kart seçili olmamalı)
    GameState updatedState = state.copyWith(
      preparationTimeLeft: seconds,
      selectedMove: null // Yeni round başlarken seçim sıfırla
    );
    
    bool moveSubmitted = false;
    
    // Son 3 saniye uyarı için kullanılacak
    bool warningTriggered = false;

    _roundTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Son 3 saniyede cihaz titreşsin (uyarı)
      if (updatedState.preparationTimeLeft <= 3 && !warningTriggered) {
        warningTriggered = true;
        _feedbackService.vibrateMedium();
      }
      
      if (updatedState.preparationTimeLeft > 1) {
        updatedState = updatedState.copyWith(
          preparationTimeLeft: updatedState.preparationTimeLeft - 1,
        );
        onTimerUpdate(updatedState);
      } else {
        // Süre bitmek üzere, son saniyede hamleyi kontrol et
        if (!moveSubmitted) {
          if (updatedState.selectedMove != null) {
            // Zaten seçilmiş hamleyi tekrar gönder
            makeMove(updatedState.selectedMove!);
            moveSubmitted = true;
            print('Süre sonunda hamle tekrar gönderildi: ${updatedState.selectedMove}');
          } else {
            // Kullanıcı hamle seçmemiş - titreşim geri bildirimi ver
            _feedbackService.vibrateLong(); // Daha güçlü titreşim (uzun)
            
            // Kullanıcı hiç hamle seçmediyse rastgele bir hamle seç
            final availableMoves = gameType == 'rps' 
                ? ['rock', 'paper', 'scissors'] 
                : ['odd', 'even'];
                
            // Bloklanan hamleleri çıkar  
            final possibleMoves = availableMoves
                .where((move) => !updatedState.blockedMoves.contains(move))
                .toList();
                
            if (possibleMoves.isNotEmpty) {
              // Possibe moves'u karıştır
              possibleMoves.shuffle(_random);
              
              // Rastgele bir hamle seç
              final randomMove = possibleMoves.first;
              
              // State'i güncelle (UI güncellenmesi için)
              updatedState = updatedState.copyWith(selectedMove: randomMove);
              onTimerUpdate(updatedState);
              
              // Hamleyi gönder
              makeMove(randomMove);
              moveSubmitted = true;
              print('Kullanıcı hamle seçmedi, rastgele hamle gönderildi: $randomMove');
            } else {
              // Tüm hamleler bloklanmışsa timeout gönder
              makeMove('timeout');
              moveSubmitted = true;
              print('Tüm hamleler bloklandı, timeout gönderildi');
            }
          }
        }
        
        // Timer'ı durdur ve state'i güncelle
        timer.cancel();
        updatedState = updatedState.copyWith(
          preparationTimeLeft: 0,
        );
        onTimerUpdate(updatedState);
      }
    });
  }

  // Yeni: Genel faz timer'ı - belirli bir faz için belirli bir süre geçtikten sonra
  // bir callback fonksiyonu çağırır
  void startPhaseTimer(GameState state, int seconds, VoidCallback onComplete) {
    _phaseTimer?.cancel();
    GameState updatedState = state.copyWith(preparationTimeLeft: seconds);
    
    onTimerUpdate(updatedState);
    
    // Süre sonunda callback'i çağır
    _phaseTimer = Timer(Duration(seconds: seconds), onComplete);
  }

  void clearAllTimers() {
    _preparationTimer?.cancel();
    _roundTimer?.cancel();
    _jokerTimer?.cancel();
    _phaseTimer?.cancel();
  }

  void dispose() {
    clearAllTimers();
  }
}