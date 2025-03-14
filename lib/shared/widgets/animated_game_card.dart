// lib/features/game/widgets/animated_game_card.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:handclash/core/haptic/feedback_service.dart';
import 'package:handclash/features/game/game_enums.dart';

class AnimatedGameCard extends StatefulWidget {
  final double width;
  final double height;
  final String frontCardPath;
  final String backCardPath;
  final bool showFront;
  final bool isSelected;
  final bool isBlocked;
  final GamePhase currentPhase; // Yeni parametre
  final VoidCallback? onTap;

  const AnimatedGameCard({
    Key? key,
    required this.width,
    required this.height,
    required this.frontCardPath,
    required this.backCardPath,
    required this.showFront,
    required this.isSelected,
    required this.isBlocked,
    required this.currentPhase, // Yeni parametre
    this.onTap,
  }) : super(key: key);

  @override
  State<AnimatedGameCard> createState() => _AnimatedGameCardState();
}

class _AnimatedGameCardState extends State<AnimatedGameCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _showFrontSide = true;
  final FeedbackService _feedbackService = FeedbackService.instance;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _animation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: pi / 2)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: pi / 2, end: pi)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(_controller);

    _animation.addListener(() {
      if (_animation.value > pi / 2 && _showFrontSide) {
        setState(() {
          _showFrontSide = false;
        });
      } else if (_animation.value < pi / 2 && !_showFrontSide) {
        setState(() {
          _showFrontSide = true;
        });
      }
    });
    
    // Başlangıçta widget.showFront'a göre kartın gösterilecek tarafını ayarla
    _showFrontSide = widget.showFront;
    if (!widget.showFront) {
      _controller.value = 1.0; // Kart sırtını göster (tam dönmüş durumda)
    } else {
      _controller.value = 0.0; // Ön yüzü göster
    }
  }

@override
void didUpdateWidget(AnimatedGameCard oldWidget) {
  super.didUpdateWidget(oldWidget);
  
  // Kart çevrilme animasyonu için showFront değişikliğini kontrol et
  if (widget.showFront != oldWidget.showFront) {
    if (widget.showFront) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
  }
  
  // selectedMove değeri null olduğunda (yeni round başladığında)
  // isSelected durumunun da güncellenmesini sağla
  if (widget.isSelected != oldWidget.isSelected) {
    setState(() {
      // Seçim durumu değişti, UI'ı güncelle
    });
  }
}

@override
Widget build(BuildContext context) {
  final bool isReallySelected = widget.isSelected;
  return GestureDetector(
    onTap: widget.onTap != null 
        ? () {
            // Titreşim ekle
            _feedbackService.vibrateShort();
            widget.onTap!();
          }
        : null,
    child: AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        // Flip sırasında arka yüzün yansıma sorununu çözen bir transform matrisi
        final transform = Matrix4.identity()
          ..setEntry(3, 2, 0.001) // Perspektif için
          ..rotateY(_animation.value);
        
        return Transform(
          transform: transform,
          alignment: Alignment.center,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: widget.isSelected 
                  ? Border.all(
                      color: Colors.blue,
                      width: 4, // Border kalınlığını arttır (daha belirgin olması için)
                    ) 
                  : null,
              // Ek gölge efekti ekle
              boxShadow: [
                BoxShadow(
                  color: widget.isSelected 
                      ? Colors.blue.withOpacity(0.5) // Seçili kartlar için daha belirgin gölge
                      : Colors.black.withOpacity(0.2),
                  blurRadius: widget.isSelected ? 8 : 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Burada değişikliğe gerek yok
                // Ön veya arka yüz - animasyon değerine göre
                _animation.value <= pi / 2
                    ? Image.asset(
                        widget.frontCardPath,
                        width: widget.width,
                        height: widget.height,
                        fit: BoxFit.fill,
                        errorBuilder: (context, error, stackTrace) {
                          print('Error loading front card image: ${widget.frontCardPath}');
                          return Container(
                            color: Colors.red.withOpacity(0.3),
                            child: const Center(child: Text('❌')),
                          );
                        },
                      )
                    : Transform(
                        transform: Matrix4.identity()
                          ..rotateY(pi), // Arka yüzü doğru yönde göster
                        alignment: Alignment.center,
                        child: Image.asset(
                          widget.backCardPath,
                          width: widget.width,
                          height: widget.height,
                          fit: BoxFit.fill,
                          errorBuilder: (context, error, stackTrace) {
                            print('Error loading back card image: ${widget.backCardPath}');
                            return Container(
                              color: Colors.red.withOpacity(0.3),
                              child: const Center(child: Text('❌')),
                            );
                          },
                        ),
                      ),
                
                // Seçilme durumunu daha belirgin yapmak için bir overlay ekle (opsiyonel)
                if (widget.isSelected)
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.blue.withOpacity(0.7),
                        width: 2,
                      ),
                    ),
                  ),
                  
                // Bloke overlay
                if (widget.isBlocked)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
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
      },
    ),
  );
}}