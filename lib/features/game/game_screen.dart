// lib/features/game/view/game_screen.dart - Yeni PlayerCardArea kullanımı ve sadeleştirilmiş GameActionButtons
// GameScreen.dart - Import bölümü
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:handclash/core/constants/app_colors.dart';
import 'package:handclash/features/auth/auth_service.dart';
import 'package:handclash/features/game/game_action_bar.dart';
// Çakışan importları çöz - bir tanesini saklayarak
import 'package:handclash/features/game/game_bottom_action_buttons.dart'
    hide PlayerCardArea;

import 'package:handclash/features/game/game_enums.dart';
import 'package:handclash/features/game/game_view_model.dart';
import 'package:handclash/features/game/user_info_model.dart';
import 'package:handclash/features/game/widgets/game_bottom_bar.dart';
import 'package:handclash/features/game/widgets/game_top_bar.dart';
import 'package:handclash/features/game/widgets/joker_bar.dart';
import 'package:handclash/features/game/widgets/joker_menu.dart';
import 'package:handclash/features/game/widgets/matchmaking_dialog.dart';
import 'package:handclash/features/home/home_screen.dart';
import 'package:handclash/shared/services/socket_service.dart';
import 'package:handclash/shared/widgets/opponent_card_area.dart';
import 'package:handclash/shared/widgets/player_card_area.dart';
import 'package:provider/provider.dart';

class GameScreen extends StatefulWidget {
  final String gameType;
  final int betAmount;
  final int targetScore;
  final bool isAIGame;

  const GameScreen({
    super.key,
    required this.gameType,
    required this.betAmount,
    required this.targetScore,
    this.isAIGame = false,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameViewModel _viewModel;
  UserInfo? currentUser;
  UserInfo? opponent;
  bool _isLoading = false; // Doğru yer burası - State sınıfı içinde

  @override
  void initState() {
    super.initState();
    // İsAIGame parametresini ViewMode'a iletiyoruz
    _viewModel = GameViewModel(
      targetScore: widget.targetScore,
      gameType: widget.gameType,
      isGreenTeam: true, // AI modunda oyuncu her zaman yeşil takım olacak
      betAmount: widget.betAmount,
      isAIGame: widget.isAIGame, // isAIGame parametresini ilettik
    );

    // Oyun sonu eventi için dinleyici ekle
    _viewModel.onGameEnd = (data) {
      bool isWinner = data['isWinner'] ?? false;
      String? message = data['message'];
      int? goldWon = data['goldWon'];

      // Oyun sonu dialogunu göster
      _showGameOverDialog(isWinner, message, goldWon);
    };

    _setupGame();

    // AI modunda eşleşme popup'ı göstermeyiz
    if (!widget.isAIGame) {
      // Eşleşme popup'ını göster
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showMatchmakingPopup();
      });
    }
  }

