// lib/features/game/services/game_socket_handler.dart

import 'package:flutter/material.dart';
import 'package:handclash/features/game/game_enums.dart';
import 'package:handclash/shared/services/socket_service.dart';

class GameSocketHandler {
  final SocketService _socketService = SocketService();
  final ValueNotifier<GameMatchState> matchState;
  final Function(Map<String, dynamic>) onGameMatched;
  final Function(Map<String, dynamic>) onPreparationPhase;
  final Function(Map<String, dynamic>) onCardSelectPhase;
  final Function(Map<String, dynamic>) onRevealingPhase;
  final Function(Map<String, dynamic>) onRoundResultPhase;
  final Function(Map<String, dynamic>) onJokerSelectPhase;
  final Function(Map<String, dynamic>) onJokerRevealPhase;
  final Function(Map<String, dynamic>) onRoundEndPhase;
  final Function(Map<String, dynamic>) onRoundStart;
  final Function(Map<String, dynamic>) onJokerPhase;
  final Function(Map<String, dynamic>) onJokerUsed;
  final Function(Map<String, dynamic>) onRoundResult;
  final Function(Map<String, dynamic>) onFinalRoundResult;
  final Function(Map<String, dynamic>) onGameEnd;
  final Function(Map<String, dynamic>) onError;
  final Function(Map<String, dynamic>)? onGameSurrendered;
  final Function(Map<String, dynamic>)? onJokerPhaseSkipped; // Yeni: Joker fazı atlandığında çağrılacak
  
  String? get currentGameId => _socketService.currentGameId;
  bool get hasActiveGame => _socketService.hasActiveGame;

  GameSocketHandler({
    required this.matchState,
    required this.onGameMatched,
    required this.onPreparationPhase,
    required this.onCardSelectPhase,
    required this.onRevealingPhase,
    required this.onRoundResultPhase,
    required this.onJokerSelectPhase,
    required this.onJokerRevealPhase,
    required this.onRoundEndPhase,
    required this.onRoundStart,
    required this.onJokerPhase,
    required this.onJokerUsed,
    required this.onRoundResult,
    required this.onFinalRoundResult,
    required this.onGameEnd,
    required this.onError,
    this.onGameSurrendered,
    this.onJokerPhaseSkipped, // Yeni: Joker fazı atlandığında bildirim
  });

  void setupSocketListeners() {
    _socketService.addGameListener(
      onGameMatched: onGameMatched,
      onPreparationPhase: onPreparationPhase,
      onCardSelectPhase: onCardSelectPhase,
      onRevealingPhase: onRevealingPhase,
      onRoundResultPhase: onRoundResultPhase,
      onJokerSelectPhase: (data) {
        // Joker kullanım hakkını kontrol et
        final hasJokers = data['hasJokers'];
        
        // Joker kullanım hakkı bilgisini debug et
        if (hasJokers != null) {
          print('Joker hakları - Player1: ${hasJokers['player1']}, Player2: ${hasJokers['player2']}');
        }
        
        // Orijinal callback'i çağır
        onJokerSelectPhase(data);
      },
      onJokerRevealPhase: (data) {
        // jokerUsageStatus verisini kontrol et ve ekle
        // Bu veri server tarafında eklendi ve şu değerleri alabilir:
        // "none": Hiçbir takım joker kullanmadı
        // "green": Sadece yeşil takım (player1) joker kullandı
        // "red": Sadece kırmızı takım (player2) joker kullandı
        // "both": Her iki takım da joker kullandı
        
        // Veri yoksa varsayılan olarak 'none' kullan
        final jokerUsageStatus = data['jokerUsageStatus'] as String? ?? 'none';
        
        // Veriyi data objesine ekle
        final Map<String, dynamic> extendedData = Map<String, dynamic>.from(data);
        extendedData['jokerUsageStatus'] = jokerUsageStatus;
        
        // Debug log
        print('Joker kullanım durumu: $jokerUsageStatus');
        
        // Güncellenmiş veriyi callback fonksiyonuna gönder
        onJokerRevealPhase(extendedData);
      },
      onRoundEndPhase: onRoundEndPhase,
      onRoundStart: onRoundStart,
      onJokerPhase: onJokerPhase,
      onJokerUsed: onJokerUsed,
      onRoundResult: onRoundResult,
      onFinalRoundResult: onFinalRoundResult,
      onGameEnd: onGameEnd,
      onError: onError,
      onGameSurrendered: onGameSurrendered,
      // Yeni: Joker fazı atlama mesajını dinle
      onJokerPhaseSkipped: (data) {
        print('Joker fazı atlandı: ${data['message']}');
        
        // Callback varsa çağır
        if (onJokerPhaseSkipped != null) {
          onJokerPhaseSkipped!(data);
        }
      },
    );
  }

  void addReadyListener(Function(Map<String, dynamic>) onAllReady) {
    _socketService.addReadyListener(onAllReady);
  }

  void startGame(int betAmount, int targetScore) {
    _socketService.findGame(betAmount, targetScore);
  }

  void makeMove(String move) {
    _socketService.makeMove(move);
  }

  void useJoker(String jokerType) {
    _socketService.useJoker(jokerType);
  }

  void markReady(String gameId) {
    _socketService.markReady(gameId);
  }

  void dispose() {
    _socketService.removeGameListeners();
  }
  
  // Genel socket emit metodu
  void emit(String event, Map<String, dynamic> data) {
    _socketService.emit(event, data);
  }
}