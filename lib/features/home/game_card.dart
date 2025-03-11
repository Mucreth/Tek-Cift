// lib/features/home/widgets/game_card_widget.dart
import 'package:flutter/material.dart';
import 'package:handclash/features/home/how_to_play_button.dart';

class GameCardWidget extends StatelessWidget {
  final int index;
  final int currentPage;
  final String gameType;
  
  const GameCardWidget({
    Key? key,
    required this.index,
    required this.currentPage,
    required this.gameType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ekran boyutları
    final screenWidth = MediaQuery.of(context).size.width;
    final isActive = currentPage == index;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      transform: Matrix4.identity()
        ..scale(isActive ? 1.0 : 0.85),  // Aktif kartta hafif büyütme
      transformAlignment: Alignment.center,
      width: screenWidth * 0.7,
      height: screenWidth * 0.7 * (9/16) * 1.8, // 16:9 oranı, 1.8 katsayısıyla yüksekliği artır
      decoration: BoxDecoration(
        color: Colors.transparent, // Arka plan rengini transparent yaparak beyaz efekti engelleriz
        borderRadius: BorderRadius.circular(24),
        // Sadece aktif kartta ve sadece alt kısımda border
        border: isActive ? const Border(
          bottom: BorderSide(
            color: Color(0xFF3A1010), // Kenar çizgisi koyu kırmızı
            width: 3, // Biraz daha kalın
          ),
        ) : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Oyun posteri - Tüm oyun türleri için
            _buildGamePoster(),
              
            // Üst kısım - Oyun etiketi ve Nasıl Oynanır butonu yan yana
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Oyun etiketi (sol tarafta)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.sports_esports, color: Colors.white, size: 18),
                        // SizedBox(width: 6),
                        // Text(
                        //   'Oyun',
                        //   style: TextStyle(
                        //     color: Colors.white,
                        //     fontWeight: FontWeight.bold,
                        //     fontSize: 14,
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                  
                  // Nasıl Oynanır butonu (sağ tarafta)
                  // İndikatör kısmından buraya taşındı
                  Container(
                    height: 30,
                    child: HowToPlayButton(currentPage: currentPage),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Oyun türüne göre poster gösterme
  Widget _buildGamePoster() {
    // Her oyun türü için poster yolunu belirle
    String posterPath;
    IconData fallbackIcon;
    
    switch (gameType) {
      case 'rps':
        posterPath = 'assets/images/rps_poster.png';
        fallbackIcon = Icons.sports_handball;
        break;
      case 'oddeven':
        posterPath = 'assets/images/oddeven_poster.png';
        fallbackIcon = Icons.casino;
        break;
      case 'number':
        posterPath = 'assets/images/number_poster.png';
        fallbackIcon = Icons.psychology;
        break;
      default:
        posterPath = '';
        fallbackIcon = Icons.sports_esports;
    }
    
    // Poster göstermeyi dene, hata durumunda fallback göster
    return Image.asset(
      posterPath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        // Poster bulunamadıysa fallback container göster
        return Container(
          color: const Color(0xFF1F0D0D),
          child: Center(
            child: Icon(
              fallbackIcon,
              size: 80,
              color: Colors.white.withOpacity(0.3),
            ),
          ),
        );
      },
    );
  }
}