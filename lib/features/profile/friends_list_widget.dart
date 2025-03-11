import 'package:flutter/material.dart';
import 'package:handclash/features/profile/profile_service.dart';

import 'dart:ui';

class FriendsListWidget extends StatefulWidget {
  final String? userId;

  const FriendsListWidget({
    super.key,
    required this.userId,
  });

  @override
  State<FriendsListWidget> createState() => _FriendsListWidgetState();
}

class _FriendsListWidgetState extends State<FriendsListWidget> {
  final ProfileService _profileService = ProfileService();
  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> _pendingRequests = [];
  bool _isLoading = true;
  bool _showPendingRequests = false;

  @override
  void initState() {
    super.initState();
    _loadFriends();
    _loadPendingRequests();
  }

  Future<void> _loadFriends() async {
    if (widget.userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final friends = await _profileService.getFriendsList(widget.userId!);
      
      if (mounted) {
        setState(() {
          _friends = friends;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Arkadaş listesi yüklenirken hata: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadPendingRequests() async {
    if (widget.userId == null) return;

    try {
      final requests = await _profileService.getPendingRequests(widget.userId!);
      
      if (mounted) {
        setState(() {
          _pendingRequests = requests;
        });
      }
    } catch (e) {
      print('Bekleyen istekler yüklenirken hata: $e');
    }
  }

  Future<void> _respondToRequest(String friendshipId, String response) async {
    try {
      final success = await _profileService.respondToFriendRequest(friendshipId, response);

      if (success) {
        // Listeyi güncelle
        await _loadPendingRequests();
        if (response == 'accept') {
          await _loadFriends();
        }
      }
    } catch (e) {
      print('Arkadaşlık isteği yanıtlama hatası: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Sekme düğmeleri
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: _buildTabButton(
                  title: 'Arkadaşlar',
                  isSelected: !_showPendingRequests,
                  onTap: () => setState(() => _showPendingRequests = false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTabButton(
                  title: 'İstekler${_pendingRequests.isNotEmpty ? " (${_pendingRequests.length})" : ""}',
                  isSelected: _showPendingRequests,
                  onTap: () => setState(() => _showPendingRequests = true),
                  hasBadge: _pendingRequests.isNotEmpty,
                ),
              ),
            ],
          ),
        ),
        
        // İçerik
        Expanded(
          child: _showPendingRequests
              ? _buildPendingRequestsList()
              : _buildFriendsList(),
        ),
      ],
    );
  }

  Widget _buildTabButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    bool hasBadge = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isSelected 
              ? Colors.white.withOpacity(0.15)
              : Colors.transparent,
          border: Border.all(
            color: isSelected 
                ? Colors.white.withOpacity(0.3)
                : Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected 
                    ? Colors.white
                    : Colors.white.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (hasBadge)
              Positioned(
                right: 8,
                top: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendsList() {
    if (_friends.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people,
                size: 60,
                color: Colors.white.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'Arkadaş listeniz boş',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Arkadaş eklemek için istekler bölümünü kontrol edin',
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _friends.length,
      itemBuilder: (context, index) {
        final friend = _friends[index];
        return _buildFriendCard(friend);
      },
    );
  }

  Widget _buildPendingRequestsList() {
    if (_pendingRequests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.notifications,
                size: 60,
                color: Colors.white.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'Bekleyen istek yok',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _pendingRequests.length,
      itemBuilder: (context, index) {
        final request = _pendingRequests[index];
        return _buildRequestCard(request);
      },
    );
  }

  Widget _buildFriendCard(Map<String, dynamic> friend) {
    final String nickname = friend['nickname'] ?? 'Arkadaş';
    final String? league = friend['current_league'];
    final int level = friend['level'] is int 
        ? friend['level'] 
        : int.tryParse(friend['level']?.toString() ?? '1') ?? 1;
    final String lastGameAt = friend['last_game_at'] ?? '';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white.withOpacity(0.05),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _getLeagueColor(league).withOpacity(0.8),
                        _getLeagueColor(league).withOpacity(0.5),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Kullanıcı Bilgileri
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nickname,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: _getLeagueColor(league).withOpacity(0.2),
                            ),
                            child: Text(
                              _getLeagueNameTr(league),
                              style: TextStyle(
                                fontSize: 10,
                                color: _getLeagueColor(league),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.amber.withOpacity(0.2),
                            ),
                            child: Text(
                              'Seviye $level',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.amber[300],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Son Oyun Tarihi
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.blue.withOpacity(0.1),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.sports_esports,
                            color: Colors.blue[300],
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Oyna',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[300],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatLastGameDate(lastGameAt),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final String senderNickname = request['sender_nickname'] ?? 'Kullanıcı';
    final String friendshipId = request['friendship_id'] ?? '';
    final String createdAt = request['created_at'] ?? '';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white.withOpacity(0.05),
              border: Border.all(
                color: Colors.amber.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                // Üst Kısım: Gönderen Bilgileri
                Row(
                  children: [
                    // Avatar
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.amber.withOpacity(0.2),
                        border: Border.all(
                          color: Colors.amber.withOpacity(0.5),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.person_add,
                        color: Colors.amber,
                        size: 30,
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // İstek Bilgileri
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            senderNickname,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Arkadaşlık İsteği',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Tarih
                    Text(
                      _formatDate(createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Alt Kısım: Butonlar
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        title: 'Reddet',
                        color: Colors.red,
                        onPressed: () => _respondToRequest(friendshipId, 'reject'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        title: 'Kabul Et',
                        color: Colors.green,
                        onPressed: () => _respondToRequest(friendshipId, 'accept'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String title,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: color.withOpacity(0.1),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  String _formatLastGameDate(String dateTime) {
    if (dateTime.isEmpty) return 'Hiç oynamadı';
    
    try {
      final date = DateTime.parse(dateTime);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays > 30) {
        return '${(difference.inDays / 30).floor()} ay önce';
      } else if (difference.inDays > 0) {
        return '${difference.inDays} gün önce';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} saat önce';
      } else {
        return '${difference.inMinutes} dakika önce';
      }
    } catch (e) {
      return 'Tarih yok';
    }
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
      return '';
    }
  }

  // Lig adını Türkçeleştir
  String _getLeagueNameTr(String? league) {
    if (league == null) return 'Bronz';
    
    switch (league.toLowerCase()) {
      case 'bronze':
        return 'Bronz';
      case 'silver':
        return 'Gümüş';
      case 'gold':
        return 'Altın';
      case 'platinum':
        return 'Platin';
      case 'diamond':
        return 'Elmas';
      default:
        return league;
    }
  }

  // Lig rengini al
  Color _getLeagueColor(String? league) {
    if (league == null) return Colors.brown;
    
    switch (league.toLowerCase()) {
      case 'bronze':
        return Colors.brown;
      case 'silver':
        return Colors.grey.shade400;
      case 'gold':
        return Colors.amber;
      case 'platinum':
        return Colors.cyan;
      case 'diamond':
        return Colors.lightBlueAccent;
      default:
        return Colors.brown;
    }
  }}