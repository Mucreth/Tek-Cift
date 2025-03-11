// lib/features/game/logic/online_game_logic.dart

import 'package:flutter/material.dart';
import 'package:handclash/features/game/game_enums.dart';
import 'package:handclash/features/game/game_state.dart';
import 'package:handclash/features/game/services/game_joker_handler.dart';
import 'package:handclash/features/game/services/game_feedback_service.dart';
import 'package:handclash/features/game/services/game_socket_handler.dart';

/// Çevrimiçi oyun mantığını yöneten sınıf.
/// Çevrimiçi modda oyuncu eşleşmesi, hamle iletişimi ve oyun olaylarını yönetir.
class OnlineGameLogic {
  final GameSocketHandler _socketHandler;
  final GameJokerHandler _jokerHandler;
  final GameFeedbackService _feedbackService;
  final String gameType;
  final int targetScore;
  final int betAmount;
  
  final ValueNotifier<GameMatchState> matchState;
  final Function(Map<String, dynamic>)? onOpponentFound;
  final Function(Map<String, dynamic>)? onGameEnd;
  
  OnlineGameLogic({
    required this.gameType,
    required this.targetScore,
    required this.betAmount,
    required GameSocketHandler socketHandler,
    required GameJokerHandler jokerHandler,
    required GameFeedbackService feedbackService,
    required this.matchState,
    this.onOpponentFound,
    this.onGameEnd,
  }) : _socketHandler = socketHandler,
       _jokerHandler = jokerHandler,
       _feedbackService = feedbackService;
  
  /// Socket ID'sini döndürür
  String? get currentGameId => _socketHandler.currentGameId;
  
  /// Aktif bir oyun olup olmadığını kontrol eder
  bool get hasActiveGame => _socketHandler.hasActiveGame;
  
  /// Çevrimiçi oyunu başlat
  void startGame() {
    print('Çevrimiçi oyun başlatılıyor...');
    _setupSocketListeners();
    _socketHandler.startGame(betAmount, targetScore);
  }
  
  /// Socket dinleyicilerini kur
  void _setupSocketListeners() {
    _socketHandler.setupSocketListeners();
    
    // Herkes hazır olduğunda
    _socketHandler.addReadyListener((data) {
      print('Herkes hazır oldu: $data');
      
      // Eşleşme durumunu güncelle
      matchState.value = GameMatchState.starting;
      
      // Oyun başlama sesi
      _feedbackService.playGameStartSound();
    });
  }
  
  /// Çevrimiçi rakip bulunduğunda
  void handleGameMatched(GameState state, Map<String, dynamic> data) {
    // Rakip adını al
    final opponentNickname = data['opponentNickname'] ?? 'Rakip';
    
    // Takım rengini belirle
    final isGreenTeam = data['isGreenTeam'] == 1 || data['isGreenTeam'] == true;
    
    // Bahis miktarını al
    final betAmount = data['betAmount'] ?? 1000;
    
    // Titreşim ver
    _feedbackService.vibrateShort();
    
    // Rakip bilgilerini callback ile ilet
    if (onOpponentFound != null) {
      final isPlayer1 = isGreenTeam;
      final opponentId = isPlayer1 ? data['player2Id'] : data['player1Id'];
      
      // Rakip bilgilerini hazırla
      Map<String, dynamic> opponentData = {
        'id': opponentId,
        'nickname': data['opponentNickname'] ?? 'Rakip',
        'win_rate': data['opponentWinRate'] ?? 0,
      };
      
      onOpponentFound!(opponentData);
    }
  }
  
  /// Hamle yap
  void makeMove(String move) {
    _socketHandler.makeMove(move);
  }
  
  /// Joker kullan
  void useJoker(JokerType type) {
    // Server'daki joker tipi adlandırması farklı
    final serverJokerType = _jokerHandler.getJokerServerType(type);
    
    // Jokeri sunucuya gönder
    _socketHandler.useJoker(serverJokerType);
  }
  
  /// Hazır olduğunu bildir
  void markPlayerReady() {
    if (!hasActiveGame) {
      print('Aktif oyun bulunamadı');
      return;
    }
    
    _socketHandler.markReady(currentGameId!);
  }
  
  /// Eşleşmeyi iptal et
  void cancelMatchmaking(BuildContext context) {
    // Sunucuya iptal bilgisini gönder
    if (currentGameId != null) {
      // Eşleşme iptal bildirimi gönder
      _socketHandler.emit('matchmaking:cancel', {
        'gameId': currentGameId
      });
    }
    
    // Ana sayfaya dön
    Navigator.of(context).pushReplacementNamed('/home');
  }
  
  /// Oyun sonu olayını işle
  void handleGameEnd(Map<String, dynamic> data, GameState state) {
    // Oyun sonu bilgisini callback ile ilet
    if (onGameEnd != null) {
      // Teslim olma durumunu kontrol et
      if (data.containsKey('surrenderedPlayer')) {
        _handleSurrenderGameEnd(data, state);
      } else {
        _handleNormalGameEnd(data, state);
      }
    }
  }
  
  /// Normal oyun sonu durumunu işle
  void _handleNormalGameEnd(Map<String, dynamic> data, GameState state) {
    // Kazananı belirle
    final bool isWinner = data['winner'] == (state.isGreenTeam ? 'player1' : 'player2');
    final bool isDraw = data['winner'] == 'draw';
    
    // Kazanç veya kayıp hesapla
    final int betAmount = state.betAmount;
    int goldResult = 0;
    String message = "";
    
    if (isWinner) {
      goldResult = (betAmount * 2);
      message = "Tebrikler! Kazandınız";
      _feedbackService.vibrateMedium();
    } else if (isDraw) {
      goldResult = betAmount;
      message = "Berabere!";
    } else {
      goldResult = 0;
      message = "Maalesef, Kaybettiniz";
      _feedbackService.vibrateLong();
    }
    
    // Sonuç sesi
    _feedbackService.playRoundResultSound(isWin: isWinner);
    
    // Oyun sonu bilgisini callback ile ilet
    if (onGameEnd != null) {
      onGameEnd!({
        'isWinner': isWinner,
        'message': message,
        'goldWon': isWinner ? goldResult : 0
      });
    }
  }
  
  /// Teslim olma durumunda oyun sonu işle
  void _handleSurrenderGameEnd(Map<String, dynamic> data, GameState state) {
    final String currentUserId = data['userId'] ?? '';
    final String surrenderedPlayerId = data['surrenderedPlayer'];
    final String winnerId = data['winner'];
    
    bool isWinner = false;
    String message = "";
    int goldResult = 0;
    
    // Teslim olan oyuncu kontrolü
    if (currentUserId == surrenderedPlayerId) {
      // Oyuncu teslim olmuş
      isWinner = false;
      message = "Oyundan ayrıldınız.";
      goldResult = 0;
    } else if (currentUserId == winnerId) {
      // Rakip teslim olmuş
      isWinner = true;
      message = "Rakip oyundan ayrıldı!";
      goldResult = (state.betAmount * 2);
    } else {
      // ID eşleşmesi sorunu var
      isWinner = false;
      message = "Bilinmeyen sonuç";
      goldResult = 0;
    }
    
    // Sonuç sesi
    _feedbackService.playRoundResultSound(isWin: isWinner);
    
    // Oyun sonu bilgisini callback ile ilet
    if (onGameEnd != null) {
      onGameEnd!({
        'isWinner': isWinner,
        'message': message,
        'goldWon': isWinner ? goldResult : 0
      });
    }
  }
  
  /// Kaynakları temizle
  void dispose() {
    // Socket işlemlerini temizle
    _socketHandler.dispose();
  }
}