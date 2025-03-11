// lib/features/game/widgets/joker_bar.dart
import 'package:flutter/material.dart';
import 'package:handclash/features/game/game_enums.dart';
import 'package:handclash/features/game/game_view_model.dart';

class JokerBar extends StatelessWidget {
  final GameViewModel viewModel;
  final Function(JokerType)? onJokerPressed;
  final double width;
  final bool isOpponent; // Opponent için mi, oyuncu için mi?

  const JokerBar({
    Key? key, 
    required this.viewModel,
    this.onJokerPressed,
    this.width = 120,  // Varsayılan genişlik 120px
    this.isOpponent = false, // Varsayılan olarak oyuncu için
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // SVG oranını korumak için (130/413 ≈ 0.315)
    final height = width * 0.315;
    
    // Takım rengi kontrolü - opponent her zaman oyuncunun karşı takımında
    final bool isTeamGreen = isOpponent 
        ? !viewModel.state.isGreenTeam  // Rakip için oyuncunun tersini kullan
        : viewModel.state.isGreenTeam;  // Oyuncu için direkt state'teki değeri kullan
    
    // Takıma göre renk seçimi
    final Color teamActiveColor = isTeamGreen
        ? const Color(0xFF3D9970) // Koyu yeşil
        : const Color(0xFF9D2933); // Koyu kırmızı
    
    final Color teamInactiveColor = isTeamGreen
        ? const Color(0xFF163328) // Çok koyu yeşil
        : const Color(0xFF381A1E); // Çok koyu kırmızı
    
    return SizedBox(
      width: width,
      height: height, // Yükseklik değerini hesapla
      child: CustomPaint(
        painter: JokerBarPainter(
          isOpponent: isOpponent,
          isGreenTeam: isTeamGreen,  // Takım rengini de gönderiyoruz
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildJokerButton(JokerType.block, Icons.block, teamActiveColor, teamInactiveColor),
            _buildJokerButton(JokerType.blind, Icons.visibility_off, teamActiveColor, teamInactiveColor),
            _buildJokerButton(JokerType.bet, Icons.monetization_on, teamActiveColor, teamInactiveColor),
          ],
        ),
      ),
    );
  }

  // Joker buton widget'ı - takım rengine göre renklendirme
  Widget _buildJokerButton(JokerType type, IconData icon, Color teamActiveColor, Color teamInactiveColor) {
    late bool isUsed;
    late bool isActive;
    late int count;
    late bool canUseJoker;
    
    if (isOpponent) {
      // Rakip için joker durumları
      isUsed = viewModel.state.usedJokers.contains(type);
      isActive = viewModel.state.opponentJoker == type;
      count = 0; // Rakibin kaç jokeri kaldığını bilemeyiz
      canUseJoker = false; // Rakibin jokerlerine tıklayamayız
    } else {
      // Oyuncu için joker durumları
      count = viewModel.state.getJokerCount(type);
      isUsed = viewModel.state.usedJokers.contains(type);
      isActive = viewModel.state.selectedJoker == type;
      canUseJoker = viewModel.state.currentPhase == GamePhase.jokerSelect && 
                    viewModel.state.canUseJoker &&
                    count > 0 && 
                    !isUsed;
    }
    
    // Buton durumuna göre renk ayarları - takım rengine göre
    Color backgroundColor;
    Color iconColor;
    
    if (isUsed || (count <= 0 && !isOpponent)) {
      // Kullanılmış veya tükenmiş joker - Koyu takım rengi
      backgroundColor = teamInactiveColor.withOpacity(0.3);
      iconColor = teamInactiveColor.withOpacity(0.7); // Daha belirgin
    } else if (isActive) {
      // Aktif joker - Parlak takım rengi
      backgroundColor = teamActiveColor.withOpacity(0.3);
      iconColor = teamActiveColor; // Tam opaklık
    } else {
      // Kullanılabilir joker - Normal takım rengi
      backgroundColor = teamActiveColor.withOpacity(0.2);
      iconColor = teamActiveColor.withOpacity(0.8);
    }

    return InkWell(
      onTap: canUseJoker && onJokerPressed != null ? () => onJokerPressed!(type) : null,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          border: isActive ? Border.all(color: teamActiveColor, width: 1.5) : null,
          boxShadow: isActive ? [
            BoxShadow(
              color: teamActiveColor.withOpacity(0.4),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ] : null,
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 12, // Daha küçük ikonlar
        ),
      ),
    );
  }
}

