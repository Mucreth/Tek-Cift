// lib/core/constants/app_constants.dart
class AppConstants {
  // Route Names
  static const String splashRoute = '/splash';
  static const String homeRoute = '/home';
  static const String gameRoute = '/game';
  static const String profileRoute = '/profile';
  static const String storeRoute = '/store';
  static const String leagueRoute = '/lig';


  // API Endpoints
  static const String baseUrl = 'https://api.handclash.com';
  static const String wsUrl = 'wss://ws.handclash.com';

  // Game Settings
  static const int roundTime = 5; // saniye
  static const int jokerTime = 10; // saniye
  static const int reconnectTime = 30; // saniye

    // lib/core/constants/app_constants.dart
  static const Map<String, Map<String, dynamic>> leagueLimits = {
    'BRONZE': {
      'min_bet': 100,       // Minimum bahis
      'max_bet': 500,       // Maksimum bahis
      'next_league_min': 2500,  // SILVER'a geçmek için min. gold
      'ai_bet': 100        // AI ile oynarken min bahis
    },
    'SILVER': {
      'min_bet': 500,
      'max_bet': 2000,
      'next_league_min': 10000,  // GOLD'a geçmek için min. gold
      'ai_bet': 500
    },
    'GOLD': {
      'min_bet': 2000,
      'max_bet': 5000,
      'next_league_min': 25000,  // PLATINUM'a geçmek için min. gold
      'ai_bet': 2000
    },
    'PLATINUM': {
      'min_bet': 5000,
      'max_bet': 15000,
      'next_league_min': 75000,
      'ai_bet': 5000
    },
    'DIAMOND': {
      'min_bet': 15000,
      'max_bet': 50000,
      'next_league_min': 250000,
      'ai_bet': 15000
    },
    'MASTER': {
      'min_bet': 50000,
      'max_bet': 150000,
      'next_league_min': 750000,
      'ai_bet': 50000
    },
    'GRANDMASTER': {
      'min_bet': 150000,
      'max_bet': 500000,
      'next_league_min': 2500000,
      'ai_bet': 150000
    },
    'LEGEND': {
      'min_bet': 500000,
      'max_bet': 2000000,
      'next_league_min': 10000000,
      'ai_bet': 500000
    }
  };

  // Tüm ligler (en düşükten en yükseğe)
  static const List<String> allLeagues = [
    'BRONZE', 'SILVER', 'GOLD', 'PLATINUM', 'DIAMOND', 'MASTER', 'GRANDMASTER', 'LEGEND'
  ];

  // Varsayılan lig
  static const String defaultLeague = 'BRONZE';
}

// lib/core/constants/enums.dart
enum GameType {
  rockPaperScissors,
  oddEven
}

enum LeagueType {
  bronze,
  silver,
  gold,
  platinum,
  diamond,
  master,
  grandmaster,
  legend
}

