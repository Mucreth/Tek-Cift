// lib/features/game/services/game_move_handler.dart

import 'package:handclash/features/game/game_enums.dart';
import 'package:handclash/features/game/game_service.dart';
import 'package:handclash/features/game/game_state.dart';

class GameMoveHandler {
  final GameService _gameService = GameService();
  final String gameType;
  
  GameMoveHandler({
    required this.gameType,
  });

  String? calculateWinner(String? playerMove, String? opponentMove) {
    return _gameService.calculateWinner(playerMove, opponentMove, gameType);
  }

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

  JokerType? serverJokerTypeToClientType(String? serverType) {
    if (serverType == null) return null;

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

  String getRoundResultText(GameState state) {
    if (state.selectedMove == null) return "Süre Doldu!";

    String? winner = _gameService.calculateWinner(
      state.selectedMove,
      state.opponentMove,
      gameType,
    );

    if (winner == null) return "Berabere!";
    return "${winner == 'player' ? (state.isGreenTeam ? 'Yeşil' : 'Kırmızı') : (state.isGreenTeam ? 'Kırmızı' : 'Yeşil')} Kazandı!";
  }

String getJokerResultText(GameState state) {
  // Joker kullanım durumunu state'ten al
  final String jokerUsageStatus = state.jokerUsageStatus;
  
  // Takım bilgisini al
  final bool isGreenTeam = state.isGreenTeam;
  
  if (state.getAvailableJokerCount() == 0) {
    return "Joker hakkınız bitti!";
  }

  // Joker kullanımını state'teki jokerUsageStatus'a göre kontrol et
  switch (jokerUsageStatus) {
    case 'both':
      return "İki taraf da joker kullandı!";
    case 'green':
      return isGreenTeam 
          ? "Takımınız joker kullandı!" 
          : "Rakip joker kullandı!";
    case 'red':
      return isGreenTeam 
          ? "Rakip joker kullandı!" 
          : "Takımınız joker kullandı!";
    case 'none':
    default:
      return "Bu el joker kullanılmadı";
  }
}
}