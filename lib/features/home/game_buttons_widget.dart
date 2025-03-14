import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:handclash/core/constants/app_constants.dart';

class GameButtonsWidget extends StatefulWidget {
  final String gameType;
  final bool isGameAvailable;
  final Function(String gameType, int targetScore, int betAmount, bool isAIGame)
      onStartGame;
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
          ),
          child: Container(
            width: screenWidth * 0.7,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF8F939),
                  Color(0xFF76CA58),
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
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showGameOptionsDialog(BuildContext context) {
    final String userLeague =
        widget.userData?['current_league'] ?? AppConstants.defaultLeague;
    final int userGold = widget.userData?['current_gold'] ?? 0;
    final Map<String, dynamic> leagueInfo =
        AppConstants.leagueLimits[userLeague]!;
    final int minBet = leagueInfo['min_bet'];
    final int maxBet = leagueInfo['max_bet'];
    final int aiBet = leagueInfo['ai_bet'];
    bool maxBetSelected = _useMaxBet;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final int currentBet = maxBetSelected ? maxBet : minBet;
            final int currentAiBet = maxBetSelected ? maxBet : aiBet;

            return Stack(
              children: [
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
                          // Lig bilgisi (yeni başlık alanı)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                            margin: const EdgeInsets.fromLTRB(8, 8, 8, 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$userLeague Ligi',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      '${minBet}-${maxBet} Gold',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.amber[300],
                                      ),
                                    ),
                                  ],
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

                          // Yan yana butonlar için Row
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // 3 Zafer butonu
                                Expanded(
                                  child: _buildOptionButton(
                                    context,
                                    '3',
                                    'zafer',
                                    'Gold: $currentBet',
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
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // 5 Zafer butonu
                                Expanded(
                                  child: _buildOptionButton(
                                    context,
                                    '5',
                                    'zafer',
                                    'Gold: $currentBet',
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
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // AI butonu
                                Expanded(
                                  child: _buildOptionButton(
                                    context,
                                    'AI',
                                    'ile oyna',
                                    'Gold: $currentAiBet',
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
                                      );
                                    },
                                    userGold >= currentAiBet,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),

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
    String goldText,
    VoidCallback onTap,
    bool canPlay,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: canPlay ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.white.withOpacity(0.1),
        highlightColor: Colors.white.withOpacity(0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: canPlay ? Colors.white.withOpacity(0.3) : Colors.white.withOpacity(0.1),
              width: 0.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Büyük sayı/yazı
              Text(
                title,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: canPlay ? Colors.white : Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              
              // Alt yazı
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: canPlay ? Colors.white.withOpacity(0.8) : Colors.grey.withOpacity(0.5),
                ),
                textAlign: TextAlign.center,
              ),
              
              // Gold miktarı
              Text(
                goldText,
                style: TextStyle(
                  fontSize: 14,
                  color: canPlay ? Colors.amber.shade300 : Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
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