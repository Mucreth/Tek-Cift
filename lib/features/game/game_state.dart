// lib/features/game/models/game_state.dart
import 'package:handclash/features/game/game_enums.dart';

class GameState {
  // Hazırlık Durumu
  final bool isPlayerReady;
  final bool isOpponentReady;
  final int preparationTimeLeft;
  
  // Oyun Durumu
  final GamePhase currentPhase;
  final bool isRoundActive;
  final int currentRound;
  final int targetScore;
  final bool isGreenTeam;
  
  // Skor
  final int playerScore;
  final int opponentScore;
  
  // Hamle
  final String? selectedMove;
  final String? opponentMove;
  final List<String> blockedMoves;
  final List<String> nextRoundBlockedMoves; // Yeni: Sonraki tur için bloke edilen hamleler
  final bool isBlindPhase;
  
  // Joker Sistemi
  final Map<JokerType, int> availableJokers; // Yeni: Her jokerin kaç adet olduğu
  final JokerType? selectedJoker;
  final JokerType? opponentJoker;
  final Set<JokerType> usedJokers;
  final String jokerUsageStatus; // Yeni: Joker kullanım durumu (none, green, red, both)
  
  // Bahis ve Ödül
  final int betAmount;           // Yeni: Bahis miktarı
  final double betMultiplier;    // Yeni: Bahis çarpanı
  final int? goldWon;
  final int? goldLost;

  final String? opponentName;
    final String? lastSelectedMove;

  GameState({
    // Hazırlık varsayılanları
    this.isPlayerReady = false,
    this.isOpponentReady = false,
    this.preparationTimeLeft = 10,
    
    // Oyun varsayılanları
    this.currentPhase = GamePhase.preparation,
    this.isRoundActive = false,
    this.currentRound = 1,
    this.targetScore = 3,
    this.isGreenTeam = true,
    
    // Skor varsayılanları
    this.playerScore = 0,
    this.opponentScore = 0,
    
    // Hamle varsayılanları
    this.selectedMove,
    this.opponentMove,
    this.blockedMoves = const [],
    this.nextRoundBlockedMoves = const [], // Yeni
    this.isBlindPhase = false,
    
    // Joker varsayılanları
    this.availableJokers = const {
      JokerType.block: 1,
      JokerType.blind: 1,
      JokerType.bet: 1,
    },
    this.selectedJoker,
    this.opponentJoker,
    this.usedJokers = const {},
    this.jokerUsageStatus = 'none', // Yeni: Varsayılan olarak 'none'
    
    // Bahis varsayılanları
    this.betAmount = 1000,
    this.betMultiplier = 1.0,
    this.goldWon,
    this.goldLost,

    this.opponentName,
        this.lastSelectedMove,
  });

  GameState copyWith({
    // Hazırlık
    bool? isPlayerReady,
    bool? isOpponentReady,
    int? preparationTimeLeft,
    
    // Oyun
    GamePhase? currentPhase,
    bool? isRoundActive,
    int? currentRound,
    int? targetScore,
    bool? isGreenTeam,
    
    // Skor
    int? playerScore,
    int? opponentScore,
    
    // Hamle
    String? selectedMove,
    String? opponentMove,
    List<String>? blockedMoves,
    List<String>? nextRoundBlockedMoves, // Yeni
    bool? isBlindPhase,
    
    // Joker
    Map<JokerType, int>? availableJokers, // Yeni
    JokerType? selectedJoker,
    JokerType? opponentJoker,
    Set<JokerType>? usedJokers,
    String? jokerUsageStatus, // Yeni: Joker kullanım durumu
    
    // Bahis ve Ödül
    int? betAmount,
    double? betMultiplier,
    int? goldWon,
    int? goldLost,

    String? opponentName,
      String? lastSelectedMove,
  }) {
    return GameState(
      // Hazırlık
      isPlayerReady: isPlayerReady ?? this.isPlayerReady,
      isOpponentReady: isOpponentReady ?? this.isOpponentReady,
      preparationTimeLeft: preparationTimeLeft ?? this.preparationTimeLeft,
      
      // Oyun
      currentPhase: currentPhase ?? this.currentPhase,
      isRoundActive: isRoundActive ?? this.isRoundActive,
      currentRound: currentRound ?? this.currentRound,
      targetScore: targetScore ?? this.targetScore,
      isGreenTeam: isGreenTeam ?? this.isGreenTeam,
      
      // Skor
      playerScore: playerScore ?? this.playerScore,
      opponentScore: opponentScore ?? this.opponentScore,
      
      // Hamle
      selectedMove: selectedMove ?? this.selectedMove,
      opponentMove: opponentMove ?? this.opponentMove,
      blockedMoves: blockedMoves ?? this.blockedMoves,
      nextRoundBlockedMoves: nextRoundBlockedMoves ?? this.nextRoundBlockedMoves,
      isBlindPhase: isBlindPhase ?? this.isBlindPhase,
      
      // Joker
      availableJokers: availableJokers ?? this.availableJokers,
      selectedJoker: selectedJoker ?? this.selectedJoker,
      opponentJoker: opponentJoker ?? this.opponentJoker,
      usedJokers: usedJokers ?? this.usedJokers,
      jokerUsageStatus: jokerUsageStatus ?? this.jokerUsageStatus, // Yeni
      
      // Bahis ve Ödül
      betAmount: betAmount ?? this.betAmount,
      betMultiplier: betMultiplier ?? this.betMultiplier,
      goldWon: goldWon ?? this.goldWon,
      goldLost: goldLost ?? this.goldLost,

      opponentName: opponentName ?? this.opponentName,
       lastSelectedMove: lastSelectedMove ?? this.lastSelectedMove,
    );
  }

  // Yardımcı metodlar
  bool get isEveryoneReady => isPlayerReady && isOpponentReady;
  bool get isGameOver => playerScore >= targetScore || opponentScore >= targetScore;
  bool get canUseJoker => getAvailableJokerCount() > 0;
  bool get isPreparationPhase => currentPhase == GamePhase.preparation;
  bool get isPlayingPhase => currentPhase == GamePhase.playing || currentPhase == GamePhase.cardSelect;
  bool get isJokerPhase => currentPhase == GamePhase.jokerSelect;
  
  // Joker sayısını alma metodu
  int getAvailableJokerCount() {
    return availableJokers.values.fold(0, (sum, count) => sum + count);
  }
  
  // Belirli bir jokerin sayısını alma
  int getJokerCount(JokerType type) {
    return availableJokers[type] ?? 0;
  }
  
  // Joker kullanım durumu metotları
  bool get didGreenTeamUseJoker => jokerUsageStatus == 'green' || jokerUsageStatus == 'both';
  bool get didRedTeamUseJoker => jokerUsageStatus == 'red' || jokerUsageStatus == 'both';
  bool get didBothTeamsUseJoker => jokerUsageStatus == 'both';
  bool get didNoTeamUseJoker => jokerUsageStatus == 'none';
  
  // Oyuncunun takımına göre joker kullanım durumunu alma
  bool get didPlayerUseJoker => isGreenTeam ? didGreenTeamUseJoker : didRedTeamUseJoker;
  bool get didOpponentUseJoker => isGreenTeam ? didRedTeamUseJoker : didGreenTeamUseJoker;
  
  String? get winner {
    if (!isGameOver) return null;
    if (playerScore > opponentScore) return 'player';
    if (opponentScore > playerScore) return 'opponent';
    return 'draw';
  }
}