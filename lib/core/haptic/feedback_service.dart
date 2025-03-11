// lib/shared/services/feedback_service.dart
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

class FeedbackService {
  static final FeedbackService _instance = FeedbackService._internal();
  static FeedbackService get instance => _instance;
  
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isSoundEnabled = true;
  bool _isVibrationEnabled = true;
  
  FeedbackService._internal();
  
  // Ses ayarını açıp kapatma
  void setSoundEnabled(bool enabled) {
    _isSoundEnabled = enabled;
  }
  
  // Titreşim ayarını açıp kapatma
  void setVibrationEnabled(bool enabled) {
    _isVibrationEnabled = enabled;
  }
  
  // Kart sesi çalma
  Future<void> playCardSound({bool isFlipping = true}) async {
    if (!_isSoundEnabled) return;
    
    final source = isFlipping 
        ? AssetSource('sounds/card_flip.mp3') 
        : AssetSource('sounds/card_place.mp3');
    
    await _audioPlayer.play(source);
  }
  
  // Oyun başlama sesi
  Future<void> playGameStartSound() async {
    if (!_isSoundEnabled) return;
    await _audioPlayer.play(AssetSource('sounds/game_start.mp3'));
  }
  
  // Tur sonucu sesi (kazanma/kaybetme)
  Future<void> playRoundResultSound({required bool isWin}) async {
    if (!_isSoundEnabled) return;
    
    final source = isWin 
        ? AssetSource('sounds/win_round.mp3') 
        : AssetSource('sounds/lose_round.mp3');
    
    await _audioPlayer.play(source);
  }
  
  // Joker sesi
  Future<void> playJokerSound() async {
    if (!_isSoundEnabled) return;
    await _audioPlayer.play(AssetSource('sounds/joker_used.mp3'));
  }
  
  // Titreşim fonksiyonları
  
  // Kısa titreşim (normal bildirim)
  Future<void> vibrateShort() async {
    if (!_isVibrationEnabled) return;
    
    final hasVibrator = await Vibration.hasVibrator() ?? false;
    if (hasVibrator) {
      Vibration.vibrate(duration: 100);
    }
  }
  
  // Orta titreşim (joker vb.)
  Future<void> vibrateMedium() async {
    if (!_isVibrationEnabled) return;
    
    final hasVibrator = await Vibration.hasVibrator() ?? false;
    if (hasVibrator) {
      Vibration.vibrate(duration: 200, amplitude: 128);
    }
  }
  
  // Uzun titreşim (oyun sonu, kaybetme)
  Future<void> vibrateLong() async {
    if (!_isVibrationEnabled) return;
    
    final hasVibrator = await Vibration.hasVibrator() ?? false;
    final hasAmplitude = await Vibration.hasAmplitudeControl() ?? false;
    
    if (hasVibrator) {
      if (hasAmplitude) {
        // Güçlü titreşim deseni
        Vibration.vibrate(
          pattern: [0, 100, 80, 100, 80, 300],
          intensities: [0, 128, 0, 255, 0, 128],
        );
      } else {
        // Basit titreşim deseni
        Vibration.vibrate(
          pattern: [0, 200, 100, 300],
        );
      }
    }
  }
}