// lib/features/home/view/home_screen.dart
import 'package:flutter/material.dart';
import 'package:handclash/core/constants/app_constants.dart';
import 'package:handclash/features/auth/auth_service.dart';
import 'dart:ui'; // ImageFilter için
import 'package:handclash/features/game/game_screen.dart';
import 'package:handclash/features/home/app_top_bar.dart';
import 'package:handclash/features/home/game_buttons_widget.dart';
import 'package:handclash/features/home/game_card.dart';
import 'package:handclash/features/home/game_info_widget.dart';
import 'package:handclash/features/home/game_logo_widget.dart';
import 'package:handclash/features/home/page_indicators_widget.dart';

import 'package:handclash/features/profile/profile_screen.dart';

import 'package:handclash/shared/widgets/game_loader.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  Map<String, dynamic>? _userData;
  late final PageController _pageController;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _pageController = PageController(
      viewportFraction: 0.75, // Apple Davetiye gibi diğer kartların kenarları da görünecek
      initialPage: 1, // İkinci kutudan başla
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final userData = await _authService.getCurrentUser();
    if (mounted) {
      setState(() => _userData = userData);
    }
  }

// lib/features/home/home_screen.dart

Future<void> _startGame(String gameType, int targetScore, int betAmount, bool isAIGame) async {
  if (_userData == null || _userData!['current_gold'] < betAmount) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Yetersiz gold! Bu bahis için yeterli altın bakiyeniz yok.')),
    );
    return;
  }

  setState(() => _isLoading = true);

  try {
    // Kullanıcının lig kontrolü
    final String userLeague = _userData!['current_league'] ?? AppConstants.defaultLeague;
    final Map<String, dynamic> leagueInfo = AppConstants.leagueLimits[userLeague] ?? 
                                         AppConstants.leagueLimits[AppConstants.defaultLeague]!;
    
    // Bahis limitleri kontrolü - AI modunda kontrolü atla
    if (!isAIGame) {
      final int minBet = leagueInfo['min_bet'];
      final int maxBet = leagueInfo['max_bet'];
      
      if (betAmount != minBet && betAmount != maxBet) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bu lig için sadece $minBet veya $maxBet bahis yapabilirsiniz!')),
        );
        setState(() => _isLoading = false);
        return;
      }
    } else {
      // AI modu için bahis kontrolü
      final int aiBet = leagueInfo['ai_bet'];
      if (betAmount != aiBet) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI modu için bahis miktarı $aiBet olmalıdır.')),
        );
        setState(() => _isLoading = false);
        return;
      }
    }

    // Altını hemen düş (UI güncellemesi için)
    _userData!['current_gold'] -= betAmount;
    
    // Oyuna yönlendir
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => GameScreen(
            gameType: gameType,
            betAmount: betAmount,
            targetScore: targetScore,
            isAIGame: isAIGame, // isAIGame parametresini ilettik
          ),
        ),
      );
    }
  } catch (e) {
    // Hata durumunda altını geri ekle
    if (_userData != null) {
      _userData!['current_gold'] += betAmount;
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Oyun başlatılamadı: $e')),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}
void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
  }

final List<Map<String, dynamic>> _games = [
  {
    'title': 'Odd or Even',
    'subtitle': 'Prediction Game',
    'description': 'Test your luck with prediction skills.\nMake right guesses to defeat opponents!',
    'gameType': 'oddeven',
    'isAvailable': false, // Game not available yet
  },
  {
    'title': 'Rock Paper Scissors',
    'subtitle': 'Classic Game',
    'description': 'Master rock, paper and scissors.\nPredict moves and winning strategies!',
    'gameType': 'rps',
    'isAvailable': true, // The only available game
  },
  {
    'title': 'Number Guess',
    'subtitle': 'Intelligence Game',
    'description': 'Use your analytical thinking skills.\nEvaluate clues and find the right number!',
    'gameType': 'number',
    'isAvailable': false, // Game not available yet
  },
];

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: GameLoader(message: 'Oyun başlatılıyor...'),
      );
    }

    // Mevcut oyun bilgilerini al
    final currentGame = _games[_currentPage];
    final bool isGameAvailable = currentGame['isAvailable'] ?? false;
    final String gameType = currentGame['gameType'];
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * 0.7;

    return Scaffold(
      backgroundColor: Colors.black, // Sayfa arka planı siyah olsun
      // Arka plan rengini kaldırıyoruz çünkü özel arka plan ekleyeceğiz
      body: Stack(
        children: [
          // Bulanık arka plan
          _buildBlurredBackground(),
          
          // Ana İçerik
          SafeArea(
            child: Column(
              children: [
                // Custom TopBar
                AppTopBar(
                  onProfileButtonPressed: _navigateToProfile,
                  userData: _userData,
                ),
                
                const SizedBox(height: 16),
                
                // Oyun kartları kısmı
                Expanded(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Column(
                        children: [
                          // Sadece kartlar için PageView
                          Expanded(
                            flex: 4, // Kartlar için daha fazla alan
                            child: Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.center,
                              children: [
                                // Kartlar PageView
                                PageView.builder(
                                  controller: _pageController,
                                  itemCount: _games.length,
                                  physics: const BouncingScrollPhysics(
                                    parent: AlwaysScrollableScrollPhysics(),
                                  ),
                                  onPageChanged: (index) {
                                    setState(() {
                                      _currentPage = index;
                                    });
                                  },
                                  itemBuilder: (context, index) {
                                    return GameCardWidget(
                                      index: index,
                                      currentPage: _currentPage,
                                      gameType: _games[index]['gameType'],
                                    );
                                  },
                                ),
                                
                                // Logo - Kartın altından taşacak şekilde
                                Positioned(
                                  bottom: -40, // Kartın alt kısmından taşma miktarı
                                  child: GameLogoWidget(
                                    gameType: gameType,
                                    isActive: true,
                                    parentWidth: cardWidth,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Sabit başlık ve butonlar kısmı
                          Expanded(
                            flex: 2, // Başlık ve butonlar için daha az alan
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Boşluk
                                const SizedBox(height: 12),
                                
                                // Açıklama metni (Description) - GameInfoWidget
                                GameInfoWidget(
                                  title: currentGame['title'],
                                  description: currentGame['description'],
                                ),
                                
                                // Butonlar
                                SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                                
                                // Tek buton ve popup menü ile oyun butonları
                                GameButtonsWidget(
                                  gameType: gameType,
                                  isGameAvailable: isGameAvailable,
                                  onStartGame: _startGame,
                                  userData: _userData,
                                ),
                              ],
                            ),
                          ),
                          
                          // Sayfa göstergeleri (dots)
                          PageIndicatorsWidget(
                            currentPage: _currentPage,
                            pageCount: _games.length,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Bulanıklaştırılmış arka plan oluşturma
  Widget _buildBlurredBackground() {
    // Mevcut oyun bilgilerini al
    final currentGame = _games[_currentPage];
    String assetPath;
    
    // Oyun türüne göre arka plan resmi seç
    if (currentGame['gameType'] == 'rps') {
      assetPath = 'assets/images/rps_poster.png';
    } else if (currentGame['gameType'] == 'oddeven') {
      assetPath = 'assets/images/oddeven_poster.png';
    } else {
      assetPath = 'assets/images/number_poster.png';
    }
    
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: Container(
        key: ValueKey<int>(_currentPage), // Animasyon için key
        decoration: BoxDecoration(
          color: Colors.black,
          image: DecorationImage(
            image: AssetImage(assetPath),
            fit: BoxFit.cover,
            opacity: 0.7, // Resim opaklığını arttırdım (daha görünür)
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 60.0, sigmaY: 60.0), // Bulanıklık efektini arttırdım
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2), // Siyahlığı azalttım
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.2), // Üst kısımdaki siyahlığı azalttım
                  Colors.black.withOpacity(0.4), // Alt kısımdaki siyahlığı biraz azalttım
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}