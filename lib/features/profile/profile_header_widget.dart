import 'package:flutter/material.dart';
import 'dart:ui';

class ProfileHeaderWidget extends StatelessWidget {
  final Map<String, dynamic>? userData;
  final Map<String, dynamic>? statsData;

  const ProfileHeaderWidget({
    super.key,
    required this.userData,
    this.statsData,
  });

  // Güvenli int dönüşümü metodu
  int _parseIntSafely(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? defaultValue;
  }

  // Level için gerekli XP'yi hesapla
  int _calculateRequiredXp(int level) {
    if (level <= 5) {
      return 1000;
    } else if (level <= 10) {
      return 2000;
    } else if (level <= 15) {
      return 4000;
    } else {
      return 8000;
    }
  }

  // Mevcut seviye için mevcut XP'yi hesapla (toplam XP içinden)
  int _calculateCurrentLevelXp(int level, int totalXp) {
    int previousLevelsXp = 0;
    
    // Önceki tüm seviyelerin XP'sini topla
    for (int i = 1; i < level; i++) {
      previousLevelsXp += _calculateRequiredXp(i);
    }
    
    // Mevcut seviye için kalan XP
    return totalXp - previousLevelsXp;
  }

@override
Widget build(BuildContext context) {
  // API'den gelen verileri konsola yazdır
  print("ProfileHeaderWidget - userData: $userData");
  print("ProfileHeaderWidget - statsData: $statsData");
  
  final nickname = userData?['nickname'] ?? 'Kullanıcı';
  final league = userData?['current_league'] ?? 'BRONZE';
  
  // Level ve XP değerlerini önce statsData'dan, yoksa userData'dan al
  final level = _parseIntSafely(statsData?['level'] ?? userData?['level'], defaultValue: 1);
  final xp = _parseIntSafely(statsData?['xp'] ?? userData?['xp'], defaultValue: 0);
  
  final gold = _parseIntSafely(userData?['current_gold'], defaultValue: 0);
  
  // XP ve Level bilgilerini özel olarak kontrol et
  print("ProfileHeaderWidget - nickname: $nickname");
  print("ProfileHeaderWidget - league: $league");
  print("ProfileHeaderWidget - level: $level (orijinal değer: ${statsData?['level'] ?? userData?['level']})");
  print("ProfileHeaderWidget - xp: $xp (orijinal değer: ${statsData?['xp'] ?? userData?['xp']})");
  print("ProfileHeaderWidget - gold: $gold (orijinal değer: ${userData?['current_gold']})");
  
  // XP hesaplamalarını da kontrol et
  final requiredXp = _calculateRequiredXp(level);
  final currentLevelXp = _calculateCurrentLevelXp(level, xp);
  print("ProfileHeaderWidget - requiredXp: $requiredXp");
  print("ProfileHeaderWidget - currentLevelXp: $currentLevelXp");
  
  // Lig isimlendirmesini Türkçeleştir
  final leagueName = _getLeagueNameTr(league);


    return Container(
      color: Color(0xFF3A1C71), // Ana arka plan rengiyle aynı
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Avatar ve Kullanıcı Bilgileri
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Blur Efektli Avatar
              _buildBlurryAvatar(league),
              
              const SizedBox(width: 16),
              
              // Kullanıcı Bilgileri
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nickname,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    
                    // Lig Göstergesi
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: _getLeagueColor(league).withOpacity(0.2),
                        border: Border.all(
                          color: _getLeagueColor(league),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        leagueName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _getLeagueColor(league),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Altın Göstergesi
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.monetization_on, color: Colors.amber[300], size: 18),
                    const SizedBox(width: 4),
                    Text(
                      _formatGold(gold),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber[300],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Seviye ve Deneyim Göstergesi
          _buildLevelProgressBar(level, xp),
          
          const SizedBox(height: 16),
          
          // Özet İstatistikler
          _buildQuickStats(),
        ],
      ),
    );
  }

  Widget _buildBlurryAvatar(String league) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Avatar Arka Planı
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _getLeagueColor(league).withOpacity(0.3),
          ),
        ),
        
        // Avatar İçeriği
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _getLeagueColor(league).withOpacity(0.9),
                _getLeagueColor(league).withOpacity(0.6),
              ],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.5),
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.person,
            color: Colors.white,
            size: 40,
          ),
        ),
        
        // Lig İkonu
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: _getLeagueIcon(league),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLevelProgressBar(int level, int xp) {
    // Bu seviye için gerekli XP
    final int requiredXp = _calculateRequiredXp(level);
    
    // Mevcut seviye için şu anki XP miktarı
    final int currentLevelXp = _calculateCurrentLevelXp(level, xp);
    
    // Güvenli double dönüşümü
    double progress = 0.0;
    try {
      if (requiredXp > 0) {
        progress = currentLevelXp / requiredXp;
      }
    } catch (e) {
      progress = 0.0;
    }
    
    // Progress 0-1 aralığında olmalı
    if (progress < 0) progress = 0.0;
    if (progress > 1) progress = 1.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Seviye Göstergesi
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Seviye $level',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              '$currentLevelXp / $requiredXp XP',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // İlerleme Çubuğu
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 12,
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    // İstatistiklerden alınan veriler
    final totalGames = _parseIntSafely(statsData?['total_games']);
    final totalWins = _parseIntSafely(statsData?['total_wins']);
    final totalLosses = _parseIntSafely(statsData?['total_losses']);
    
    // win_rate değerini double'a güvenli dönüşüm
    double winRate = 0.0;
    if (statsData != null && statsData!['win_rate'] != null) {
      if (statsData!['win_rate'] is double) {
        winRate = statsData!['win_rate'];
      } else if (statsData!['win_rate'] is int) {
        winRate = (statsData!['win_rate'] as int).toDouble();
      } else {
        winRate = double.tryParse(statsData!['win_rate'].toString()) ?? 0.0;
      }
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Color(0xFF5E60CE).withOpacity(0.3),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(totalGames.toString(), 'Maç'),
          _buildDivider(),
          _buildStatItem(totalWins.toString(), 'Galibiyet'),
          _buildDivider(),
          _buildStatItem(totalLosses.toString(), 'Mağlubiyet'),
          _buildDivider(),
          _buildStatItem('${winRate.toInt()}%', 'Kazanma'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.white.withOpacity(0.2),
    );
  }

  // Lig adını Türkçeleştir
  String _getLeagueNameTr(String league) {
    switch (league.toUpperCase()) {
      case 'BRONZE':
        return 'Bronz';
      case 'SILVER':
        return 'Gümüş';
      case 'GOLD':
        return 'Altın';
      case 'PLATINUM':
        return 'Platin';
      case 'DIAMOND':
        return 'Elmas';
      default:
        return league;
    }
  }

  // Lig rengini al
  Color _getLeagueColor(String league) {
    switch (league.toUpperCase()) {
      case 'BRONZE':
        return Colors.brown;
      case 'SILVER':
        return Colors.grey.shade400;
      case 'GOLD':
        return Colors.amber;
      case 'PLATINUM':
        return Colors.cyan;
      case 'DIAMOND':
        return Colors.lightBlueAccent;
      default:
        return Colors.brown;
    }
  }

  // Lig ikonunu al
  Widget _getLeagueIcon(String league) {
    IconData iconData;
    Color iconColor;
    
    switch (league.toUpperCase()) {
      case 'BRONZE':
        iconData = Icons.shield;
        iconColor = Colors.brown;
        break;
      case 'SILVER':
        iconData = Icons.shield;
        iconColor = Colors.grey.shade400;
        break;
      case 'GOLD':
        iconData = Icons.shield;
        iconColor = Colors.amber;
        break;
      case 'PLATINUM':
        iconData = Icons.shield;
        iconColor = Colors.cyan;
        break;
      case 'DIAMOND':
        iconData = Icons.diamond;
        iconColor = Colors.lightBlueAccent;
        break;
      default:
        iconData = Icons.shield;
        iconColor = Colors.brown;
    }
    
    return Icon(
      iconData,
      color: iconColor,
      size: 16,
    );
  }

  // Büyük altın miktarlarını formatla (örn: 1.2M, 350K gibi)
  String _formatGold(int gold) {
    if (gold >= 1000000) {
      return '${(gold / 1000000).toStringAsFixed(1)}M';
    } else if (gold >= 1000) {
      return '${(gold / 1000).toStringAsFixed(1)}K';
    } else {
      return gold.toString();
    }
  }
}