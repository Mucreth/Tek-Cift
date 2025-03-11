// lib/features/game/widgets/game_top_bar.dart
import 'package:flutter/material.dart';

class GameTopBar extends StatelessWidget {
  final VoidCallback? onLeftButtonPressed;
  final VoidCallback? onRightButtonPressed;
  final IconData leftIcon;
  final IconData rightIcon;
  final double height;

  const GameTopBar({
    Key? key,
    this.onLeftButtonPressed,
    this.onRightButtonPressed,
    this.leftIcon = Icons.arrow_back,
    this.rightIcon = Icons.settings,
    this.height = 50,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Sol buton
          IconButton(
            onPressed: onLeftButtonPressed,
            icon: Icon(
              leftIcon,
              color: Colors.white,
              size: 24,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            splashRadius: 24,
          ),
          
          // Ortada logo
          Expanded(
            child: Center(
              child: Image.asset(
                'assets/images/logo.png',
                height: height * 0.7, // Yüksekliğin %70'i
                fit: BoxFit.contain,
              ),
            ),
          ),
          
          // Sağ buton
          IconButton(
            onPressed: onRightButtonPressed,
            icon: Icon(
              rightIcon,
              color: Colors.white,
              size: 24,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            splashRadius: 24,
          ),
        ],
      ),
    );
  }
}