// SVG yolunu çizen CustomPainter
class JokerBarPainter extends CustomPainter {
  final bool isOpponent;
  final bool isGreenTeam;  // Takım rengini ekledik
  
  JokerBarPainter({
    this.isOpponent = false,
    required this.isGreenTeam,  // Zorunlu parametre yaptık
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    
    // Her iki takım için de siyah renk kullanıyoruz
    final Color barColor = const Color.fromARGB(255, 0, 0, 0);  // Siyah renk
    
    final paint = Paint()
      ..color = barColor  // Rengi değiştirdik
      ..style = PaintingStyle.fill
      ..strokeWidth = 1;
    
    // Eğer opponent için ise canvas'ı çevir
    if (isOpponent) {
      // Canvas'ı döndür ve yansıt
      canvas.translate(width, height);
      canvas.scale(-1, -1);
    }
    
    // SVG yolunu ölçeklendirerek çiziyoruz
    final path = Path();
    
    // İlk noktalar
    // Ölçekleme faktörü: genişlik için width/413, yükseklik için height/130
    final scaleX = width / 413;
    final scaleY = height / 130;
    
    path.moveTo(35.2774 * scaleX, 11.5794 * scaleY);
    path.cubicTo(
      41.3568 * scaleX, 4.24467 * scaleY,
      50.3881 * scaleX, 0 * scaleY,
      59.9148 * scaleX, 0 * scaleY
    );
    
    // Üst kenar
    path.lineTo(98.75 * scaleX, 0 * scaleY);
    path.lineTo(206.5 * scaleX, 0 * scaleY);
    path.lineTo(314.25 * scaleX, 0 * scaleY);
    path.lineTo(353.085 * scaleX, 0 * scaleY);
    
    path.cubicTo(
      362.612 * scaleX, 0 * scaleY,
      371.643 * scaleX, 4.24466 * scaleY,
      377.723 * scaleX, 11.5794 * scaleY
    );
    
    // Sağ üst eğri
    path.lineTo(405.074 * scaleX, 44.5794 * scaleY);
    
    path.cubicTo(
      414.891 * scaleX, 56.4234 * scaleY,
      414.891 * scaleX, 73.5766 * scaleY,
      405.074 * scaleX, 85.4206 * scaleY
    );
    
    // Sağ alt eğri
    path.lineTo(377.723 * scaleX, 118.421 * scaleY);
    
    path.cubicTo(
      371.643 * scaleX, 125.755 * scaleY,
      362.612 * scaleX, 130 * scaleY,
      353.085 * scaleX, 130 * scaleY
    );
    
    // Alt kenar
    path.lineTo(314.25 * scaleX, 130 * scaleY);
    path.lineTo(206.5 * scaleX, 130 * scaleY);
    path.lineTo(98.75 * scaleX, 130 * scaleY);
    path.lineTo(59.9148 * scaleX, 130 * scaleY);
    
    path.cubicTo(
      50.3881 * scaleX, 130 * scaleY,
      41.3568 * scaleX, 125.755 * scaleY,
      35.2774 * scaleX, 118.421 * scaleY
    );
    
    // Sol alt eğri
    path.lineTo(7.92554 * scaleX, 85.4206 * scaleY);
    
    path.cubicTo(
      -1.89131 * scaleX, 73.5766 * scaleY,
      -1.89132 * scaleX, 56.4234 * scaleY,
      7.92552 * scaleX, 44.5794 * scaleY
    );
    
    // Başlangıç noktasına dön
    path.lineTo(35.2774 * scaleX, 11.5794 * scaleY);
    
    path.close();
    
    // Siyah gölge efekti - her iki takım için aynı
    canvas.drawShadow(
      path, 
      Colors.black,
      4, 
      true
    );
    
    // Ana yolu çiz
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is JokerBarPainter) {
      return oldDelegate.isOpponent != isOpponent || 
             oldDelegate.isGreenTeam != isGreenTeam;
    }
    return true;
  }
}