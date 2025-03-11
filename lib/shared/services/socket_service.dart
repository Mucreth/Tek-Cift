// lib/shared/services/socket_service.dart
import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;
  String? _currentGameId;

  bool get isConnected => _isConnected;
  String? get currentGameId => _currentGameId;

  void initSocket() {
    if (_socket != null) {
      _socket?.disconnect();
      _socket = null;
    }

    _socket = IO.io('http://51.20.120.189:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'reconnection': true,
      'reconnectionDelay': 1000,
      'reconnectionAttempts': 5,
    });

    _setupSocketListeners();
    _socket?.connect();
  }

  Future<bool> connectAndAuthenticate(String userId, String deviceId) async {
    try {
      if (_socket == null || !_isConnected) {
        initSocket();
        // Bağlantı kurulana kadar bekle
        await Future.delayed(const Duration(seconds: 2));
      }
      

      if (_socket == null || !_isConnected) {
        print('Socket bağlantısı kurulamadı');
        return false;
      }

      final authResult = await authenticate(userId, deviceId);
      return authResult;
    } catch (e) {
      print('Bağlantı hatası: $e');
      return false;
    }
  }

  Future<bool> authenticate(String userId, String deviceId) async {
    if (_socket == null) {
      print('Socket instance yok');
      return false;
    }

    final completer = Completer<bool>();
    var isCompleted = false;

    void successListener(dynamic _) {
      if (!isCompleted) {
        isCompleted = true;
        print('Auth başarılı');
        completer.complete(true);
      }
    }

    void failedListener(dynamic data) {
      if (!isCompleted) {
        isCompleted = true;
        print('Auth başarısız: ${data['message']}');
        completer.complete(false);
      }
    }

    void timeoutHandler() {
      if (!isCompleted) {
        isCompleted = true;
        print('Auth timeout');
        completer.complete(false);
      }
    }

    // Event dinleyicilerini ekle
    _socket?.on('auth:success', successListener);
    _socket?.on('auth:failed', failedListener);

    // Auth isteğini gönder
    _socket?.emit('auth', {
      'userId': userId,
      'deviceId': deviceId,
    });

    // Timeout ayarla
    Timer(const Duration(seconds: 5), timeoutHandler);

    try {
      final result = await completer.future;
      
      // Event dinleyicilerini temizle
      _socket?.off('auth:success', successListener);
      _socket?.off('auth:failed', failedListener);
      
      return result;
    } catch (e) {
      print('Auth error: $e');
      return false;
    }
  }


  // Ready event'i
  void markReady(String? gameId) {
    print('Attempting to mark ready for game: $gameId');

    if (!_isConnected || _socket == null) {
      print('Cannot mark ready: Socket not connected');
      return;
    }

    if (gameId == null) {
      print('Cannot mark ready: No game ID provided');
      return;
    }

    print('Sending game:ready event');
    _socket?.emit('game:ready', {'gameId': gameId});
  }

  // Oyun eşleşmesi
  void findGame(int betAmount, int targetWins) {
    print('Finding game with bet: $betAmount, target: $targetWins');
    
    // Waiting dinleyicisi ekle
    _socket?.on('matchmaking:waiting', (_) {
      print('Added to matchmaking queue');
    });

    emit('matchmaking:find', {
      'betAmount': betAmount,
      'targetWins': targetWins
    });
  }

  // Hamle yap
void makeMove(String move) {
  if (_currentGameId == null) {
    print('makeMove çağrıldı ama aktif oyun yok!');
    return;
  }
  
  print('Socket üzerinden hamle gönderiliyor: $_currentGameId - $move');
  emit('game:move', {'gameId': _currentGameId, 'move': move});
}

