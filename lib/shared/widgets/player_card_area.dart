// lib/shared/widgets/player_card_area.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:handclash/core/constants/app_colors.dart';
import 'package:handclash/features/game/game_enums.dart';
import 'package:handclash/features/game/game_view_model.dart';
import 'package:handclash/shared/widgets/animated_game_card.dart';

class PlayerCardArea extends StatelessWidget {
  final String playerName; 
  final String? selectedMove;
  final bool isBlindPhase;
  final List<String> availableMoves;
  final List<String> blockedMoves;
  final Function(String) onMoveSelected;
  final GamePhase currentPhase;
  final bool isGreenTeam;
  final bool isPreparationPhase;
  final GameViewModel viewModel;

  const PlayerCardArea({
    Key? key,
    required this.playerName, 
    required this.selectedMove,
    required this.isBlindPhase,
    required this.availableMoves,
    required this.blockedMoves,
    required this.onMoveSelected,
    required this.currentPhase,
    required this.isGreenTeam,
    this.isPreparationPhase = false,
    required this.viewModel,
  }) : super(key: key);

 @override
Widget build(BuildContext context) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 10),
    child: Container(
      width: MediaQuery.of(context).size.width - 20,
      padding: const EdgeInsets.all(10),
      decoration: ShapeDecoration(
        color: isGreenTeam ? AppColors.greenSecondary : AppColors.redSecondary,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(0),
            bottomRight: Radius.circular(0),
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalSpacing = (availableMoves.length - 1) * 5;
          final cardWidth = (constraints.maxWidth - totalSpacing) / availableMoves.length;
          final cardHeight = cardWidth * 1.64;

          return SizedBox(
            height: cardHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: availableMoves.map((move) {
                return Padding(
                  padding: EdgeInsets.only(
                    right: move != availableMoves.last ? 5 : 0,
                  ),
                  child: _buildCard(move, cardWidth, cardHeight),
                );
              }).toList(),
            ),
          );
        }
      ),
    ),
  );
}

  Widget _buildCard(String move, double width, double height) {
    bool isBlocked = blockedMoves.contains(move);
    
    // Seçilme durumunu kontrol et - kartın seçili olup olmadığını belirle
    bool isSelected = selectedMove == move;
    
    // Dikkat: Tüm fazlarda seçili kartın borderi görünmeli
    
    // Ön yüz yolunu belirle
    String frontCardPath;
    String teamFolder = isGreenTeam ? 'green' : 'red';
    switch (move) {
      case 'rock':
        frontCardPath = 'assets/card/$teamFolder/${teamFolder}_front_rock.png';
        break;
      case 'paper':
        frontCardPath = 'assets/card/$teamFolder/${teamFolder}_front_paper.png';
        break;
      case 'scissors':
        frontCardPath = 'assets/card/$teamFolder/${teamFolder}_front_sci.png';
        break;
      default:
        frontCardPath = 'assets/card/$teamFolder/${teamFolder}_front_$move.png';
    }
    
    String backCardPath = 'assets/card/$teamFolder/${teamFolder}_back.png';
    
    // Kartın ne zaman ön yüzünü göstereceğini belirleme
    bool shouldShowFront = true;
    
    // Açılma veya sonuç fazlarında ve seçili değilse arka yüzü göster
    if ((currentPhase == GamePhase.revealing || currentPhase == GamePhase.roundResult) && !isSelected) {
      shouldShowFront = false;
    }
    
    // Kart seçilebilir mi?
    bool canSelectCard = !isBlocked && 
                        (currentPhase == GamePhase.playing || 
                         currentPhase == GamePhase.cardSelect);
    
    return AnimatedGameCard(
      width: width,
      height: height,
      frontCardPath: frontCardPath,
      backCardPath: backCardPath,
      showFront: shouldShowFront,
      isSelected: isSelected,
      isBlocked: isBlocked,
      onTap: !canSelectCard 
          ? null 
          : () {
              // Hamleyi kaydet ve sunucuya gönder
              onMoveSelected(move);
            },
    );
  }
}