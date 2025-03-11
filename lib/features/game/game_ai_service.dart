// lib/features/game/service/game_ai_service.dart
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:handclash/features/game/game_enums.dart';

class GameAIService {
  final Random _random = Random();
  List<String> _playerMoveHistory = [];
  JokerType? _lastPlayerJoker;
  
  // Taş Kağıt Makas için hamleler
  static const List<String> rpsOptions = ['rock', 'paper', 'scissors'];
  
  // Tek Çift için hamleler
  static const List<String> oddEvenOptions = ['odd', 'even'];
  
  // AI joker kullanımı için olasılıklar
  final double _blockJokerChance = 0.3;  // %30 blok jokeri kullanma şansı
  final double _blindJokerChance = 0.25; // %25 kanca jokeri kullanma şansı
  final double _betJokerChance = 0.2;    // %20 bahis jokeri kullanma şansı

  // Hamle geçmişine göre sonraki hamleyi tahmin et
  String predictNextMove(String gameType, List<String> blockedMoves) {
    // Bloke edilmiş hamleler dışındaki seçenekleri al
    List<String> availableMoves = [];
    
    if (gameType == 'rps') {
      availableMoves = rpsOptions.where((move) => !blockedMoves.contains(move)).toList();
    } else {
      availableMoves = oddEvenOptions.where((move) => !blockedMoves.contains(move)).toList();
    }
    
    // Eğer tüm hamleler bloke edilmişse timeout dön
    if (availableMoves.isEmpty) {
      return 'timeout';
    }
    
    if (_playerMoveHistory.isEmpty) {
      // İlk hamle rastgele (ama bloke edilmemiş hamlelerden)
      return availableMoves[_random.nextInt(availableMoves.length)];
    }

    // Son hamlelere bakarak pattern analizi yap
    String predictedMove = '';
    if (gameType == 'rps') {
      predictedMove = _predictRPSMove();
    } else {
      predictedMove = _predictOddEvenMove();
    }
    
    // Eğer tahmin edilen hamle bloke edilmişse, başka bir hamle seç
    if (blockedMoves.contains(predictedMove)) {
      // Rastgele bir kullanılabilir hamle seç
      return availableMoves[_random.nextInt(availableMoves.length)];
    }
    
    return predictedMove;
  }

  String _predictRPSMove() {
    if (_playerMoveHistory.length < 3) {
      return rpsOptions[_random.nextInt(rpsOptions.length)];
    }

    // Son 3 hamleye bak
    var lastThreeMoves = _playerMoveHistory.sublist(_playerMoveHistory.length - 3);
    
    // Eğer oyuncu sürekli aynı hamleyi yapıyorsa
    if (lastThreeMoves.toSet().length == 1) {
      // Oyuncunun hamlesini yenen hamleyi yap
      return _getWinningMove(lastThreeMoves.last);
    }

    // Eğer oyuncu sırayla hamle yapıyorsa (rock->paper->scissors)
    if (_isSequential(lastThreeMoves)) {
      // Sıradaki hamleyi tahmin et ve onu yenen hamleyi yap
      return _getWinningMove(_predictNextInSequence(lastThreeMoves));
    }

    // Pattern bulunamazsa, hafif ağırlıklı rastgele seçim
    return _makeWeightedRandomChoice();
  }

  String _predictOddEvenMove() {
    if (_playerMoveHistory.length < 3) {
      return oddEvenOptions[_random.nextInt(oddEvenOptions.length)];
    }

    // Son 3 hamleye bak
    var lastThreeMoves = _playerMoveHistory.sublist(_playerMoveHistory.length - 3);
    
    // Eğer oyuncu hep aynısını seçiyorsa, tersini seç
    if (lastThreeMoves.toSet().length == 1) {
      return lastThreeMoves.last == 'odd' ? 'even' : 'odd';
    }

    // Alternatif yapıyorsa, patternı boz
    if (_isAlternating(lastThreeMoves)) {
      var nextExpected = lastThreeMoves.last == 'odd' ? 'even' : 'odd';
      return nextExpected == 'odd' ? 'even' : 'odd';
    }

    return oddEvenOptions[_random.nextInt(oddEvenOptions.length)];
  }

  String _getWinningMove(String move) {
    switch (move) {
      case 'rock':
        return 'paper';
      case 'paper':
        return 'scissors';
      case 'scissors':
        return 'rock';
      default:
        return rpsOptions[_random.nextInt(rpsOptions.length)];
    }
  }

  bool _isSequential(List<String> moves) {
    if (moves.length < 3) return false;
    
    var sequence = ['rock', 'paper', 'scissors'];
    for (int i = 0; i < sequence.length - 2; i++) {
      var possibleSequence = sequence.sublist(i) + sequence.sublist(0, i);
      if (listEquals(moves, possibleSequence.sublist(0, 3))) {
        return true;
      }
    }
    return false;
  }

