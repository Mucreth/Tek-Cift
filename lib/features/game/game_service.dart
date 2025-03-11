// lib/features/game/services/game_service.dart
import 'package:handclash/features/game/game_enums.dart';

class GameService {
  String? calculateWinner(String? playerMove, String? opponentMove, String gameType) {
    if (playerMove == null || opponentMove == null) return null;
    if (playerMove == 'timeout' || opponentMove == 'timeout') {
      if (playerMove == 'timeout' && opponentMove == 'timeout') return null; // Berabere
      return playerMove == 'timeout' ? 'opponent' : 'player'; // Timeout yapan kaybeder
    }
    
    if (gameType == 'rps') {
      if (playerMove == opponentMove) return null; // Berabere
      
      if ((playerMove == 'rock' && opponentMove == 'scissors') ||
          (playerMove == 'paper' && opponentMove == 'rock') ||
          (playerMove == 'scissors' && opponentMove == 'paper')) {
        return 'player';
      }
      return 'opponent';
    } else {
      // Tek-Çift mantığı
      return playerMove == opponentMove ? 'player' : 'opponent';
    }
  }

  // Server'daki bloke yapısına uygun olarak bloke edilecek hamleleri hesapla
  List<String> calculateBlockedMoves(String gameType, JokerType? playerJoker, JokerType? opponentJoker) {
    // Bloke veya Hook jokeri kullanılmadıysa boş liste dön
    if ((playerJoker != JokerType.block && playerJoker != JokerType.blind) && 
        (opponentJoker != JokerType.block && opponentJoker != JokerType.blind)) {
      return [];
    }

    List<String> allMoves = gameType == 'rps' 
        ? ['rock', 'paper', 'scissors']
        : ['odd', 'even'];
    
    // Bloke jokeri için rastgele 2 (RPS) veya 1 (Tek-Çift) hamle seçiyoruz
    if (playerJoker == JokerType.block || opponentJoker == JokerType.block) {
      allMoves.shuffle();
      return allMoves.sublist(0, gameType == 'rps' ? 2 : 1);
    }
    
    // Hook jokeri için boş liste döndür, çünkü gerçek bloke edilecek hamle
    // oyun sırasında seçilen hamle olacak
    return [];
  }
  
  // Joker kullanıcısını doğru formata çevir
  String clientJokerTypeToServerType(JokerType jokerType) {
    switch (jokerType) {
      case JokerType.block:
        return 'block';
      case JokerType.blind:
        return 'hook';  // Client'taki blind, server'da hook
      case JokerType.bet:
        return 'bet';
      default:
        return 'none';
    }
  }
  
  // Server'dan gelen joker tipini client'taki tipe çevir
  JokerType serverJokerTypeToClientType(String serverType) {
    switch (serverType) {
      case 'block':
        return JokerType.block;
      case 'hook':
        return JokerType.blind;  // Server'daki hook, client'ta blind
      case 'bet':
        return JokerType.bet;
      default:
        return JokerType.none;
    }
  }
}