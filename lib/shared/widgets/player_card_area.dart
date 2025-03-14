// lib/shared/widgets/player_card_area.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:handclash/core/constants/app_colors.dart';
import 'package:handclash/features/game/game_enums.dart';
import 'package:handclash/features/game/game_view_model.dart';
import 'package:handclash/core/haptic/feedback_service.dart';

class PlayerCardArea extends StatefulWidget {  // StatefulWidget yaptık
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
  State<PlayerCardArea> createState() => _PlayerCardAreaState();
}

class _PlayerCardAreaState extends State<PlayerCardArea> {
  // Yerel olarak seçilen hareket
  String? _localSelectedMove;
  
  @override
  void initState() {
    super.initState();
    // Başlangıçta widget'tan gelen değeri ata
    _localSelectedMove = widget.selectedMove;
  }
  
  @override
  void didUpdateWidget(PlayerCardArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Faz değişimlerini kontrol et
    if (widget.currentPhase != oldWidget.currentPhase) {
      // Kart seçim fazına geçildiğinde yerel seçimi sıfırla
      if (widget.currentPhase == GamePhase.cardSelect) {
        setState(() {
          _localSelectedMove = null;
        });
        print("Kart seçim fazına geçildi. Yerel seçim sıfırlandı.");
      }
      
      // Joker fazına geçildiğinde seçili kartı widget'tan al
      else if (widget.currentPhase == GamePhase.jokerSelect) {
        setState(() {
          _localSelectedMove = widget.selectedMove;
        });
        print("Joker fazına geçildi. Yerel seçim: $_localSelectedMove");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        width: MediaQuery.of(context).size.width - 20,
        padding: const EdgeInsets.all(10),
        decoration: ShapeDecoration(
          color: widget.isGreenTeam ? AppColors.greenSecondary : AppColors.redSecondary,
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
            final totalSpacing = (widget.availableMoves.length - 1) * 5;
            final cardWidth = (constraints.maxWidth - totalSpacing) / widget.availableMoves.length;
            final cardHeight = cardWidth * 1.64;

            return SizedBox(
              height: cardHeight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: widget.availableMoves.map((move) {
                  return Padding(
                    padding: EdgeInsets.only(
                      right: move != widget.availableMoves.last ? 5 : 0,
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
    bool isBlocked = widget.blockedMoves.contains(move);
    
    // Kartın yerel olarak seçili olup olmadığını kontrol et
    bool isCurrentMoveSelected = _localSelectedMove == move;
    
    // Kart seçimini gerçekleştirme metodu
    void selectCard() {
      // Titreşimli geri bildirim
      FeedbackService.instance.vibrateShort();
      
      // Yerel seçimi güncelle
      setState(() {
        _localSelectedMove = move;
      });
      
      // Hamleyi viewModel'e ilet
      widget.onMoveSelected(move);
    }
    
    // Ön yüz yolunu belirle
    String frontCardPath;
    String teamFolder = widget.isGreenTeam ? 'green' : 'red';
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
    
    // Kartın ön yüzünü gösterme durumu
    bool shouldShowFront = true;
    
    // Sonuç fazında seçili olmayan kartların arka yüzünü göster
    if ((widget.currentPhase == GamePhase.revealing || widget.currentPhase == GamePhase.roundResult) && 
        widget.selectedMove != move) {
      shouldShowFront = false;
    }
    
    // Kart seçilebilir mi?
    bool canSelectCard = !isBlocked && 
                         (widget.currentPhase == GamePhase.playing || 
                          widget.currentPhase == GamePhase.cardSelect);
    
    // Border'ın görünürlüğü - kart seçme ve joker arasındaki fazlarda
    bool shouldShowBorder = isCurrentMoveSelected && 
                           (widget.currentPhase == GamePhase.cardSelect || 
                            widget.currentPhase == GamePhase.playing ||
                            widget.currentPhase == GamePhase.revealing ||
                            widget.currentPhase == GamePhase.roundResult);
    
    return GestureDetector(
      onTap: canSelectCard ? selectCard : null,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: shouldShowBorder 
              ? Border.all(
                  color: Colors.blue,
                  width: 3,
                ) 
              : null,
          boxShadow: [
            BoxShadow(
              color: shouldShowBorder 
                  ? Colors.blue.withOpacity(0.5) 
                  : Colors.black.withOpacity(0.2),
              blurRadius: shouldShowBorder ? 8 : 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Ön veya arka yüz
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                shouldShowFront ? frontCardPath : backCardPath,
                width: width,
                height: height,
                fit: BoxFit.fill,
                errorBuilder: (context, error, stackTrace) {
                  print('Error loading card image: ${shouldShowFront ? frontCardPath : backCardPath}');
                  return Container(
                    color: Colors.red.withOpacity(0.3),
                    child: const Center(child: Text('❌')),
                  );
                },
              ),
            ),
            
            // Seçim göstergesi
            if (shouldShowBorder)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            
            // Bloke overlay
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
}