  bool _isAlternating(List<String> moves) {
    if (moves.length < 2) return false;
    return moves[moves.length - 1] != moves[moves.length - 2];
  }

  String _predictNextInSequence(List<String> moves) {
    var sequence = ['rock', 'paper', 'scissors'];
    var lastMove = moves.last;
    var lastIndex = sequence.indexOf(lastMove);
    return sequence[(lastIndex + 1) % sequence.length];
  }

  String _makeWeightedRandomChoice() {
    // Oyuncunun en çok kullandığı hamleyi hesapla
    var moveCounts = {
      'rock': 0,
      'paper': 0,
      'scissors': 0,
    };

    for (var move in _playerMoveHistory) {
      moveCounts[move] = (moveCounts[move] ?? 0) + 1;
    }

    // En çok kullanılan hamleyi bul
    var mostUsedMove = moveCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    // %60 ihtimalle en çok kullanılan hamleyi yenen hamleyi yap
    if (_random.nextDouble() < 0.6) {
      return _getWinningMove(mostUsedMove);
    }

    // %40 ihtimalle rastgele hamle yap
    return rpsOptions[_random.nextInt(rpsOptions.length)];
  }

  // Joker kullanma kararı
  JokerType? decideJoker(
    Map<JokerType, int> availableJokers, 
    Set<JokerType> usedJokers,
    String playerLastMove,
    int currentRound,
    int targetScore
  ) {
    // Joker seçimi için bazı kontroller
    if (availableJokers.isEmpty) return null;
    
    // Kullanılan jokerleri filtrele
    final availableJokerTypes = availableJokers.entries
        .where((entry) => entry.value > 0 && !usedJokers.contains(entry.key))
        .map((entry) => entry.key)
        .toList();
    
    if (availableJokerTypes.isEmpty) return null;
    
    // AI stratejileri
    double randomValue = _random.nextDouble();
    
    // Oyun sonlarına doğru joker kullanma olasılığını artır
    double roundMultiplier = currentRound / targetScore;
    
    // Oyuncunun son jokeri bilgisine göre strateji belirle
    if (_lastPlayerJoker != null) {
      // Oyuncu bir joker kullandıysa, AI de kullanma olasılığını artır
      if (_lastPlayerJoker == JokerType.block && 
          availableJokers[JokerType.blind] != null && 
          availableJokers[JokerType.blind]! > 0 &&
          !usedJokers.contains(JokerType.blind)) {
        // Oyuncu blok kullandıysa, AI kanca kullanma olasılığını artır
        if (randomValue < _blindJokerChance * 1.5) {
          return JokerType.blind;
        }
      } else if (_lastPlayerJoker == JokerType.bet && 
                availableJokers[JokerType.bet] != null && 
                availableJokers[JokerType.bet]! > 0 &&
                !usedJokers.contains(JokerType.bet)) {
        // Oyuncu bahis jokeri kullandıysa, AI de bahis jokeri kullanabilir
        if (randomValue < _betJokerChance * 1.5) {
          return JokerType.bet;
        }
      }
    }
    
    // Genel joker seçim mantığı
    if (randomValue < _blockJokerChance * roundMultiplier && 
        availableJokers[JokerType.block] != null && 
        availableJokers[JokerType.block]! > 0 &&
        !usedJokers.contains(JokerType.block)) {
      return JokerType.block;
    } else if (randomValue < (_blockJokerChance + _blindJokerChance) * roundMultiplier && 
              availableJokers[JokerType.blind] != null && 
              availableJokers[JokerType.blind]! > 0 &&
              !usedJokers.contains(JokerType.blind)) {
      return JokerType.blind;
    } else if (randomValue < (_blockJokerChance + _blindJokerChance + _betJokerChance) * roundMultiplier && 
              availableJokers[JokerType.bet] != null && 
              availableJokers[JokerType.bet]! > 0 &&
              !usedJokers.contains(JokerType.bet)) {
      return JokerType.bet;
    }
    
    // Bazen joker kullanmama kararı da alabilir
    return null;
  }

  // Oyuncunun hamlesini kaydet
  void recordPlayerMove(String move) {
    _playerMoveHistory.add(move);
  }
  
  // Oyuncunın kullandığı jokeri kaydet
  void recordPlayerJoker(JokerType? jokerType) {
    _lastPlayerJoker = jokerType;
  }

  // Oyun geçmişini temizle
  void resetHistory() {
    _playerMoveHistory.clear();
    _lastPlayerJoker = null;
  }
}