  void _showMatchmakingPopup() {
    if (widget.isAIGame) return; // AI modunda gösterme

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return MatchmakingDialog(
          viewModel: _viewModel,
          betAmount: widget.betAmount,
        );
      },
    );
  }

  Future<void> _setupGame() async {
    try {
      // Mevcut kullanıcı bilgilerini al
      final userData = await AuthService().getCurrentUser();
      if (userData != null) {
        // Win rate'i doğru formatlayalım
        String formattedWinRate;

        if (userData.containsKey('win_rate')) {
          // Önce sayısal değere dönüştürüp sonra formatlayalım
          double winRateValue = 0.0;

          if (userData['win_rate'] is double) {
            winRateValue = userData['win_rate'];
          } else if (userData['win_rate'] is int) {
            winRateValue = (userData['win_rate'] as int).toDouble();
          } else {
            // String'den double'a çevirmeyi dene
            winRateValue =
                double.tryParse(
                  userData['win_rate'].toString().replaceAll(',', '.'),
                ) ??
                0.0;
          }

          // Formatla: 1 decimal basamaklı ve % işareti
          formattedWinRate = '${winRateValue.toStringAsFixed(1)}%';
        } else {
          formattedWinRate = '0.0%';
        }

        setState(() {
          currentUser = UserInfo(
            userId: userData['user_id'],
            nickname: userData['nickname'],
            winRate: formattedWinRate, // Formatlanmış win rate kullan
            isGreenTeam: true, // Başlangıç değeri, sonradan güncellenecek
          );
        });
      }

      // AI modunda rakip bilgilerini manuel olarak oluştur
      if (widget.isAIGame) {
        setState(() {
          // AI rakibi oluştur
          opponent = UserInfo(
            userId: 'ai',
            nickname: 'AI Rakip',
            winRate: '50.0%', // Formatlanmış değer
            isGreenTeam: false, // AI her zaman kırmızı takım
          );
        });

        // AI oyununu doğrudan başlat
        _viewModel.startGame();
        return;
      }

      // Çevrimiçi modda devam et
      _viewModel.onOpponentFound = (opponentData) {
        final isGreenTeam = _viewModel.state.isGreenTeam;
        print("Gelen rakip verileri: $opponentData"); // Debug için

        setState(() {
          // UserInfo'yu güncelle - artık isGreenTeam değeri doğru
          if (currentUser != null) {
            currentUser = currentUser!.copyWith(isGreenTeam: isGreenTeam);
          }

          // Rakip her zaman farklı renktedir
          opponent = UserInfo.fromJson(opponentData, isGreenTeam: !isGreenTeam);
          print(
            "İşlenmiş rakip: ${opponent?.nickname}, ${opponent?.winRate}",
          ); // Debug için
        });
      };

      _viewModel.startGame();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Oyun başlatma hatası: $e')));
      }
    }
  }

  // GameScreen sınıfına eklenecek metod
  Widget _buildBlurredBackground(GameViewModel viewModel) {
    // Takım rengine göre arka plan resmi seç
    String assetPath;

    // viewModel.state.isGreenTeam true ise yeşil takım, false ise kırmızı takım
    if (viewModel.state.isGreenTeam) {
      assetPath = 'assets/images/green.png'; // Yeşil takım için
    } else {
      assetPath = 'assets/images/red.png'; // Kırmızı takım için
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        image: DecorationImage(
          image: AssetImage(assetPath),
          fit: BoxFit.cover,
          opacity: 0.7, // Resim opaklığı
        ),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 60.0,
          sigmaY: 60.0,
        ), // Bulanıklık efekti
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2), // Hafif karartma
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.2), // Üst kısımdaki siyahlık
                Colors.black.withOpacity(0.4), // Alt kısımdaki siyahlık
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<GameViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            body: Stack(
              children: [
                // Bulanık arka plan
                _buildBlurredBackground(viewModel),

                // Ana içerik
                SafeArea(
                  child: Column(
                    children: [
                      // Top Bar - Ayrı bir widget olarak
                      GameTopBar(
                        onLeftButtonPressed: () {
                          // Geri dönüş veya istenen bir aksiyon
                          _showSurrenderDialog(context);
                        },
                        onRightButtonPressed: () {
                          // Ayarlar veya başka bir aksiyon
                        },
                        leftIcon: Icons.close,
                        rightIcon: Icons.info_outline,
                      ),

                      const SizedBox(height: 10),

                      // Opponent's Action Bar and Info
                      GameActionBar(
                        playerName: opponent?.nickname ?? 'Rakip',
                        winRate: opponent?.winRate ?? '0%',
                        blockJokerCount: viewModel.state.getJokerCount(
                          JokerType.block,
                        ),
                        blindJokerCount: viewModel.state.getJokerCount(
                          JokerType.blind,
                        ),
                        betJokerCount: viewModel.state.getJokerCount(
                          JokerType.bet,
                        ),
                        usedJokers: viewModel.state.usedJokers,
                        activeJoker: viewModel.state.opponentJoker,
                        isGreenTeam:
                            !viewModel
                                .state
                                .isGreenTeam, // Rakibin rengi, oyuncunun tersi olmalı
                        onAddFriend: () {
                          // Arkadaş ekleme fonksiyonu
                        },
                        onChat: null, // Chat henüz aktif değil
                      ),

                      // Opponent Cards Area ve Joker Bar - Stack ile üst üste konumlandırılıyor
                      Stack(
                        clipBehavior: Clip.none, // Taşma olabilmesi için
                        alignment: Alignment.bottomCenter,
                        children: [
                          // Opponent Cards Area
                          OpponentCardArea(
                            playerName: opponent?.nickname ?? 'Rakip',
                            selectedMove: viewModel.state.opponentMove,
                            isBlindPhase: viewModel.state.isBlindPhase,
                            availableMoves:
                                widget.gameType == 'rps'
                                    ? ['rock', 'paper', 'scissors']
                                    : ['odd', 'even'],
                            blockedMoves: viewModel.state.blockedMoves,
                            currentPhase: viewModel.state.currentPhase,
                            isGreenTeam:
                                !viewModel
                                    .state
                                    .isGreenTeam, // DÜZELTİLDİ: Oyuncunun tam tersi renk olmalı
                          ),

                          // Opponent Joker Bar için de aynı değişiklik yapılmalı
                          Positioned(
                            bottom: -18.9, // Yüksekliğin yarısı
                            child: JokerBar(
                              viewModel: viewModel,
                              width: 120,
                              isOpponent:
                                  true, // Opponent joker barı olduğunu belirt
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Scoreboard
                      _buildScoreBoard(viewModel),

                      const SizedBox(height: 10),

                      // Player Joker Bar ve Player Card Area bölgesi
                      Stack(
                        clipBehavior: Clip.none, // Taşma olabilmesi için
                        alignment: Alignment.topCenter,
                        children: [
                          // Player Cards Area
                          PlayerCardArea(
                            playerName: currentUser?.nickname ?? 'OYUNCU',
                            selectedMove:
                                viewModel
                                    .state
                                    .selectedMove, // Bu değer doğru aktarılıyor mu?
                            isBlindPhase: viewModel.state.isBlindPhase,
                            availableMoves:
                                widget.gameType == 'rps'
                                    ? ['rock', 'paper', 'scissors']
                                    : ['odd', 'even'],
                            blockedMoves: viewModel.state.blockedMoves,
                            onMoveSelected: viewModel.makeMove,
                            currentPhase: viewModel.state.currentPhase,
                            isGreenTeam: viewModel.state.isGreenTeam,
                            isPreparationPhase:
                                viewModel.state.currentPhase ==
                                GamePhase.preparation,
                            viewModel: viewModel,
                          ),

                          // Player Joker Bar - Üstte konumlandırıldı
                          Positioned(
                            top: -18.9,
                            child: JokerBar(
                              viewModel: viewModel,
                              width: 120,
                              isOpponent: false, // Oyuncu joker barı
                              onJokerPressed: (type) {
                                // Tıklanan jokere göre joker menüsünü göster
                                _showJokerMenu(
                                  viewModel,
                                  preSelectedJoker: type,
                                );
                              },
                            ),
                          ),
                        ],
                      ),

                      // GameActionButtons
                      GameActionButtons(
                        viewModel: viewModel,
                        playerName: currentUser?.nickname ?? 'Sen',
                        winRate: currentUser?.winRate ?? '0%',
                        onSurrenderPressed: () => _showSurrenderDialog(context),
                        onJokerMenuPressed: () => _showJokerMenu(viewModel),
                        onEmotePressed: () {
                          // Emote menüsünü göster
                        },
                      ),

                      const SizedBox(height: 10),
                      GameBottomBar(
                        onSurrenderPressed: () => _showSurrenderDialog(context),
                        onJokerMenuPressed: () => _showJokerMenu(viewModel),
                        viewModel: viewModel,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildScoreBoard(GameViewModel viewModel) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      decoration: ShapeDecoration(
        // Arkaplan rengini kaldırdık - saydam olacak
        color: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Opponent Score - Rakip puanı
          Text(
            viewModel.state.opponentScore.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              // Kırmızı/yeşil takım kontrolü - Rakibin rengi, oyuncunun tersi olmalı
              color: viewModel.state.isGreenTeam ? Colors.red : Colors.green,
            ),
          ),

          // Status Message - artık sadece Text var, Container yok
          Text(
            viewModel.timerText,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _getStatusColor(
                viewModel.timerStatus,
              ), // Durum rengini saydamlık olmadan uygula
            ),
          ),

          // Player Score - Oyuncu puanı
          Text(
            viewModel.state.playerScore.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: viewModel.state.isGreenTeam ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(TimerStatus status) {
    switch (status) {
      case TimerStatus.preparation:
        return Colors.grey;
      case TimerStatus.cardSelect:
        return Colors.blue;
      case TimerStatus.countdown:
        return Colors.orange;
      case TimerStatus.revealing:
      case TimerStatus.roundResult:
        return Colors.purple;
      case TimerStatus.jokerTime:
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  void _showJokerMenu(GameViewModel viewModel, {JokerType? preSelectedJoker}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      barrierColor: Colors.black.withOpacity(0.4),
      builder:
          (context) => JokerMenu(
            viewModel: viewModel,
            preSelectedJoker: preSelectedJoker,
            onClose: (context) {
              Navigator.pop(context);
            },
          ),
    );
  }

  Widget _buildJokerOption(
    JokerType type,
    String label,
    IconData icon,
    String description,
    GameViewModel viewModel, {
    bool isPreSelected = false,
  }) {
    // Jokerin kullanılabilir olup olmadığını kontrol et
    bool hasAvailable = viewModel.state.getJokerCount(type) > 0;
    bool isUsed = viewModel.state.usedJokers.contains(type);
    bool isActive = viewModel.state.selectedJoker == type || isPreSelected;
    bool isDisabled =
        !hasAvailable ||
        isUsed ||
        viewModel.state.currentPhase != GamePhase.jokerSelect;

    return GestureDetector(
      onTap:
          isDisabled
              ? null
              : () {
                Navigator.pop(context);
                viewModel.useJoker(type);
              },
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              isDisabled
                  ? Colors.grey[100]
                  : isActive
                  ? Colors.purple[100]
                  : Colors.purple[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isDisabled
                    ? Colors.grey[300]!
                    : isActive
                    ? Colors.purple[400]!
                    : Colors.purple[200]!,
            width: isActive ? 2 : 1,
          ),
          boxShadow:
              isActive
                  ? [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                  : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    isDisabled
                        ? Colors.grey[200]
                        : isActive
                        ? Colors.purple[200]
                        : Colors.purple[100],
                shape: BoxShape.circle,
                boxShadow:
                    isActive
                        ? [
                          BoxShadow(
                            color: Colors.purple.withOpacity(0.3),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ]
                        : null,
              ),
              child: Icon(
                icon,
                size: 32,
                color:
                    isDisabled
                        ? Colors.grey[400]
                        : isActive
                        ? Colors.purple[900]
                        : Colors.purple[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color:
                    isDisabled
                        ? Colors.grey[400]
                        : isActive
                        ? Colors.purple[900]
                        : Colors.purple[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color:
                    isDisabled
                        ? Colors.grey[400]
                        : isActive
                        ? Colors.purple[700]
                        : Colors.purple[300],
              ),
            ),
            // Joker sayısını göster
            if (hasAvailable && !isUsed) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Kalan: ${viewModel.state.getJokerCount(type)}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[700],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showSurrenderDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Oyundan Ayrıl'),
          content: const Text(
            'Oyundan ayrılırsanız bahis tutarınızı kaybedeceksiniz. Devam etmek istiyor musunuz?',
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hayır', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                // Dialog'u kapat
                Navigator.pop(context);

                // Sunucuya oyundan çıkış bilgisini gönder
                if (_viewModel.currentGameId != null) {
                  // Eğer oyun.ID varsa sunucuya çıkış bildirimi yap
                  SocketService().emit('game:surrender', {
                    'gameId': _viewModel.currentGameId,
                  });
                }

                // HomeScreen'e doğrudan dönüş
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Evet, Ayrıl',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  // lib/features/game/game_screen.dart

  void _showGameOverDialog(
    bool isWinner,
    String? customMessage,
    int? goldResult,
  ) {
    print(
      "Dialog açılıyor: isWinner=$isWinner, message=$customMessage, goldResult=$goldResult",
    );

    // customMessage yoksa varsayılan mesajı kullan
    final String resultMessage =
        customMessage ??
        (isWinner ? 'Tebrikler! Kazandınız' : 'Maalesef, Kaybettiniz');

    final Color resultColor = isWinner ? Colors.green : Colors.red;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            resultMessage,
            style: TextStyle(color: resultColor, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Gold sonucu
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.monetization_on,
                      color:
                          goldResult != null && goldResult > 0
                              ? Colors.amber
                              : Colors.red,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      goldResult != null
                          ? (goldResult > 0
                              ? '+${goldResult.toString()}'
                              : goldResult.toString())
                          : '0',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color:
                            goldResult != null && goldResult > 0
                                ? Colors.amber
                                : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Skor bilgisi
              Text(
                'Son skor: ${_viewModel.state.playerScore} - ${_viewModel.state.opponentScore}',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          actions: [
            // Tekrar Oyna butonu
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Dialogu kapat
                _startNewGame(); // Yeni oyun başlat
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.blue.withOpacity(0.1),
              ),
              child: const Text(
                'Tekrar Oyna',
                style: TextStyle(color: Colors.blue),
              ),
            ),

            // Ana Sayfaya Dön butonu
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: resultColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Ana Sayfaya Dön',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _startNewGame() {
    // Mevcut bahis ve hedef skoru kullanarak yeni oyun başlatacağız

    // Önceki viewModel'i temizleyelim
    _viewModel.dispose();

    // Yeni oyunu başlatmak için en kolay yol: aynı sayfayı yeniden açmak
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder:
            (context) => GameScreen(
              gameType: widget.gameType,
              betAmount: widget.betAmount,
              targetScore: widget.targetScore,
              isAIGame: widget.isAIGame,
            ),
      ),
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }
}

// Sadeleştirilmiş yeni action buttons bileşeni (jokerler olmadan)
class SimpleActionButtons extends StatelessWidget {
  final String playerName;
  final String winRate;
  final VoidCallback onSurrenderPressed;
  final VoidCallback? onEmotePressed;
  final bool isGreenTeam;

  const SimpleActionButtons({
    Key? key,
    required this.playerName,
    required this.winRate,
    required this.onSurrenderPressed,
    this.onEmotePressed,
    required this.isGreenTeam,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      decoration: ShapeDecoration(
        color: isGreenTeam ? AppColors.greenSecondary : AppColors.redSecondary,
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
          // İki buton (teslim ol ve emote) yan yana
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Teslim ol / Bayrak butonu
              Expanded(
                child: InkWell(
                  onTap: onSurrenderPressed,
                  child: Container(
                    height: 50,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.flag_outlined,
                            color: Colors.red[400],
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Teslim Ol',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Emote butonu
              Expanded(
                child: InkWell(
                  onTap: onEmotePressed,
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.emoji_emotions_outlined,
                            color: Colors.amber[400],
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Emote',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Oyuncu bilgisi
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: ShapeDecoration(
              color:
                  isGreenTeam
                      ? const Color(0xFF192418) // Yeşil takım arka planı
                      : const Color(0xFF241818), // Kırmızı takım arka planı
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
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1,
                  ),
                ),
                Text(
                  'Win Rate: $winRate',
                  style: const TextStyle(
                    color: Colors.white,
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
}
