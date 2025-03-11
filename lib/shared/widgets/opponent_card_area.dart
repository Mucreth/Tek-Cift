// lib/features/game/widgets/opponent_card_area.dart
import 'package:flutter/material.dart';
import 'package:handclash/core/constants/app_colors.dart';
import 'package:handclash/features/game/game_enums.dart';
import 'package:handclash/shared/widgets/animated_game_card.dart';

class OpponentCardArea extends StatelessWidget {
  final String playerName; // Will be shown in GameActionBar
  final String? selectedMove;
  final bool isBlindPhase;
  final List<String> availableMoves;
  final List<String> blockedMoves;
  final GamePhase currentPhase;
  final bool isGreenTeam;

  const OpponentCardArea({
    Key? key,
    required this.playerName, // Still needed for reference
    required this.selectedMove,
    required this.isBlindPhase,
    required this.availableMoves,
    required this.blockedMoves,
    required this.currentPhase,
    required this.isGreenTeam,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        width: MediaQuery.of(context).size.width - 20,
        padding: const EdgeInsets.all(10),
        decoration: ShapeDecoration(
          // Rengi isGreenTeam durumuna göre değiştiriyoruz
          color: isGreenTeam ? AppColors.greenSecondary : AppColors.redSecondary,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(00),
              topRight: Radius.circular(0),
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final totalSpacing = (availableMoves.length - 1) * 5;
            final cardWidth =
                (constraints.maxWidth - totalSpacing) / availableMoves.length;
            final cardHeight = cardWidth * 1.64;

            return SizedBox(
              height: cardHeight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children:
                    availableMoves.map((move) {
                      return Padding(
                        padding: EdgeInsets.only(
                          right: move != availableMoves.last ? 5 : 0,
                        ),
                        child: _buildCard(move, cardWidth, cardHeight),
                      );
                    }).toList(),
              ),
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildCard(String move, double width, double height) {
    bool isCurrentMove = selectedMove == move;
    
    // Rakip her zaman oyuncunun zıt rengi olmalı
    // Eğer oyuncu yeşilse rakip kırmızı, oyuncu kırmızıysa rakip yeşil
    String teamFolder = !isGreenTeam ? 'red' : 'green';

    // Ön yüz yolunu hesapla
    String frontCardPath;
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
    
    // Arka yüz her zaman aynı
    String backCardPath = 'assets/card/$teamFolder/${teamFolder}_back.png';
    
    // Kartın ne zaman açık gösterileceğini belirleme mantığı
    bool shouldShowFront = false;
    
    // Revealing ve roundResult fazlarında sadece seçili kartı göster
    if ((currentPhase == GamePhase.revealing || currentPhase == GamePhase.roundResult) && isCurrentMove) {
      shouldShowFront = true;
    }
    
    // Sadece mevcut round sonuçlanırken seçili göster, diğer durumlarda border gösterme
    bool showSelected = isCurrentMove && 
                       (currentPhase == GamePhase.revealing || 
                        currentPhase == GamePhase.roundResult);
    
    return AnimatedGameCard(
      width: width,
      height: height,
      frontCardPath: frontCardPath,
      backCardPath: backCardPath,
      showFront: shouldShowFront,
      isSelected: showSelected, // Sadece revealing ve roundResult fazlarında seçili göster
      isBlocked: false,
      onTap: null, // Rakip kartlarına tıklanamaz
    );
  }
}