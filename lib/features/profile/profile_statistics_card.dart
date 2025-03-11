import 'package:flutter/material.dart';
import 'dart:ui';

class ProfileStatisticsCard extends StatelessWidget {
  final Map<String, dynamic>? statsData;

  const ProfileStatisticsCard({
    super.key,
    this.statsData,
  });

  @override
  Widget build(BuildContext context) {
    // Veri kontrolü
    if (statsData == null) {
      return _buildEmptyCard("Veri yok");
    }

    

    // Veri dönüşümleri
  int totalGames = _parseIntSafely(statsData!['total_games']);
  int totalWins = _parseIntSafely(statsData!['total_wins']);
  int totalLosses = _parseIntSafely(statsData!['total_losses']);
  int totalDraws = _parseIntSafely(statsData!['total_draws']);
  double winRate = _parseDoubleSafely(statsData!['win_rate']);

    if (totalGames == 0) {
    totalGames = totalWins + totalLosses + totalDraws;
  }

    try {
      // String değerleri için int'e dönüştürme
      totalGames = _parseIntSafely(statsData!['total_games']);
      totalWins = _parseIntSafely(statsData!['total_wins']);
      totalLosses = _parseIntSafely(statsData!['total_losses']);
      totalDraws = _parseIntSafely(statsData!['total_draws']);
      
      // Win rate için double'a dönüştürme
      if (statsData!['win_rate'] != null) {
        if (statsData!['win_rate'] is int) {
          winRate = (statsData!['win_rate'] as int).toDouble();
        } else if (statsData!['win_rate'] is double) {
          winRate = statsData!['win_rate'];
        } else {
          winRate = double.tryParse(statsData!['win_rate'].toString()) ?? 0.0;
        }
      }
    } catch (e) {
      print('Veri dönüşüm hatası: $e');
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Color(0xFF5E60CE).withOpacity(0.3),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık ve Win Rate
          _buildHeader(winRate),
          
          const SizedBox(height: 16),
          
          // Detaylı İstatistikler
          _buildStatRows(totalGames, totalWins, totalLosses, totalDraws),
          
          const SizedBox(height: 20),
          
          // Performans Grafiği Başlığı
          const Text(
            'Performans Grafiği',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Performans Grafiği
          _buildSimplePerformanceGraph(totalWins, totalLosses, totalDraws, totalGames),
        ],
      ),
    );
  }
  
  int _parseIntSafely(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

    double _parseDoubleSafely(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }
  
  // Boş kart widgeti
  Widget _buildEmptyCard(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Color(0xFF5E60CE).withOpacity(0.3),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 0.5,
        ),
      ),
      height: 150,
      alignment: Alignment.center,
      child: Text(
        message,
        style: TextStyle(
          fontSize: 16,
          color: Colors.white.withOpacity(0.7),
        ),
      ),
    );
  }
  
  // Başlık ve Win Rate
  Widget _buildHeader(double winRate) {
    final Color winRateColor = _getWinRateColor(winRate);
    final IconData winRateIcon = _getWinRateIcon(winRate);
    
    return Row(
      children: [
        const Icon(
          Icons.bar_chart,
          color: Colors.white,
          size: 20,
        ),
        const SizedBox(width: 8),
        const Text(
          'Detaylı İstatistikler',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: winRateColor.withOpacity(0.2),
          ),
          child: Row(
            children: [
              Icon(
                winRateIcon,
                color: winRateColor,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '${winRate.toInt()}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: winRateColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  // İstatistik Satırları
  Widget _buildStatRows(int totalGames, int totalWins, int totalLosses, int totalDraws) {
    return Column(
      children: [
        _buildStatRow('Toplam Maç', totalGames.toString()),
        _buildDivider(),
        _buildStatRow('Kazanılan', totalWins.toString()),
        _buildDivider(),
        _buildStatRow('Kaybedilen', totalLosses.toString()),
        _buildDivider(),
        _buildStatRow('Berabere', totalDraws.toString()),
      ],
    );
  }
  
  // Tek İstatistik Satırı
  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  
  // Ayırıcı Çizgi
  Widget _buildDivider() {
    return Divider(
      color: Colors.white.withOpacity(0.1),
      thickness: 1,
    );
  }
  
  // Basitleştirilmiş Performans Grafiği
  Widget _buildSimplePerformanceGraph(int wins, int losses, int draws, int total) {
    // Toplam maç yoksa boş döndür
    if (total == 0) {
      return Container(
        height: 50,
        alignment: Alignment.center,
        child: Text(
          'Henüz maç yok',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
      );
    }
    
    // Yüzde değerleri hesapla
    int winsPercent = (wins * 100 ~/ total).clamp(0, 100);
    int drawsPercent = (draws * 100 ~/ total).clamp(0, 100);
    int lossesPercent = (losses * 100 ~/ total).clamp(0, 100);
    
    // Yüzdelerin toplamını 100 yap
    int totalPercent = winsPercent + drawsPercent + lossesPercent;
    if (totalPercent != 100) {
      // En büyük değeri düzenle
      if (winsPercent >= drawsPercent && winsPercent >= lossesPercent) {
        winsPercent += (100 - totalPercent);
      } else if (lossesPercent >= winsPercent && lossesPercent >= drawsPercent) {
        lossesPercent += (100 - totalPercent);
      } else {
        drawsPercent += (100 - totalPercent);
      }
    }
    
    // Grafiğin genişliklerini hesapla (min 1)
    int winsFlex = winsPercent > 0 ? winsPercent : 1;
    int lossesFlex = lossesPercent > 0 ? lossesPercent : 1;
    int drawsFlex = drawsPercent > 0 ? drawsPercent : 1;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Grafik Çubuğu
        SizedBox(
          height: 30,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Row(
              children: [
                // Kazanma Bölümü
                Expanded(
                  flex: winsFlex,
                  child: Container(
                    color: Colors.green,
                    child: Center(
                      child: winsPercent > 15 ? Text(
                        '$winsPercent%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ) : const SizedBox(),
                    ),
                  ),
                ),
                
                // Beraberlik Bölümü
                Expanded(
                  flex: drawsFlex,
                  child: Container(
                    color: Colors.orange,
                    child: Center(
                      child: drawsPercent > 15 ? Text(
                        '$drawsPercent%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ) : const SizedBox(),
                    ),
                  ),
                ),
                
                // Kaybetme Bölümü
                Expanded(
                  flex: lossesFlex,
                  child: Container(
                    color: Colors.red,
                    child: Center(
                      child: lossesPercent > 15 ? Text(
                        '$lossesPercent%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ) : const SizedBox(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Gösterge
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem('Galibiyet', Colors.green),
            const SizedBox(width: 16),
            _buildLegendItem('Beraberlik', Colors.orange),
            const SizedBox(width: 16),
            _buildLegendItem('Mağlubiyet', Colors.red),
          ],
        ),
      ],
    );
  }
  
  // Gösterge Öğesi
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
  
  // Win Rate Rengi
  Color _getWinRateColor(double winRate) {
    if (winRate >= 65) {
      return Colors.green;
    } else if (winRate >= 50) {
      return Colors.lightGreen;
    } else if (winRate >= 35) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
  
  // Win Rate İkonu
  IconData _getWinRateIcon(double winRate) {
    if (winRate >= 65) {
      return Icons.emoji_events;
    } else if (winRate >= 50) {
      return Icons.thumb_up;
    } else if (winRate >= 35) {
      return Icons.thumbs_up_down;
    } else {
      return Icons.trending_down;
    }
  }
}