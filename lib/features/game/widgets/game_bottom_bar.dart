// lib/features/game/widgets/game_bottom_bar.dart
import 'package:flutter/material.dart';
import 'package:handclash/core/constants/app_colors.dart';
import 'package:handclash/features/game/game_enums.dart';
import 'package:handclash/features/game/game_view_model.dart';

class GameBottomBar extends StatefulWidget {
  final VoidCallback onSurrenderPressed;
  final VoidCallback onJokerMenuPressed;
  final GameViewModel viewModel;
  
  const GameBottomBar({
    Key? key,
    required this.onSurrenderPressed,
    required this.onJokerMenuPressed,
    required this.viewModel,
  }) : super(key: key);

  @override
  State<GameBottomBar> createState() => _GameBottomBarState();
}

class _GameBottomBarState extends State<GameBottomBar> with SingleTickerProviderStateMixin {
  bool _isEmojiMenuOpen = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleEmojiMenu() {
    setState(() {
      _isEmojiMenuOpen = !_isEmojiMenuOpen;
      if (_isEmojiMenuOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Ana butonlar - Row'un arkaplanı olmayan temiz versiyon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Teslim ol / Bayrak butonu - sadece icon
              IconButton(
                onPressed: widget.onSurrenderPressed,
                icon: Icon(
                  Icons.flag_outlined,
                  color: Colors.red[400],
                  size: 28,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              
              // Joker kullan butonu
              _buildJokerButton(),
              
              // Emoji ikonu ve panel - emoji ikonu artık Stack içinde
              _buildEmojiButtonAndPanel(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJokerButton() {
    bool canUseJoker = widget.viewModel.state.currentPhase == GamePhase.jokerSelect && 
                        widget.viewModel.state.canUseJoker;
    
    // Takım rengine göre aktif joker butonu rengini seç
    Color activeJokerColor = widget.viewModel.state.isGreenTeam
        ? const Color(0xFF3D9970) // Yeşil takım için koyu yeşil
        : const Color(0xFF9D2933); // Kırmızı takım için koyu kırmızı
    
    if (canUseJoker) {
      // Aktif durum - buton görünümünde
      return InkWell(
        onTap: widget.onJokerMenuPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: activeJokerColor.withOpacity(0.7),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Text(
            'Joker Kullan',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    } else {
      // İnaktif durum - sadece text
      return const Text(
        'Joker Kullan',
        style: TextStyle(
          color: Colors.grey,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      );
    }
  }

  // Emoji butonu ve panel - bir arada
  Widget _buildEmojiButtonAndPanel() {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomRight,
      children: [
        // Emoji Butonu - panel açıkken çarpı ikonu
        IconButton(
          onPressed: _toggleEmojiMenu,
          icon: Icon(
            _isEmojiMenuOpen ? Icons.close : Icons.emoji_emotions_outlined,
            color: _isEmojiMenuOpen ? Colors.white : Colors.amber[400],
            size: 28,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        
        // Emoji Panel - animasyonlu
        if (_isEmojiMenuOpen)
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Positioned(
                bottom: 35, // Butonun üzerinde
                right: 0, // Butona hizalı
                child: Opacity(
                  opacity: _animation.value,
                  child: Transform.translate(
                    offset: Offset(0, 20 - (_animation.value * 20)), // Küçük bir yukarı animasyonu
                    child: _buildEmojiPanel(),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildEmojiPanel() {
    // Örnek emojiler - gerçek uygulamada bu kısım sticker ya da emoji paketlerine göre değişecek
    final List<String> emojis = ['😀', '😂', '😍', '🤔', '😎', '👍', '❤️', '🎮', '🎯', '🎲'];
    
    return Container(
      width: 80, // Daha dar
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Üst kısım - başlık
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: const Center(
              child: Text(
                'Emojiler',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          
          // Emoji listesi - dikey
          Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.3, // Ekranın %30'u kadar yükseklik
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: emojis.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    // Emoji seçildiğinde yapılacak işlemler
                    // Örneğin, seçilen emojiyi rakibe gönderme
                    _toggleEmojiMenu(); // Seçim yapıldıktan sonra menüyü kapat
                  },
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        emojis[index],
                        style: const TextStyle(fontSize: 30), // Daha büyük emoji
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}