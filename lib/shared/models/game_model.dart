import 'package:handclash/core/constants/app_constants.dart';

class GameModel {
  final String id;
  final GameType type;
  final int betAmount;
  final String player1Id;
  final String player2Id;
  final List<RoundModel> rounds;
  
  GameModel({
    required this.id,
    required this.type,
    required this.betAmount,
    required this.player1Id,
    required this.player2Id,
    required this.rounds,
  });
}

class RoundModel {
  final int roundNumber;
  final String? player1Move;
  final String? player2Move;
  final String? winner;

  RoundModel({
    required this.roundNumber,
    this.player1Move,
    this.player2Move,
    this.winner,
  });
}