// Emit metodunu güncelleme
void emit(String event, Map<String, dynamic> data) {
  if (!_isConnected || _socket == null) {
    print('Socket bağlantısı yok - emit yapılamadı: $event');
    return;
  }
  print('Socket emit: $event - $data');
  _socket?.emit(event, data);
}

  // Joker kullan
  void useJoker(String jokerType) {
    if (_currentGameId == null) return;
    emit('game:joker', {'gameId': _currentGameId, 'jokerType': jokerType});
  }

  void _setupSocketListeners() {
    _socket?.onConnect((_) {
      print('Socket bağlantısı kuruldu');
      _isConnected = true;
    });

    _socket?.onDisconnect((_) {
      print('Socket bağlantısı kesildi');
      _isConnected = false;
      _currentGameId = null;
    });

    _socket?.onConnectError((error) {
      print('Socket bağlantı hatası: $error');
      _isConnected = false;
    });

    _socket?.onError((error) {
      print('Socket hatası: $error');
    });
  }

  // Oyundan çıkış (teslim ol)
void surrender(String gameId) {
  if (_currentGameId == null || _currentGameId != gameId) {
    print('Aktif oyun yok veya ID eşleşmiyor - surrender yapılamadı');
    return;
  }
  
  emit('game:surrender', {'gameId': gameId});
  print('Surrender signal sent for game: $gameId');
}

