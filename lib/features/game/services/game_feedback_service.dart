// lib/features/game/services/game_feedback_service.dart

import 'package:handclash/core/haptic/feedback_service.dart';
import 'package:handclash/features/game/game_enums.dart';

/// Oyun geri bildirim servisini yöneten sınıf.
/// Ses ve titreşim efektlerini oyun durumlarına göre yönetir.
class GameFeedbackService {
  final FeedbackService _feedbackService = FeedbackService.instance;
  
  /// Faz değişimi için geri bildirim sağla
  void provideFeedbackForPhaseChange(GamePhase phase) {
    switch (phase) {
      case GamePhase.everyoneReady:
        playGameStartSound();
        vibrateShort();
        break;
      case GamePhase.cardSelect:
        playCardPlaceSound();
        break;
      case GamePhase.revealing:
        playCardFlipSound();
        break;
      default:
        // Diğer fazlar için özel bir efekt gerekmiyor
        break;
    }
  }
  
  /// Oyun sonucu için geri bildirim sağla
  void provideFeedbackForGameResult(bool isWinner) {
    playRoundResultSound(isWin: isWinner);
    if (isWinner) {
      vibrateShort();
    } else {
      vibrateMedium();
    }
  }
  
  /// Round sonu için geri bildirim sağla
  void provideFeedbackForRoundEnd(bool isGameOver) {
    if (isGameOver) {
      vibrateLong();
    } else {
      vibrateShort();
    }
  }
  
  /// Joker kullanımı için geri bildirim sağla
  void provideFeedbackForJokerUsage() {
    playJokerSound();
    vibrateMedium();
  }
  
  /// Oyun başlama sesi
  void playGameStartSound() {
    _feedbackService.playGameStartSound();
  }
  
  /// Kart yerleştirme sesi
  void playCardPlaceSound() {
    _feedbackService.playCardSound(isFlipping: false);
  }
  
  /// Kart çevirme sesi
  void playCardFlipSound() {
    _feedbackService.playCardSound(isFlipping: true);
  }
  
  /// Round sonuç sesi
  void playRoundResultSound({required bool isWin}) {
    _feedbackService.playRoundResultSound(isWin: isWin);
  }
  
  /// Joker sesi
  void playJokerSound() {
    _feedbackService.playJokerSound();
  }
  
  /// Kısa titreşim
  void vibrateShort() {
    _feedbackService.vibrateShort();
  }
  
  /// Orta titreşim
  void vibrateMedium() {
    _feedbackService.vibrateMedium();
  }
  
  /// Uzun titreşim
  void vibrateLong() {
    _feedbackService.vibrateLong();
  }
}