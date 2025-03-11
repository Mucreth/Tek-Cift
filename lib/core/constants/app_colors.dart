// lib/shared/constants/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // Genel renkler
  static const Color black = Colors.black;
  static const Color white = Colors.white;
  
  // Arka plan ve panel renkleri
  static const Color darkBackground = Color(0xFF0D1A0C);
  
  // Takım renkleri
  static const Color greenPrimary = Colors.green;
  static const Color greenSecondary = Color(0xFF0D1A0C);
  static const Color redPrimary = Colors.red;
  static const Color redSecondary = Color(0xFF1E0B0B);
  
  // Buton ve vurgu renkleri
  static Color greenOverlay = Colors.green.withOpacity(0.5);
  static Color greenShadow = Colors.green.withOpacity(0.2);
  static Color darkOverlay = Colors.black.withOpacity(0.6);
  static Color redOverlay = const Color.fromARGB(255, 175, 76, 76).withOpacity(0.5);
  static Color redShadow = const Color.fromARGB(255, 175, 76, 76).withOpacity(0.2);
  // Fazlara göre renkler
  static const Color playingPhaseColor = Colors.blue;
  static const Color revealingPhaseColor = Colors.orange;
  static const Color resultPhaseColor = Colors.purple;

  // Gradyan arka plan renkleri
  static const Color preparationGradientStart = Color(0xFF1A237E); // Koyu mavi
  static const Color preparationGradientEnd = Color(0xFF303F9F); // Orta mavi
  
  static const Color playingGradientStart = Color(0xFF0D47A1); // Koyu mavi
  static const Color playingGradientEnd = Color(0xFF1976D2); // Açık mavi
  
  static const Color countdownGradientStart = Color(0xFFE65100); // Koyu turuncu
  static const Color countdownGradientEnd = Color(0xFFFF9800); // Açık turuncu
  
  static const Color revealingGradientStart = Color(0xFF6A1B9A); // Koyu mor
  static const Color revealingGradientEnd = Color(0xFF9C27B0); // Açık mor
  
  static const Color jokerTimeGradientStart = Color(0xFFBF360C); // Koyu kırmızı
  static const Color jokerTimeGradientEnd = Color(0xFFE64A19); // Açık kırmızı
  
  // Transparan kart alanları için arka plan renkleri
  static Color transparentGreenCard = const Color(0xFF0D1A0C).withOpacity(0.7);
  static Color transparentRedCard = const Color(0xFF1E0B0B).withOpacity(0.7);
}