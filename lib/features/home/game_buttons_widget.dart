import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:handclash/core/constants/app_constants.dart';

class GameButtonsWidget extends StatefulWidget {
  final String gameType;
  final bool isGameAvailable;
  final Function(String gameType, int targetScore, int betAmount, bool isAIGame)
  onStartGame; // isAIGame parametresi eklendi
  final Map<String, dynamic>? userData;

  const GameButtonsWidget({
    Key? key,
    required this.gameType,
    required this.isGameAvailable,
    required this.onStartGame,
    this.userData,
  }) : super(key: key);

  @override
  State<GameButtonsWidget> createState() => _GameButtonsWidgetState();
}

class _GameButtonsWidgetState extends State<GameButtonsWidget> {
  // Maksimum bahis kullanılsın mı?
  bool _useMaxBet = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.isGameAvailable) {
      return _buildComingSoonButton(context);
    }

    return Center(child: _buildPlayButton(context));
  }

  Widget _buildPlayButton(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return InkWell(
      onTap: () {
        _showGameOptionsDialog(context);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 12,
            sigmaY: 12,
          ), // Blur efekti arttırıldı
          child: Container(
            width: screenWidth * 0.7, // Card genişliği ile aynı
            // PADDING: Ana buton iç padding - 16 dikey, 24 yatay
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF8F939), // Sarı renk
                  Color(0xFF76CA58), // Yeşil renk
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'PLAY NOW',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18, // Font boyutu büyütüldü
                  fontWeight: FontWeight.w600, // Daha kalın font
                  letterSpacing: 1, // Harfler arası mesafe arttırıldı
                  color:
                      Colors
                          .black87, // Sarı-yeşil üzerine siyah metin daha okunur
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showGameOptionsDialog(BuildContext context) {
    // Kullanıcının mevcut ligi
    final String userLeague =
        widget.userData?['current_league'] ?? AppConstants.defaultLeague;

    // Kullanıcının mevcut altını
    final int userGold = widget.userData?['current_gold'] ?? 0;

    // Lig bilgileri
    final Map<String, dynamic> leagueInfo =
        AppConstants.leagueLimits[userLeague]!;

    // Min ve max bahis
    final int minBet = leagueInfo['min_bet'];
    final int maxBet = leagueInfo['max_bet'];
    final int aiBet = leagueInfo['ai_bet'];

    // Bahis seçimi için başlangıç değeri
    bool maxBetSelected = _useMaxBet;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Geçerli bahis değeri
            final int currentBet = maxBetSelected ? maxBet : minBet;
            final int currentAiBet = maxBetSelected ? maxBet : aiBet;

            return Stack(
              children: [
                // Ana dialog
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Dialog(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    insetPadding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.2),
                            Colors.grey.shade600.withOpacity(0.3),
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 0.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Başlık ve Switch
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 10,
                              left: 20,
                              right: 10,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'OYUN ŞEKLİ SEÇ',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      maxBetSelected
                                          ? 'Max Bahis'
                                          : 'Min Bahis',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color:
                                            maxBetSelected
                                                ? Colors.amber
                                                : Colors.white.withOpacity(0.7),
                                      ),
                                    ),
                                    Switch(
                                      value: maxBetSelected,
                                      onChanged: (value) {
                                        setDialogState(() {
                                          maxBetSelected = value;
                                        });
                                      },
                                      activeColor: Colors.amber,
                                      inactiveThumbColor: Colors.grey.shade400,
                                      activeTrackColor: Colors.amber
                                          .withOpacity(0.3),
                                      inactiveTrackColor: Colors.grey
                                          .withOpacity(0.3),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Başlık altına ayırıcı çizgi
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Container(
                              height: 1,
                              width: double.infinity,
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),

                          // Lig bilgisi
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              '$userLeague Ligi: ${minBet}-${maxBet} Gold',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.amber[300],
                              ),
                            ),
                          ),

                          // 3 Zafer Seçeneği (Online)
                          _buildOptionButton(
                            context,
                            '3 Zafer',
                            'Gold: $currentBet',
                            '👥 Çevrimiçi Oyna',
                            () {
                              setState(() {
                                _useMaxBet = maxBetSelected;
                              });
                              Navigator.pop(context);
                              widget.onStartGame(
                                widget.gameType,
                                3,
                                currentBet,
                                false,
                              );
                            },
                            userGold >= currentBet,
                            Colors.teal, // Online mod için teal rengi ekledik
                          ),

                          // 5 Zafer Seçeneği (Online)
                          _buildOptionButton(
                            context,
                            '5 Zafer',
                            'Gold: $currentBet',
                            '👥 Çevrimiçi Oyna',
                            () {
                              setState(() {
                                _useMaxBet = maxBetSelected;
                              });
                              Navigator.pop(context);
                              widget.onStartGame(
                                widget.gameType,
                                5,
                                currentBet,
                                false,
                              );
                            },
                            userGold >= currentBet,
                            Colors.teal, // Online mod için teal rengi ekledik
                          ),

                          const SizedBox(height: 6),

                          // Yapay Zeka Seçeneği (Farklı renk)
                          _buildOptionButton(
                            context,
                            'Yapay Zeka',
                            'Gold: $currentAiBet',
                            '🤖 AI ile Oyna', // AI ikonunu ekledik
                            () {
                              setState(() {
                                _useMaxBet = maxBetSelected;
                              });
                              Navigator.pop(context);
                              widget.onStartGame(
                                widget.gameType,
                                3,
                                currentAiBet,
                                true,
                              ); // isAIGame: true
                            },
                            userGold >= currentAiBet,
                            Colors.indigo, // AI modu için farklı renk
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Popup altındaki çarpı ikonu (aynı kalacak)
                Positioned(
                  bottom: 50,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.2),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildOptionButton(
    BuildContext context,
    String title,
    String subtitle,
    String description, // Açıklama eklendi
    VoidCallback onTap,
    bool canPlay,
    Color? color, // Renk parametresi eklendi (isteğe bağlı)
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: canPlay ? onTap : null,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 1, horizontal: 1),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors:
                  canPlay
                      ? [
                        (color ?? Colors.black).withOpacity(0.6),
                        (color ?? Colors.black).withOpacity(0.4),
                      ]
                      : [
                        Colors.black.withOpacity(0.4),
                        Colors.black.withOpacity(0.2),
                      ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  canPlay
                      ? (color ?? Colors.white).withOpacity(0.3)
                      : Colors.white.withOpacity(0.1),
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Başlık ve alt başlık
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Seçenek başlığı (sol tarafta)
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: canPlay ? Colors.white : Colors.grey,
                    ),
                  ),

                  // Gold miktarı (sağ tarafta)
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          canPlay
                              ? Colors.amber.shade300
                              : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),

              // Açıklama
              if (description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          canPlay
                              ? Colors.white.withOpacity(0.7)
                              : Colors.grey.withOpacity(0.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComingSoonButton(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.7,
      height: 56,
      // MARGIN: Coming Soon buton dış margin - yatay 20
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.grey.shade800.withOpacity(0.8),
                  Colors.grey.shade900.withOpacity(0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.schedule,
                  color: Colors.white.withOpacity(0.7),
                  size: 20,
                ),
                // SPACING: İkon ile metin arası - 8
                const SizedBox(width: 8),
                Text(
                  'COMING SOON',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withOpacity(0.7),
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
