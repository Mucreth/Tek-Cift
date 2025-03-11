class UserProfile {
  final String userId;
  final String nickname;
  final String league;
  final int level;
  final int xp;
  final int gold;
  final bool isPremium;
  final UserStatistics? statistics;

  UserProfile({
    required this.userId,
    required this.nickname,
    required this.league,
    this.level = 1,
    this.xp = 0,
    required this.gold,
    this.isPremium = false,
    this.statistics,
  });

  factory UserProfile.fromMap(Map<String, dynamic> userData, Map<String, dynamic>? statsData) {
    return UserProfile(
      userId: userData['user_id'] ?? '',
      nickname: userData['nickname'] ?? 'Kullanıcı',
      league: userData['current_league'] ?? 'bronze',
      level: userData['level'] is int 
          ? userData['level'] 
          : int.tryParse(userData['level']?.toString() ?? '1') ?? 1,
      xp: userData['xp'] is int 
          ? userData['xp']
          : int.tryParse(userData['xp']?.toString() ?? '0') ?? 0,
      gold: userData['current_gold'] is int 
          ? userData['current_gold']
          : int.tryParse(userData['current_gold']?.toString() ?? '0') ?? 0,
      isPremium: userData['is_premium'] == 1 || userData['is_premium'] == true,
      statistics: statsData != null ? UserStatistics.fromMap(statsData) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'nickname': nickname,
      'current_league': league,
      'level': level,
      'xp': xp,
      'current_gold': gold,
      'is_premium': isPremium,
    };
  }
}

class UserStatistics {
  final int totalGames;
  final int totalWins;
  final int totalLosses;
  final int totalDraws;
  final double winRate;
  final List<MatchRecord> recentMatches;

  UserStatistics({
    this.totalGames = 0,
    this.totalWins = 0,
    this.totalLosses = 0,
    this.totalDraws = 0,
    this.winRate = 0.0,
    this.recentMatches = const [],
  });

  factory UserStatistics.fromMap(Map<String, dynamic> map) {
    final List<MatchRecord> matches = [];
    
    if (map['recent_matches'] != null && map['recent_matches'] is List) {
      for (var match in map['recent_matches']) {
        matches.add(MatchRecord.fromMap(match));
      }
    }

    return UserStatistics(
      totalGames: map['total_games'] is int 
          ? map['total_games']
          : int.tryParse(map['total_games']?.toString() ?? '0') ?? 0,
      totalWins: map['total_wins'] is int 
          ? map['total_wins'] 
          : int.tryParse(map['total_wins']?.toString() ?? '0') ?? 0,
      totalLosses: map['total_losses'] is int 
          ? map['total_losses']
          : int.tryParse(map['total_losses']?.toString() ?? '0') ?? 0,
      totalDraws: map['total_draws'] is int 
          ? map['total_draws']
          : int.tryParse(map['total_draws']?.toString() ?? '0') ?? 0,
      winRate: map['win_rate'] is double 
          ? map['win_rate']
          : double.tryParse(map['win_rate']?.toString() ?? '0.0') ?? 0.0,
      recentMatches: matches,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'total_games': totalGames,
      'total_wins': totalWins,
      'total_losses': totalLosses,
      'total_draws': totalDraws,
      'win_rate': winRate,
    };
  }
}

class MatchRecord {
  final String gameId;
  final String opponentId;
  final String opponentNickname;
  final String winner;
  final int betAmount;
  final DateTime startedAt;
  final DateTime endedAt;

  MatchRecord({
    required this.gameId,
    required this.opponentId,
    required this.opponentNickname,
    required this.winner,
    required this.betAmount,
    required this.startedAt,
    required this.endedAt,
  });

  factory MatchRecord.fromMap(Map<String, dynamic> map) {
    return MatchRecord(
      gameId: map['game_id'] ?? '',
      opponentId: map['opponent_id'] ?? '',
      opponentNickname: map['opponent_nickname'] ?? 'Rakip',
      winner: map['winner'] ?? '',
      betAmount: map['bet_amount'] is int 
          ? map['bet_amount'] 
          : int.tryParse(map['bet_amount']?.toString() ?? '0') ?? 0,
      startedAt: map['started_at'] != null 
          ? DateTime.tryParse(map['started_at']) ?? DateTime.now()
          : DateTime.now(),
      endedAt: map['ended_at'] != null 
          ? DateTime.tryParse(map['ended_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'game_id': gameId,
      'opponent_id': opponentId,
      'opponent_nickname': opponentNickname,
      'winner': winner,
      'bet_amount': betAmount,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt.toIso8601String(),
    };
  }
}