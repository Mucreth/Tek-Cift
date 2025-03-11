// lib/features/game/services/game_joker_handler.dart

import 'dart:math';
import 'package:handclash/features/game/game_enums.dart';
import 'package:handclash/features/game/game_state.dart';

/// Joker mantığını ele alan sınıf.
/// Joker tipleri arasındaki dönüşümü ve joker etkilerinin uygulanmasını yönetir.
class GameJokerHandler {
  final Random _random = Random();
  final String gameType;
  
  GameJokerHandler({required this.gameType});
  
  /// Joker tipini server formatına dönüştürür
  String getJokerServerType(JokerType type) {
    switch (type) {
      case JokerType.block:
        return 'block';
      case JokerType.blind:
        return 'hook'; // Client'ta blind, server'da hook
      case JokerType.bet:
        return 'bet';
      default:
        return 'none';
    }
  }
  
  /// Server'daki joker tipini client formatına dönüştürür
  JokerType serverJokerTypeToClientType(String? serverType) {
    if (serverType == null) return JokerType.none;

    switch (serverType) {
      case 'block':
        return JokerType.block;
      case 'hook':
        return JokerType.blind; // Server'da hook, client'ta blind
      case 'bet':
        return JokerType.bet;
      default:
        return JokerType.none;
    }
  }

  /// Joker etkilerini uygular ve güncellenen değerleri döndürür
  GameState applyJokerEffects({
    required GameState state,
    required JokerType? playerJoker,
    required JokerType? opponentJoker,
    bool isAIMode = false
  }) {
    // Bahis jokerlerini kontrol et
    double updatedBetMultiplier = state.betMultiplier;
    if ((playerJoker == JokerType.bet) || (opponentJoker == JokerType.bet)) {
      updatedBetMultiplier *= 2.0;
    }
    
    // Bloke edilmiş hamleleri belirle
    List<String> nextRoundBlockedMoves = [];
    
    // Oyuncu blok jokeri kullandıysa
    if (playerJoker == JokerType.block) {
      // Rakibin sonraki round için bloke edilecek hamleleri
      final allMoves = gameType == 'rps' 
          ? ['rock', 'paper', 'scissors'] 
          : ['odd', 'even'];
      
      // Rastgele 2 (rps için) veya 1 (tek-çift için) hamle bloke et
      allMoves.shuffle(_random);
      final opponentBlockedCount = gameType == 'rps' ? 2 : 1;
      
      // Bu durumda isGreenTeam durumuna göre bloke edilecek hamleler değişmez
      // Çünkü burada sonraki roundda rakibin bloke edilecek hamleleri belirleniyor
    }
    
    // Rakip blok jokeri kullandıysa
    if (opponentJoker == JokerType.block) {
      // Oyuncunun sonraki round için bloke edilecek hamleleri
      final allMoves = gameType == 'rps' 
          ? ['rock', 'paper', 'scissors'] 
          : ['odd', 'even'];
      
      // Rastgele 2 (rps için) veya 1 (tek-çift için) hamle bloke et
      allMoves.shuffle(_random);
      nextRoundBlockedMoves = allMoves.sublist(0, gameType == 'rps' ? 2 : 1);
    }
    
    // Oyuncu kanca jokeri kullandıysa
    if (playerJoker == JokerType.blind && state.opponentMove != null) {
      // Rakibin bu round'da kullandığı hamleyi sonraki round için bloke et
      // Eğer zaten bloke edilmemiş ise
      String? opponentMove = state.opponentMove;
      if (opponentMove != null && !state.nextRoundBlockedMoves.contains(opponentMove)) {
        // Bu işlem rakip için yapılıyor, bu yüzden nextRoundBlockedMoves etkilenmez
      }
    }
    
    // Rakip kanca jokeri kullandıysa
    if (opponentJoker == JokerType.blind && state.selectedMove != null) {
      // Oyuncunun bu round'da kullandığı hamleyi sonraki round için bloke et
      String? selectedMove = state.selectedMove;
      if (selectedMove != null && !nextRoundBlockedMoves.contains(selectedMove)) {
        nextRoundBlockedMoves.add(selectedMove);
      }
    }
    
    // Kullanılan jokerleri kaydet
    Set<JokerType> newUsedJokers = Set.from(state.usedJokers);
    if (playerJoker != null && playerJoker != JokerType.none) {
      newUsedJokers.add(playerJoker);
    }
    
    if (opponentJoker != null && opponentJoker != JokerType.none && isAIMode) {
      newUsedJokers.add(opponentJoker);
    }
    
    // Yeni state'i döndür
    return state.copyWith(
      betMultiplier: updatedBetMultiplier,
      nextRoundBlockedMoves: nextRoundBlockedMoves,
      usedJokers: newUsedJokers
    );
  }
  
  /// Çevrimiçi mod için server verilerinden bloklanmış hamleleri hesaplayan metod
  List<String> calculateBlockedMovesFromServerData(
    Map<String, dynamic> data, 
    bool isGreenTeam
  ) {
    final blockedMovesData = data['blockedMoves'];
    if (blockedMovesData == null) return [];
    
    if (isGreenTeam) {
      return List<String>.from(blockedMovesData['player1'] ?? []);
    } else {
      return List<String>.from(blockedMovesData['player2'] ?? []);
    }
  }
  
  /// Çevrimiçi mod için joker tiplerini belirle
  Map<String, JokerType?> extractJokersFromServerData(
    Map<String, dynamic> data,
    bool isGreenTeam
  ) {
    final jokersData = data['jokers'];
    if (jokersData == null) {
      return {'playerJoker': null, 'opponentJoker': null};
    }
    
    final playerJokerStr = isGreenTeam ? jokersData['player1'] : jokersData['player2'];
    final opponentJokerStr = isGreenTeam ? jokersData['player2'] : jokersData['player1'];
    
    return {
      'playerJoker': serverJokerTypeToClientType(playerJokerStr),
      'opponentJoker': serverJokerTypeToClientType(opponentJokerStr)
    };
  }
}