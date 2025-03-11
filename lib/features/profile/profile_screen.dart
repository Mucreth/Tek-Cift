import 'package:flutter/material.dart';
import 'package:handclash/features/auth/auth_service.dart';
import 'package:handclash/features/profile/friends_list_widget.dart';
import 'package:handclash/features/profile/premium_status_card.dart';
import 'package:handclash/features/profile/profile_header_widget.dart';
import 'package:handclash/features/profile/profile_service.dart';
import 'package:handclash/features/profile/profile_settings_widget.dart';
import 'package:handclash/features/profile/profile_statistics_card.dart';
import 'package:handclash/features/profile/recent_matches_widget.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:handclash/shared/models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();
  
  late TabController _tabController;
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _statsData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, initialIndex: 1, vsync: this);
    _loadUserData();
    
    // Status bar rengini ayarla
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
Future<void> _loadUserData() async {
  setState(() => _isLoading = true);
  
  try {
    // Kullanıcı bilgilerini al
    final userData = await _authService.getCurrentUser();
    print("ProfileScreen - API'den gelen userData: $userData");
    
    // İstatistikleri al
    if (userData != null) {
      final statsResponse = await _profileService.getUserStatistics(userData['user_id']);
      print("ProfileScreen - API'den gelen statsResponse: $statsResponse");
      
      setState(() {
        _userData = userData;
        _statsData = statsResponse;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  } catch (e) {
    print('Profil verileri yüklenirken hata: $e');
    setState(() => _isLoading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            color: Color(0xFF3A1C71),
          ),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Bulanık arka plan
          _buildBlurredBackground(),
          
          // Ana içerik
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  backgroundColor: Color(0xFF3A1C71),
                  expandedHeight: 0,
                  pinned: true,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: const Text(
                    'Profil',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.settings, color: Colors.white),
                      onPressed: () {
                        // Ayarlar ekranına yönlendirme
                        _showSettingsBottomSheet(context);
                      },
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: ProfileHeaderWidget(
                    userData: _userData,
                    statsData: _statsData,
                  ),
                ),
                SliverPersistentHeader(
                  delegate: _SliverAppBarDelegate(
                    TabBar(
                      controller: _tabController,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white.withOpacity(0.6),
                      indicatorColor: Colors.amber,
                      indicatorWeight: 3,
                      tabs: const [
                        Tab(text: 'İstatistikler'),
                        Tab(text: 'Son Maçlar'),
                        Tab(text: 'Arkadaşlar'),
                      ],
                    ),
                  ),
                  pinned: true,
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                // İstatistikler Sekmesi
                _buildStatisticsTab(),
                
                // Son Maçlar Sekmesi
                RecentMatchesWidget(userId: _userData?['user_id']),
                
                // Arkadaşlar Sekmesi
                FriendsListWidget(userId: _userData?['user_id']),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatisticsTab() {
    return ListView(
      padding: EdgeInsets.only(
        left: 16, 
        right: 16, 
        top: 16,
        bottom: 16 + MediaQuery.of(context).padding.bottom, // Bottom safe area
      ),
      children: [
        ProfileStatisticsCard(statsData: _statsData),
        const SizedBox(height: 16),
        //PremiumStatusCard(userId: _userData?['user_id']),
      ],
    );
  }

  Widget _buildBlurredBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF3A1C71),  // Koyu mor
            Color(0xFF7C3AAD),  // Orta mor-mavi
            Color(0xFF5E60CE),  // Lacivert-mor
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
    );
  }

  void _showSettingsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF3A1C71),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: EdgeInsets.only(
          left: 24, 
          right: 24, 
          top: 24, 
          bottom: MediaQuery.of(context).padding.bottom + 24, // SafeArea için
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ProfileSettingsWidget(
                onEditProfile: () {
                  Navigator.pop(context);
                  // Profil düzenleme sayfasına yönlendirme
                },
                onChangeNickname: () {
                  Navigator.pop(context);
                  // Kullanıcı adı değiştirme ekranına yönlendirme
                },
                onSupport: () {
                  Navigator.pop(context);
                  // Destek sayfasına yönlendirme
                },
                onLogout: () {
                  Navigator.pop(context);
                  // Çıkış yap
                },
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white.withOpacity(0.1),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'Kapat',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverAppBarDelegate(this.tabBar);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF3A1C71),
      ),
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant _SliverAppBarDelegate oldDelegate) {
    return false;
  }
}