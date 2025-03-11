// lib/features/game/logic/game_result_processor.dart

import 'package:handclash/features/auth/auth_service.dart';
import 'package:handclash/features/game/game_enums.dart';
import 'package:handclash/features/game/game_state.dart';
import 'package:handclash/features/game/services/game_feedback_service.dart';

/// Oyun sonuç işleme sınıfı.
/// Oyun sonuçlarını, kazanç/kayıp hesaplamalarını ve kullanıcı bilgilerini güncellemeyi yönetir.
class GameResultProcessor {
  final GameFeedbackService _feedbackService;
  final Function(Map<String, dynamic>)? _onGameEnd;
  final AuthService _authService = AuthService();
  
  GameResultProcessor({
    required GameFeedbackService feedbackService,
    Function(Map<String, dynamic>)? onGameEnd,
  }) : _feedbackService = feedbackService,
       _onGameEnd = onGameEnd;
  
  /// Çevrimiçi oyun sonu sonuçlarını işle
  Future<GameState> processOnlineGameEnd(GameState state, Map<String, dynamic> data) async {
    // Teslim olma durumunu kontrol et
    if (data.containsKey('surrenderedPlayer') && data.containsKey('winner')) {
      return await _processSurrenderGameEnd(state, data);
    } else {
      return await _processNormalGameEnd(state, data);
    }
  }
  
  /// Normal oyun sonu sonuçlarını işle
  Future<GameState> _processNormalGameEnd(GameState state, Map<String, dynamic> data) async {
  bool isWinner = false;
  bool isDraw = false;
  int goldResult = 0;
  String message = "";
  
  // Debug için veriyi yazdır
  print("Game End Data: $data, isGreenTeam: ${state.isGreenTeam}");
  
  // Kazananı belirle
  String winnerId = data['winner']?.toString() ?? '';
  String currentUserId = await _authService.getCurrentUserId();
  
  // 'draw' durumu kontrolü
  if (winnerId == 'draw') {
    isDraw = true;
  } else {
    // Kazananın mevcut kullanıcı olup olmadığını kontrol et
    isWinner = (winnerId == currentUserId);
  }
  
  print("Kazanan kontrolü: winnerId=$winnerId, currentUserId=$currentUserId, isWinner=$isWinner, isDraw=$isDraw");
  
  // Kazanç veya kayıp hesapla
  if (isWinner) {
    // Kazanan oyuncu bahis * 2 altın kazanır
    goldResult = (state.betAmount * 2);
    message = "Tebrikler! Kazandınız";
    _feedbackService.vibrateMedium();
  } else if (isDraw) {
    // Beraberlikte bahis iade edilir
    goldResult = state.betAmount;
    message = "Berabere!";
  } else {
    // Kaybedildiğinde miktar kaydedilir (zaten bahis düşüldü)
    goldResult = 0;
    message = "Maalesef, Kaybettiniz";
    _feedbackService.vibrateLong();
  }
  
  // Sonuç sesini çal
  _feedbackService.playRoundResultSound(isWin: isWinner);
  
  // Yeni durum oluştur
  final updatedState = state.copyWith(
    currentPhase: GamePhase.gameOver,
    isRoundActive: false,
    goldWon: isWinner || isDraw ? goldResult : 0,
    goldLost: !isWinner && !isDraw ? state.betAmount : 0,
  );
  
  // Kullanıcı altınını güncelle
  await _updateUserGold();
  
  // Oyun sonu bilgisini callback ile ilet
  if (_onGameEnd != null) {
    _onGameEnd!({
      'isWinner': isWinner,
      'message': message,
      'goldWon': isWinner ? goldResult : 0
    });
  }
  
  return updatedState;
}
  
  /// Teslim olma durumundaki oyun sonu sonuçlarını işle
  Future<GameState> _processSurrenderGameEnd(GameState state, Map<String, dynamic> data) async {
    String currentUserId = _authService.getCurrentUserId();
    String surrenderedPlayerId = data['surrenderedPlayer'];
    String winnerId = data['winner'];
    
    bool isWinner = false;
    String message = "";
    int goldResult = 0;
    
    // Teslim olan oyuncu kontrolü
    if (currentUserId == surrenderedPlayerId) {
      // Siz teslim olmuşsunuz
      isWinner = false;
      message = "Oyundan ayrıldınız.";
      goldResult = 0;
    } else if (currentUserId == winnerId) {
      // Siz kazanmışsınız
      isWinner = true;
      message = "Rakip oyundan ayrıldı!";
      goldResult = (state.betAmount * 2);
    } else {
      // ID eşleşmesi sorunu var
      isWinner = false; // Varsayılan olarak kaybeden göster
      message = "Bilinmeyen sonuç";
      goldResult = 0;
    }
    
    // Sonuç sesini çal
    _feedbackService.playRoundResultSound(isWin: isWinner);
    
    // Yeni durum oluştur
    final updatedState = state.copyWith(
      currentPhase: GamePhase.gameOver,
      isRoundActive: false,
      goldWon: isWinner ? goldResult : 0,
      goldLost: !isWinner ? state.betAmount : 0,
    );
    
    // Kullanıcı altınını güncelle
    await _updateUserGold();
    
    // Oyun sonu bilgisini callback ile ilet
    if (_onGameEnd != null) {
      _onGameEnd!({
        'isWinner': isWinner,
        'message': message,
        'goldWon': isWinner ? goldResult : 0
      });
    }
    
    return updatedState;
  }
  
  /// AI oyun sonu sonuçlarını işle
  Future<GameState> processAIGameEnd(GameState state) async {
    // Kazananı belirle
    final bool isWinner = state.playerScore > state.opponentScore;
    
    // Kazanç hesapla
    final int betAmount = state.betAmount;
    final int goldResult = isWinner ? (betAmount * 2) : 0;
    final String message = isWinner ? "Tebrikler! Kazandınız" : "Maalesef, Kaybettiniz";
    
    // Sonuç sesini çal
    _feedbackService.provideFeedbackForGameResult(isWinner);
    
    // Yeni durum oluştur
    final updatedState = state.copyWith(
      currentPhase: GamePhase.gameOver,
      goldWon: isWinner ? goldResult : 0,
      goldLost: !isWinner ? betAmount : 0
    );
    
    // Kullanıcı altınını güncelle
    await _updateUserGold();
    
    // Oyun sonu bilgisini callback ile ilet
    if (_onGameEnd != null) {
      _onGameEnd!({
        'isWinner': isWinner,
        'message': message,
        'goldWon': isWinner ? goldResult : 0
      });
    }
    
    return updatedState;
  }
  
  /// Kullanıcı altınını güncelle
  Future<void> _updateUserGold() async {
    try {
      // Kullanıcı bilgilerini yenile (bu, sunucudan güncel bilgiyi çekecek)
      await _authService.getCurrentUser();
    } catch (e) {
      print('Altın güncelleme hatası: $e');
    }
  }
}