// lib/features/game/widgets/game_move_button.dart
import 'package:flutter/material.dart';

class GameMoveButton extends StatelessWidget {
  final String move;
  final String label;
  final bool isBlocked;
  final bool isSelected;
  final bool isActive;
  final Function(String) onTap;

  const GameMoveButton({
    Key? key,
    required this.move,
    required this.label,
    required this.isBlocked,
    required this.isSelected,
    required this.isActive,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isActive && !isBlocked ? () => onTap(move) : null,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: isBlocked 
              ? Colors.grey[300] 
              : isSelected 
                  ? Colors.blue[100] 
                  : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isBlocked 
                ? Colors.grey 
                : isSelected 
                    ? Colors.blue 
                    : Colors.grey[300]!,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildMoveIcon(),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: isBlocked ? Colors.grey : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (isBlocked)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Icon(
                    Icons.block,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoveIcon() {
    IconData icon;
    switch (move) {
      case 'rock':
        icon = Icons.circle_outlined;
        break;
      case 'paper':
        icon = Icons.note;
        break;
      case 'scissors':
        icon = Icons.content_cut;
        break;
      case 'odd':
        icon = Icons.looks_one;
        break;
      case 'even':
        icon = Icons.looks_two;
        break;
      default:
        icon = Icons.question_mark;
    }
    return Icon(
      icon,
      size: 40,
      color: isBlocked ? Colors.grey : Colors.grey[700],
    );
  }
}