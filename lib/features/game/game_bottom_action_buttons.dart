// lib/features/game/widgets/game_action_buttons.dart - Düzeltme
// Oyuncu için takım rengine göre panel rengi değişimi

import 'package:flutter/material.dart';
import 'package:handclash/core/constants/app_colors.dart';
import 'package:handclash/features/game/game_enums.dart';
import 'package:handclash/features/game/game_view_model.dart';

class GameActionButtons extends StatelessWidget {
  final GameViewModel viewModel;
  final String playerName;
  final String winRate;
  final Function() onSurrenderPressed;
  final Function() onJokerMenuPressed;
  final Function()? onEmotePressed;

  const GameActionButtons({
    Key? key,
    required this.viewModel,
    required this.playerName,
    required this.winRate,
    required this.onSurrenderPressed,
    required this.onJokerMenuPressed,
    this.onEmotePressed,
  }) : super(key: key);

  // Joker color constants
  static const Color jokerActiveBase = Color(0xFF9872DA); // Purple shade
  static const Color jokerInactiveBase = Color(0xFF181F49); // Dark blue shade
  
  @override
  Widget build(BuildContext context) {
    // Takım rengine göre arkaplan ve metin panel renkleri
    final Color backgroundColor = viewModel.state.isGreenTeam 
        ? AppColors.greenSecondary 
        : AppColors.redSecondary;
    
    final Color infoPanelColor = viewModel.state.isGreenTeam
        ? const Color(0xFF192418) // Yeşil takım için koyu yeşil
        : const Color(0xFF241818); // Kırmızı takım için koyu kırmızı
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      decoration: ShapeDecoration(
        color: backgroundColor, // Dinamik renk kullanımı
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(0),
            topRight: Radius.circular(0),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          // Player info container - now at the bottom
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: ShapeDecoration(
              color: infoPanelColor, // Dinamik renk kullanımı
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  playerName,
                  style: const TextStyle(
                    color: Color(0xFFF5F5B7),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1,
                  ),
                ),
                Text(
                  'Win Rate: $winRate',
                  style: const TextStyle(
                    color: Color(0xFFF5F5B7),
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build action buttons (surrender and emote)
  Widget _buildActionButton({
    required Function()? onPressed,
    IconData? icon,
    Color? iconColor,
    String? label,
    Color? textColor,
    required double width,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        width: width,
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Center(
          child: icon != null
              ? Icon(
                  icon,
                  color: iconColor ?? Colors.white,
                  size: 28,
                )
              : Text(
                  label ?? "",
                  style: TextStyle(
                    color: textColor ?? Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }

  // Helper method to build joker buttons
  Widget _buildJokerButton(
    JokerType type,
    IconData icon,
    Color baseColor,
    String tooltip,
  ) {
    final int count = viewModel.state.getJokerCount(type);
    final bool isUsed = viewModel.state.usedJokers.contains(type);
    final bool isActive = viewModel.state.selectedJoker == type;
    final bool canUseJoker = viewModel.state.currentPhase == GamePhase.jokerSelect && 
                            viewModel.state.canUseJoker &&
                            count > 0 && 
                            !isUsed;
    
    // Determine the background color based on joker state - enhanced visibility
    Color backgroundColor;
    Color borderColor;
    Color iconColor;
    
    if (isUsed || count <= 0) {
      // Inactive/used joker
      backgroundColor = jokerInactiveBase.withOpacity(0.5); // More visible
      borderColor = jokerInactiveBase;
      iconColor = Colors.grey;
    } else if (isActive) {
      // Active joker
      backgroundColor = jokerActiveBase.withOpacity(0.6); // More visible
      borderColor = jokerActiveBase;
      iconColor = Colors.white; // Better contrast
    } else if (canUseJoker) {
      // Available joker
      backgroundColor = jokerActiveBase.withOpacity(0.4); // More visible
      borderColor = jokerActiveBase.withOpacity(0.7);
      iconColor = Colors.white; // Better contrast
    } else {
      // Joker not usable now
      backgroundColor = jokerInactiveBase.withOpacity(0.4); // More visible
      borderColor = jokerInactiveBase.withOpacity(0.7);
      iconColor = Colors.white.withOpacity(0.7); // Better contrast
    }

    return InkWell(
      onTap: canUseJoker ? () => _onJokerSelected(type) : null,
      child: Tooltip(
        message: tooltip,
        child: Container(
          width: 65, // Slightly wider for better appearance
          height: 50, // Same height as other buttons
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(15), // Same as other buttons
            border: Border.all(
              color: borderColor,
              width: isActive ? 2 : 1,
            ),
            boxShadow: isActive ? [
              BoxShadow(
                color: baseColor.withOpacity(0.4),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ] : null,
          ),
          child: Center(
            child: Icon(
              icon,
              color: iconColor,
              size: 24, // Slightly larger
            ),
          ),
        ),
      ),
    );
  }

  // Handle joker selection
  void _onJokerSelected(JokerType type) {
    // Show the joker menu or directly use the joker
    onJokerMenuPressed();
    
    // Ideally, this would directly trigger the joker selection
    // viewModel.useJoker(type);
    
    // For now, just showing the menu which will then handle joker selection
  }
}