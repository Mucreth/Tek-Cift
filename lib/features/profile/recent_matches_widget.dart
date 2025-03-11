import 'package:flutter/material.dart';
import 'package:handclash/features/profile/profile_service.dart';
import 'dart:ui';

class RecentMatchesWidget extends StatefulWidget {
  final String? userId;

  const RecentMatchesWidget({
    super.key,
    required this.userId,
  });

  @override
  State<RecentMatchesWidget> createState() => _RecentMatchesWidgetState();
}

class _RecentMatchesWidgetState extends State<RecentMatchesWidget> {
  final ProfileService _profileService = ProfileService();
  List<Map<String, dynamic>> _recentMatches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentMatches();
  }

  Future<void> _loadRecentMatches() async {
    if (widget.userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final matches = await _profileService.getRecentMatches(widget.userId!);
      
      setState(() {
        _recentMatches = matches;
        _isLoading = false;
      });
    } catch (e) {
      print('Son maçlar yüklenirken hata: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_recentMatches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sports_esports,
                size: 60,
                color: Colors.white.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'Henüz hiç maç oynamadınız',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Maç geçmişiniz burada görünecek',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.5),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _recentMatches.length,
      itemBuilder: (context, index) {
        final match = _recentMatches[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: _buildMatchCard(match),
        );
      },
    );
  }

  Widget _buildMatchCard(Map<String, dynamic> match) {
    final String gameId = match['game_id'] ?? '';
    final String opponentNickname = match['opponent_nickname'] ?? 'Rakip';
    final String winner = match['winner'] ?? '';
    final int betAmount = match['bet_amount'] is int 
        ? match['bet_amount'] 
        : int.tryParse(match['bet_amount']?.toString() ?? '0') ?? 0;
    
    // Maç tarihini hesapla
    final String startedAt = match['started_at'] ?? '';
    final String endedAt = match['ended_at'] ?? '';
    
    // Kullanıcının kazanıp kazanmadığını belirle
    final bool isWinner = winner == widget.userId;
    final bool isDraw = winner == 'draw';
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white.withOpacity(0.05),
            border: Border.all(
              color: _getResultColor(isWinner, isDraw).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst Kısım: Sonuç ve Rakip
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Sonuç
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: _getResultColor(isWinner, isDraw).withOpacity(0.1),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getResultIcon(isWinner, isDraw),
                          color: _getResultColor(isWinner, isDraw),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getResultText(isWinner, isDraw),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _getResultColor(isWinner, isDraw),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Bahis Miktarı
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.amber.withOpacity(0.1),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.monetization_on,
                          color: Colors.amber[300],
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          betAmount.toString(),
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
              
              const SizedBox(height: 12),
              
              // Orta Kısım: Rakip ve Tarih
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Rakip
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.1),
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                opponentNickname,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Rakip',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Tarih
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatDate(endedAt),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      Text(
                        _formatTime(endedAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getResultColor(bool isWinner, bool isDraw) {
    if (isDraw) return Colors.orange;
    return isWinner ? Colors.green : Colors.red;
  }

  IconData _getResultIcon(bool isWinner, bool isDraw) {
    if (isDraw) return Icons.handshake;
    return isWinner ? Icons.emoji_events : Icons.cancel;
  }

  String _getResultText(bool isWinner, bool isDraw) {
    if (isDraw) return 'Berabere';
    return isWinner ? 'Galibiyet' : 'Mağlubiyet';
  }

String _formatDate(String dateTime) {
  if (dateTime.isEmpty) return '';
  
  try {
    final date = DateTime.parse(dateTime);
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else {
      return '${difference.inMinutes} dk önce';
    }
  } catch (e) {
    print('Tarih dönüşüm hatası: $e');
    return '';
  }
}

  String _formatTime(String dateTime) {
    if (dateTime.isEmpty) return 'Saat Yok';
    
    try {
      final date = DateTime.parse(dateTime);
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Geçersiz Saat';
    }
  }
}