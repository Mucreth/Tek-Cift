// lib/features/game/widgets/joker_card.dart
import 'package:flutter/material.dart';
import 'package:handclash/features/game/game_enums.dart';

class JokerCard extends StatelessWidget {
  final JokerType type;
  final bool isActive;
  final bool isDisabled;
  final VoidCallback? onTap;
  final double width;
  final double height;

  const JokerCard({
    Key? key,
    required this.type,
    this.isActive = false,
    this.isDisabled = false,
    this.onTap,
    this.width = 80.0,
    this.height = 120.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Joker tipine göre kart görselini belirle
    String imagePath;
    switch (type) {
      case JokerType.block:
        imagePath = 'assets/card/joker/block.png';
        break;
      case JokerType.blind:
        imagePath = 'assets/card/joker/hook.png';
        break;
      case JokerType.bet:
        imagePath = 'assets/card/joker/bet.png';
        break;
      case JokerType.none:
        // Varsayılan joker görüntüsü veya boş kart
        imagePath = 'assets/card/joker/block.png'; // Varsayılan bir görsel
        break;
    }

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(
        width: width,
        height: height,
        margin: const EdgeInsets.symmetric(horizontal: 5.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: isActive ? [
            BoxShadow(
              color: Colors.purple.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ] : null,
        ),
        child: Stack(
          children: [
            // Kart görseli
            Opacity(
              opacity: isDisabled ? 0.5 : 1.0,
              child: Image.asset(
                imagePath,
                width: width,
                height: height,
                fit: BoxFit.contain,
              ),
            ),
            
            // Devre dışı bırakılmışsa gri overlay ekle
            if (isDisabled)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  color: Colors.black.withOpacity(0.3),
                ),
              ),
              
            // Aktif olduğunda parlama efekti
            if (isActive)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(
                    color: Colors.purple,
                    width: 2.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.5),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}