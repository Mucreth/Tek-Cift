// lib/features/game/widgets/matchmaking_dialog.dart
import 'dart:ui';
import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:handclash/features/game/game_view_model.dart';
import 'package:handclash/features/game/game_enums.dart';
import 'package:handclash/features/home/home_screen.dart';
import 'package:lottie/lottie.dart';

class MatchmakingDialog extends StatefulWidget {
  final GameViewModel viewModel;
  final int betAmount;

  const MatchmakingDialog({
    Key? key,
    required this.viewModel,
    required this.betAmount,
  }) : super(key: key);

  @override
  State<MatchmakingDialog> createState() => _MatchmakingDialogState();
}

class _MatchmakingDialogState extends State<MatchmakingDialog> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late int _estimatedWaitTime;
  late DateTime _searchStartTime;
  Timer? _waitTimer;
  Timer? _readyTimer;
  int _elapsedSeconds = 0;
  int _readyTimeLeft = 10; // 10 saniye hazırlık sayacı
  
  @override
  void initState() {
    super.initState();
    
    // Arama animasyonu için controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    
    // Rastgele bekleme süresi (10-25 saniye arası)
    _estimatedWaitTime = Random().nextInt(16) + 10; // 10 ile 25 arası
    _searchStartTime = DateTime.now();
    
    // Geçen süreyi takip etmek için timer
    _startWaitTimer();
  }
  
  void _startWaitTimer() {
    _waitTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsedSeconds = DateTime.now().difference(_searchStartTime).inSeconds;
        });
      }
    });
  }
  
  void _startReadyTimer() {
    // Hazırlık sayacı
    _readyTimeLeft = 10;
    _readyTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _readyTimeLeft--;
          
          // Süre dolunca otomatik iptal et
          if (_readyTimeLeft <= 0) {
            _readyTimer?.cancel();
            _cancelMatchmaking(context);
          }
        });
      }
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _waitTimer?.cancel();
    _readyTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Geri tuşunu devre dışı bırak
      child: ValueListenableBuilder<GameMatchState>(
        valueListenable: widget.viewModel.matchState,
        builder: (context, state, child) {
          // Eğer state değişti ve ready state'ine geçildiyse sayacı başlat
          if (state == GameMatchState.ready) {
            // build bittikten sonra çalışsın diye Future.microtask kullanıyoruz
            if (_readyTimer == null) {
              Future.microtask(() {
                if (mounted) {
                  _startReadyTimer();
                }
              });
            }
          }
          
          // Eğer "starting" durumundaysa otomatik olarak dialog'u kapat
          if (state == GameMatchState.starting) {
            // build bittikten sonra çalışsın diye Future.microtask kullanıyoruz
            Future.microtask(() {
              if (mounted) {
                Future.delayed(const Duration(seconds: 2), () {
                  try {
                    if (mounted && Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  } catch (e) {
                    print('Dialog kapatma hatası: $e');
                  }
                });
              }
            });
          }

          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              // PADDING: Dialog için yatay iç boşluk
              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildDialogContent(state, context),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDialogContent(GameMatchState state, BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          // PADDING: Ana container iç boşluğu (her taraftan 6px)
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.15),
                Colors.grey.withOpacity(0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // PADDING: Başlık ve bahis bilgisi padding (üst, alt, sağ, sol)
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 15, left: 10, right: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getTitleForState(state),
                      style: const TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                    _buildBetAmountBadge(),
                  ],
                ),
              ),
              
              // PADDING: Ayırıcı çizgi padding
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: Container(
                  height: 1,
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
              
              // PADDING: İçerik padding
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: _buildContentForState(state),
              ),
              
              // PADDING: Butonlar padding
              Padding(
                padding: const EdgeInsets.only(bottom: 4, left: 4, right: 4),
                child: _buildActionsForState(state, context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTitleForState(GameMatchState state) {
    switch (state) {
      case GameMatchState.searching:
        return 'Eşleşme Bekleniyor';
      case GameMatchState.opponentFound:
        return 'Rakip Bulundu!';
      case GameMatchState.ready:
        return 'Oyuna Hazırlık';
      case GameMatchState.starting:
        return 'Oyun Başlıyor!';
      default:
        return 'Eşleşme Bekleniyor';
    }
  }

  Widget _buildContentForState(GameMatchState state) {
    switch (state) {
      case GameMatchState.searching:
        return _buildSearchingContent();
      case GameMatchState.opponentFound:
        return _buildOpponentFoundContent();
      case GameMatchState.ready:
        return _buildReadyContent();
      case GameMatchState.starting:
        return _buildStartingContent();
      default:
        return _buildSearchingContent();
    }
  }

  Widget _buildActionsForState(GameMatchState state, BuildContext context) {
    if (state == GameMatchState.searching ||
        state == GameMatchState.opponentFound) {
      return _buildGlowingButton(
        onPressed: () => _cancelMatchmaking(context),
        text: 'İptal Et',
        color: Colors.redAccent,
      );
    } else if (state == GameMatchState.ready) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 1,
            child: _buildGlowingButton(
              onPressed: () => _cancelMatchmaking(context),
              text: 'İptal',
              color: Colors.redAccent,
            ),
          ),
          // MARGIN: İptal ve Hazırım butonları arasındaki boşluk
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: _buildGlowingButton(
              onPressed: () {
                // build sonrası çalışsın
                Future.microtask(() {
                  if (mounted) {
                    widget.viewModel.markPlayerReady();
                    _readyTimer?.cancel(); // Hazır olunca sayacı durdur
                    setState(() {});
                  }
                });
              },
              text: 'Hazırım!',
              color: Colors.green,
              isDisabled: widget.viewModel.state.isPlayerReady,
            ),
          ),
        ],
      );
    } else {
      return const SizedBox.shrink(); // Gizli buton
    }
  }

  Widget _buildSearchingContent() {
    return Column(
      children: [
        // Lottie animasyonu - sarı çember olmadan ve daha büyük
        // Lottie doğrudan, daha büyük boyutta
        SizedBox(
          // BOYUT: Lottie animasyonunun boyutu
          width: 140, // Daha büyük boyut (önceden 120 idi)
          height: 140, // Daha büyük boyut (önceden 120 idi)
          child: Builder(
            builder: (context) {
              return Lottie.asset(
                'assets/images/search.json',
                width: 140, // Daha büyük boyut
                height: 140, // Daha büyük boyut
                fit: BoxFit.contain,
                addRepaintBoundary: true,
                frameRate: FrameRate(30),
              );
            },
          ),
        ),
        
        // MARGIN: Animasyon ile metin arası boşluk
        const SizedBox(height: 2),
        // Tahmini bekleme süresi - Ekran genişliğine uygun
        LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              width: constraints.maxWidth, // Ekran genişliğinde
              // PADDING: Bekleme süresi kutusu iç boşluğu
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Tahmini bekleme süresi: $_estimatedWaitTime saniye',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  // MARGIN: İki metin arası boşluk
                  const SizedBox(height: 8),
                  
                  // Geçen süre
                  Text(
                    'Geçen süre: $_elapsedSeconds saniye',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _elapsedSeconds > _estimatedWaitTime 
                          ? Colors.amber.withOpacity(0.8) 
                          : Colors.white70,
                      fontSize: 14,
                      fontWeight: _elapsedSeconds > _estimatedWaitTime 
                          ? FontWeight.bold 
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildOpponentFoundContent() {
    return Column(
      children: [
        Container(
          // BOYUT: Rakip bulundu ikonu boyutu
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withOpacity(0.2),
            border: Border.all(
              color: Colors.green.withOpacity(0.7),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            Icons.person_search,
            color: Colors.green.withOpacity(0.9),
            size: 48,
          ),
        ),
        // MARGIN: İkon ile yazı arası boşluk
        const SizedBox(height: 16),
        
        // Rakip bulundu yazısı
        Container(
          // PADDING: Rakip bulundu yazısı iç boşluğu
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.green.withOpacity(0.3),
                Colors.green.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text(
            'Rakip bulundu!',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        
        // MARGIN: Yazı ile rakip ismi arası boşluk
        const SizedBox(height: 20),
        
        // Rakip ismi
        LayoutBuilder(
          builder: (context, constraints) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: Container(
                  width: constraints.maxWidth, // Tam genişlik
                  // PADDING: Rakip ismi kutusu iç boşluğu
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.person,
                        color: Colors.white70,
                        size: 22,
                      ),
                      // MARGIN: İkon ile rakip ismi arası boşluk
                      const SizedBox(width: 10),
                      Text(
                        '${widget.viewModel.opponentName ?? "Rakip"}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildReadyContent() {
    final bool isPlayerReady = widget.viewModel.state.isPlayerReady;
    
    return Column(
      children: [
        // Tam genişlikte hazırlık ekranı için LayoutBuilder kullanıyoruz
        LayoutBuilder(
          builder: (context, constraints) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                child: Container(
                  // Tam genişlik
                  width: constraints.maxWidth,
                  // PADDING: Hazırlık ekranı iç boşluğu
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isPlayerReady ? Colors.green.withOpacity(0.6) : Colors.white.withOpacity(0.1),
                      width: isPlayerReady ? 2 : 1,
                    ),
                    boxShadow: isPlayerReady
                        ? [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.2),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        isPlayerReady ? Icons.check_circle : Icons.hourglass_top,
                        color: isPlayerReady ? Colors.green : Colors.white70,
                        size: 48,
                      ),
                      // MARGIN: İkon ile başlık arası boşluk
                      const SizedBox(height: 16),
                      Text(
                        isPlayerReady ? 'Hazırsınız!' : 'Hazır mısınız?',
                        style: TextStyle(
                          color: isPlayerReady ? Colors.green : Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // MARGIN: Başlık ile açıklama arası boşluk
                      const SizedBox(height: 12),
                      Text(
                        isPlayerReady 
                            ? 'Rakip de hazır olduğunda oyun başlayacak'
                            : 'Hazır olduğunuzda "Hazırım!" butonuna basın',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: isPlayerReady ? Colors.green.withOpacity(0.8) : Colors.white70,
                        ),
                      ),
                      
                      // Hazırlık sayacı (eğer hazır değilse)
                      if (!isPlayerReady) ...[
                        // MARGIN: Açıklama ile sayaç arası boşluk
                        const SizedBox(height: 20),
                        Container(
                          // Sayacı da maksimum genişlikte yapalım
                          width: double.infinity,
                          // PADDING: Sayaç kutusu iç boşluğu
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _readyTimeLeft <= 3 
                                ? Colors.red.withOpacity(0.2)
                                : Colors.amber.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _readyTimeLeft <= 3
                                  ? Colors.red.withOpacity(0.5)
                                  : Colors.amber.withOpacity(0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center, // Merkeze hizala
                            children: [
                              Icon(
                                Icons.timer,
                                color: _readyTimeLeft <= 3 ? Colors.red : Colors.amber,
                                size: 18,
                              ),
                              // MARGIN: İkon ile sayaç yazısı arası boşluk
                              const SizedBox(width: 8),
                              Text(
                                '$_readyTimeLeft saniye içinde karar verin',
                                style: TextStyle(
                                  color: _readyTimeLeft <= 3 ? Colors.red : Colors.amber,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStartingContent() {
    return Column(
      children: [
        // Oyun başlıyor içeriği
        Container(
          // BOYUT: Oyun başlıyor ikonu boyutu
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.green.withOpacity(0.3),
                Colors.green.withOpacity(0.1),
              ],
            ),
            border: Border.all(
              color: Colors.green.withOpacity(0.7),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.sports_esports,
            color: Colors.green,
            size: 60,
          ),
        ),
        // MARGIN: İkon ile yazı arası boşluk
        const SizedBox(height: 20),
        
        // Oyun başlıyor yazısı
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Container(
              // PADDING: Oyun başlıyor yazısı iç boşluğu
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.green.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Oyun başlıyor!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: Colors.green.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  // MARGIN: Yazı ile ikon arası boşluk
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.rocket_launch,
                    color: Colors.green,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBetAmountBadge() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          // PADDING: Bahis rozeti iç boşluğu
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.amber.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withOpacity(0.2),
                blurRadius: 8,
                spreadRadius: 0,
              )
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.monetization_on_outlined,
                color: Colors.amber,
                size: 18,
              ),
              // MARGIN: İkon ile yazı arası boşluk
              const SizedBox(width: 4),
              Text(
                '${widget.betAmount} Gold',
                style: const TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlowingButton({
    required VoidCallback onPressed,
    required String text,
    required Color color,
    bool isDisabled = false,
    bool small = false,
  }) {
    return InkWell(
      onTap: isDisabled ? null : onPressed,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16), // 16 radius
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: Container(
            // BOYUT VE PADDING: Buton yüksekliği ve iç boşluğu
            height: 50, // Sabit yükseklik - tüm butonlar aynı yükseklikte
            padding: EdgeInsets.symmetric(
              horizontal: small ? 12 : 24,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDisabled
                    ? [Colors.grey.shade800.withOpacity(0.7), Colors.grey.shade900.withOpacity(0.7)]
                    : [color.withOpacity(0.7), color.withOpacity(0.5)],
              ),
              borderRadius: BorderRadius.circular(16), // 16 radius
              border: Border.all(
                color: isDisabled
                    ? Colors.grey.withOpacity(0.3)
                    : color.withOpacity(0.5),
                width: 1.5,
              ),
              boxShadow: isDisabled
                  ? null
                  : [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ],
            ),
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  color: isDisabled ? Colors.grey : Colors.white,
                  fontSize: small ? 14 : 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _cancelMatchmaking(BuildContext context) {
    // Timer'ları kapat
    _waitTimer?.cancel();
    _readyTimer?.cancel();
    
    // Ana sayfaya yönlendir
    Navigator.of(context).pop(); // Dialog'u kapat
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );

    // Eşleşmeyi iptal et
    widget.viewModel.cancelMatchmaking(context);
  }
}