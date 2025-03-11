// lib/shared/widgets/app_top_bar.dart
import 'package:flutter/material.dart';
import 'dart:ui';

// lib/shared/widgets/app_top_bar.dart

class AppTopBar extends StatelessWidget {
  final VoidCallback? onLeagueButtonPressed;
  final VoidCallback? onProfileButtonPressed;
  final double height;
  final Map<String, dynamic>? userData;

  const AppTopBar({
    Key? key,
    this.onLeagueButtonPressed,
    this.onProfileButtonPressed,
    this.height = 50,
    this.userData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ortada logo (tam ortada)
          Center(
            child: Image.asset(
              'assets/images/logo.png',
              height: height * 0.7, // Yüksekliğin %70'i
              fit: BoxFit.contain,
            ),
          ),

          // Yan elemanları içeren Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Sol köşe - Gold bilgisi (sabit genişlikli ve blur arkaplanı)
// Sol köşe - Gold bilgisi (içeriğe göre genişlik ve blur arkaplanı)
ClipRRect(
  borderRadius: BorderRadius.circular(20),
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
    child: Container(
      // Sabit genişlik yerine içeriğe göre otomatik ayarlanacak
      constraints: const BoxConstraints(
        minWidth: 50, // Minimum genişlik
        maxWidth: 150, // Maksimum genişlik
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.grey.withOpacity(0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, // İçeriğe göre küçülsün
        children: [
          Icon(Icons.monetization_on, color: Colors.amber[300], size: 20),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              _formatGold(userData?['current_gold'] ?? 0),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.amber[300],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ),
  ),
),

              // Sağ köşe - Profil butonu (sabit genişlikli ve blur arkaplanı)
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    width: 40, // Daha küçük ve yuvarlak
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.15),
                          Colors.grey.withOpacity(0.15),
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 0.5,
                      ),
                    ),
                    child: IconButton(
                      onPressed: onProfileButtonPressed,
                      icon: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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
