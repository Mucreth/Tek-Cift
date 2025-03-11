// lib/features/home/widgets/game_logo_widget.dart
import 'package:flutter/material.dart';

class GameLogoWidget extends StatelessWidget {
  final String gameType;
  final bool isActive;
  final double parentWidth;
  
  const GameLogoWidget({
    Key? key,
    required this.gameType,
    required this.isActive,
    required this.parentWidth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Logo genişliği parent genişliğinin %80'i
    final logoWidth = parentWidth * 0.8;
    
    // Her oyun türü için logo yolunu belirle
    String logoPath;
    bool hasLogo = true;
    
    switch (gameType) {
      case 'rps':
        logoPath = 'assets/images/rps_logo.png';
        break;
      case 'oddeven':
        logoPath = 'assets/images/oddeven_logo.png';
        break;
      case 'number':
        logoPath = 'assets/images/number_logo.png';
        break;
      default:
        hasLogo = false;
        logoPath = '';
    }
    
    // Logo yoksa boş bir widget döndür
    if (!hasLogo) {
      return const SizedBox.shrink();
    }
    
    return AnimatedScale(
      scale: isActive ? 1.0 : 0.85,
      duration: const Duration(milliseconds: 400),
      child: Image.asset(
        logoPath,
        width: logoWidth,
        height: logoWidth * 0.5,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Logo yüklenemediğinde boş alan göster
          return const SizedBox.shrink();
        },
      ),
    );
  }
}