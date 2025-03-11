// lib/features/game/widgets/joker_menu.dart
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:handclash/features/game/game_enums.dart';
import 'package:handclash/features/game/game_view_model.dart';

class JokerMenu extends StatefulWidget {
  final GameViewModel viewModel;
  final JokerType? preSelectedJoker;
  final Function(BuildContext) onClose;

  const JokerMenu({
    Key? key,
    required this.viewModel,
    this.preSelectedJoker,
    required this.onClose,
  }) : super(key: key);

  @override
  State<JokerMenu> createState() => _JokerMenuState();
}

class _JokerMenuState extends State<JokerMenu> {
  JokerType? _selectedJoker;
  bool _isClosing = false;

  @override
  void initState() {
    super.initState();
    // Önceden seçilmiş bir joker varsa onu kullan
    _selectedJoker = widget.viewModel.state.selectedJoker != JokerType.none
        ? widget.viewModel.state.selectedJoker
        : widget.preSelectedJoker;
  }

  void _selectJoker(JokerType type) {
    if (_isClosing) return;

    setState(() {
      _selectedJoker = type;
    });

    // Önce jokeri seç
    widget.viewModel.useJoker(type);

    // Kısa bir gecikmeyle menüyü kapat - kullanıcı seçimini görsün
    _isClosing = true;
    Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        widget.onClose(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Ekranın boyutlarını al
    final size = MediaQuery.of(context).size;
    
    // Kartların genişliği - boşluklar düşünülerek hesapla
    final cardWidth = (size.width - 48) / 3; // 12 margin x 2 + 8 spacing x 2
    
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.9),
              const Color(0xFF2C0E37).withOpacity(0.95), // Koyu mor
            ],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Başlık ve Kapat Butonu - Sabit padding ile
              Padding(
                padding: const EdgeInsets.only(left: 12, right: 12, top: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Başlık
                    const Text(
                      'Joker Seç',
                      style: TextStyle(
                        fontSize: 24, 
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    
                    // Kapat butonu
                    GestureDetector(
                      onTap: () => widget.onClose(context),
                      behavior: HitTestBehavior.opaque,
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Joker Kartları - Aynı yükseklikte kutular
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: IntrinsicHeight(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildJokerOption(
                        context,
                        JokerType.block,
                        'Blok',
                        'assets/card/joker/block.png',
                        'Rakibin 2 kartını blokla\n(Sonraki el için)',
                        widget.viewModel,
                        cardWidth: cardWidth,
                      ),
                      const SizedBox(width: 8),
                      _buildJokerOption(
                        context,
                        JokerType.blind,
                        'Kanca',
                        'assets/card/joker/hook.png',
                        'Rakibin yaptığı hamleyi blokla\n(Sonraki el için)',
                        widget.viewModel,
                        cardWidth: cardWidth,
                      ),
                      const SizedBox(width: 8),
                      _buildJokerOption(
                        context,
                        JokerType.bet,
                        'Bahis',
                        'assets/card/joker/bet.png',
                        'Bahsi 2\'ye katla\n(Oyun sonuna kadar)',
                        widget.viewModel,
                        cardWidth: cardWidth,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20), // Alt kısımdaki boşluğu artırdık
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJokerOption(
    BuildContext context,
    JokerType type,
    String label,
    String imagePath,
    String description,
    GameViewModel viewModel, {
    required double cardWidth,
  }) {
    // Jokerin kullanılabilir olup olmadığını kontrol et
    bool hasAvailable = viewModel.state.getJokerCount(type) > 0;
    bool isUsed = viewModel.state.usedJokers.contains(type);
    
    // Local state'deki seçimi kontrol et
    bool isSelected = _selectedJoker == type;
    
    // Joker kullanılabilir mi kontrolü
    bool isDisabled = !hasAvailable || isUsed;
    
    // İnteraksiyon için - isDisabled true olsa bile tıklanabilir olmalı, sadece işlev görmemeli
    bool canSelect = hasAvailable && !isUsed && !_isClosing;
    
    // Seçilen kenar rengi
    Color borderColor = isSelected ? Colors.purpleAccent : Colors.purple.withOpacity(0.3);
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (canSelect) {
            _selectJoker(type);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12), // Her tarafta eşit boşluk
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Kart görseli - Sabit genişlik ve yükseklik oranı
                AspectRatio(
                  aspectRatio: 2/3, // Genişlik/Yükseklik oranı - tipik kart oranı
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Kart görseli
                      Opacity(
                        opacity: isDisabled ? 0.5 : 1.0,
                        child: Image.asset(
                          imagePath,
                          fit: BoxFit.contain,
                        ),
                      ),
                      
                      // Devre dışı bırakılmışsa gri overlay ekle
                      if (isDisabled)
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.black.withOpacity(0.4),
                          ),
                        ),
                        
                      // Aktif olduğunda sadece çerçeve ekle
                      if (isSelected)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.purpleAccent,
                              width: 2,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Joker adı
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.purpleAccent : Colors.white,
                  ),
                ),
                
                const SizedBox(height: 4),
                
                // Joker açıklaması
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white70,
                  ),
                ),
                
                const SizedBox(height: 10), // Daha fazla boşluk
                
                // Kalan joker sayısı
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Kalan: ${viewModel.state.getJokerCount(type)}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.purpleAccent : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}