void cancelMatchmaking(String? gameId) {
  if (!_isConnected || _socket == null) {
    print('Socket bağlantısı yok - cancelMatchmaking yapılamadı');
    return;
  }
  
  emit('matchmaking:cancel', {
    'gameId': gameId
  });
  
  print('Matchmaking cancelled');
}

  // Oyun dinleyicisi ekle
    void addGameListener({
    Function(Map<String, dynamic>)? onGameMatched,
    Function(Map<String, dynamic>)? onRoundStart,
    Function(Map<String, dynamic>)? onJokerPhase,
    Function(Map<String, dynamic>)? onJokerUsed,
    Function(Map<String, dynamic>)? onRoundResult,
    Function(Map<String, dynamic>)? onFinalRoundResult,
    Function(Map<String, dynamic>)? onGameEnd,
    Function(Map<String, dynamic>)? onError,
    // Yeni event'ler için dinleyiciler
    Function(Map<String, dynamic>)? onPreparationPhase,
    Function(Map<String, dynamic>)? onCardSelectPhase,
    Function(Map<String, dynamic>)? onRevealingPhase,
    Function(Map<String, dynamic>)? onRoundResultPhase,
    Function(Map<String, dynamic>)? onJokerSelectPhase,
    Function(Map<String, dynamic>)? onJokerRevealPhase,
    Function(Map<String, dynamic>)? onRoundEndPhase,
    Function(Map<String, dynamic>)? onGameSurrendered,
    Function(Map<String, dynamic>)? onJokerPhaseSkipped, // Yeni: Joker fazı atlama
  }) {
    // game:matched event'i için özel dinleyici
    _socket?.on('game:matched', (data) {
      print('Received game:matched with data: $data');
      _currentGameId = data['gameId'];
      print('Set current game ID to: $_currentGameId');

      final Map<String, dynamic> gameData =
          data is Map ? Map<String, dynamic>.from(data) : {'gameId': data.toString()};

      onGameMatched?.call(gameData);
    });

    // Yeni oyun akışı event'leri
    _socket?.on('game:preparationPhase', (data) => 
      onPreparationPhase?.call(Map<String, dynamic>.from(data)));
    
    _socket?.on('game:cardSelectPhase', (data) => 
      onCardSelectPhase?.call(Map<String, dynamic>.from(data)));
    
    _socket?.on('game:revealingPhase', (data) => 
      onRevealingPhase?.call(Map<String, dynamic>.from(data)));
    
    _socket?.on('game:roundResultPhase', (data) {
      print('Round result phase event received: $data');
      if (onRoundResultPhase != null) {
        onRoundResultPhase(Map<String, dynamic>.from(data));
      }
    });
    
    _socket?.on('game:jokerSelectPhase', (data) => 
      onJokerSelectPhase?.call(Map<String, dynamic>.from(data)));
    
    _socket?.on('game:jokerRevealPhase', (data) => 
      onJokerRevealPhase?.call(Map<String, dynamic>.from(data)));
    
    _socket?.on('game:roundEndPhase', (data) => 
      onRoundEndPhase?.call(Map<String, dynamic>.from(data)));
      
    // Yeni: Joker fazı atlama event'i
    _socket?.on('game:jokerPhaseSkipped', (data) {
      print('Joker phase skipped event received: $data');
      if (onJokerPhaseSkipped != null) {
        onJokerPhaseSkipped(Map<String, dynamic>.from(data));
      }
    });

    // Eski/mevcut event'ler, ama bunları yeni akış içinde kullanacağız
    _socket?.on('round:start', (data) => 
      onRoundStart?.call(Map<String, dynamic>.from(data)));
    
    _socket?.on('round:jokerPhase', (data) => 
      onJokerPhase?.call(Map<String, dynamic>.from(data)));
    
    _socket?.on('game:jokerUsed', (data) => 
      onJokerUsed?.call(Map<String, dynamic>.from(data)));
    
    _socket?.on('round:result', (data) {
      print('Round result event received: $data');
      if (onRoundResult != null) {
        onRoundResult(Map<String, dynamic>.from(data));
      }
    });

    _socket?.on('round:finalResult', (data) {
      print('Final round result event received: $data');
      if (onFinalRoundResult != null) {
        onFinalRoundResult(Map<String, dynamic>.from(data));
      }
    });

    _socket?.on('game:end', (data) {
      _currentGameId = null;
      onGameEnd?.call(Map<String, dynamic>.from(data));
    });

    _socket?.on('error', (data) => 
      onError?.call(Map<String, dynamic>.from(data)));
      
    // Oyuncudan ayrılma durumu
    _socket?.on('game:disconnected', (data) {
      print('Player disconnected: $data');
      // Bu event'i de kullanabiliriz, şimdilik sadece log
    });

    _socket?.on('game:surrendered', (data) {
      print('Received surrender event: $data');
      if (onGameSurrendered != null) {
        onGameSurrendered(Map<String, dynamic>.from(data));
      }
      // Teslim olma aynı zamanda oyunun bitişi anlamına gelir
      if (onGameEnd != null) {
        final String winnerId = data['winner'];
        final String surrenderedPlayer = data['surrenderedPlayer'];
        onGameEnd({
          'winner': winnerId,
          'surrenderedPlayer': surrenderedPlayer,
          'stats': {'player1Wins': 0, 'player2Wins': 0, 'draws': 0},
          'totalRounds': 0
        });
      }
    });
  }
  void addReadyListener(Function(Map<String, dynamic>) onAllReady) {
  // Önceki dinleyicileri temizle
  _socket?.off('game:allReady');
  _socket?.off('game:playerReady');
  
  // Sadece allReady olayını dinle
  _socket?.on('game:allReady', (data) {
    print('Received all ready event');
    onAllReady(data is Map ? Map<String, dynamic>.from(data) : {});
  });
  
  // PlayerReady olayını sadece log için dinle
  _socket?.on('game:playerReady', (data) {
    print('Received player ready event: $data');
    // Burada onAllReady çağrılmamalı!
  });
}

  // Dinleyicileri kaldır
  void removeGameListeners() {
    _socket?.off('game:matched');
    
    // Yeni event dinleyicileri kaldır
    _socket?.off('game:preparationPhase');
    _socket?.off('game:cardSelectPhase');
    _socket?.off('game:revealingPhase');
    _socket?.off('game:roundResultPhase');
    _socket?.off('game:jokerSelectPhase');
    _socket?.off('game:jokerRevealPhase');
    _socket?.off('game:roundEndPhase');
    _socket?.off('game:surrendered');
    _socket?.off('game:jokerPhaseSkipped'); // Yeni: Joker fazı atlama
    
    // Eski event dinleyicileri kaldır
    _socket?.off('round:start');
    _socket?.off('round:jokerPhase');
    _socket?.off('game:jokerUsed');
    _socket?.off('round:result');
    _socket?.off('round:finalResult');
    _socket?.off('game:end');
    _socket?.off('error');
    _socket?.off('game:allReady');
    _socket?.off('game:disconnected');
  }

  // Geçerli oyun ID'sini kontrol etmek için yardımcı metod
  bool get hasActiveGame => _currentGameId != null;

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
    _isConnected = false;
    _currentGameId = null;
  }
}