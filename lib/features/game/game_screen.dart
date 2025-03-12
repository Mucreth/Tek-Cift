//... Diğer kodlar aynen kalacak

  Future<void> _setupGame() async {
  try {
    // Mevcut kullanıcı bilgilerini al
    final userData = await AuthService().getCurrentUser();
    if (userData != null) {
      print('DEBUG_SCREEN: Kullanıcı verileri: $userData');
      setState(() {
        currentUser = UserInfo(
          userId: userData['user_id'] ?? '',
          nickname: userData['nickname'] ?? 'Oyuncu',
          winRate: _formatWinRate(userData['win_rate']),
          isGreenTeam: true, // Başlangıç değeri, sonradan güncellenecek
        );
      });
      print('DEBUG_SCREEN: Güncel kullanıcı: ${currentUser?.nickname}, WinRate: ${currentUser?.winRate}');
    }

    // AI modunda rakip bilgilerini manuel olarak oluştur
    if (widget.isAIGame) {
      setState(() {
        // AI rakibi oluştur
        opponent = UserInfo(
          userId: 'ai',
          nickname: 'AI Rakip',
          winRate: '50.0%',  // Formatlanmış değer
          isGreenTeam: false, // AI her zaman kırmızı takım
        );
      });
      print('DEBUG_SCREEN: AI rakibi oluşturuldu: ${opponent?.nickname}, WinRate: ${opponent?.winRate}');
      
      // AI oyununu doğrudan başlat
      _viewModel.startGame();
      return;
    }

    // Çevrimiçi modda devam et
    _viewModel.onOpponentFound = (opponentData) {
      // Rakip verileri gelince buradaki kod çalışacak
      final isGreenTeam = _viewModel.state.isGreenTeam;
      print("DEBUG_SCREEN: onOpponentFound callback - Gelen rakip verileri: $opponentData"); // Debug için

      setState(() {
        // Önce mevcut kullanıcı takım bilgisini güncelle
        if (currentUser != null) {
          currentUser = currentUser!.copyWith(isGreenTeam: isGreenTeam);
          print('DEBUG_SCREEN: Kullanıcı takım rengi güncellendi, isGreenTeam: $isGreenTeam');
        }

        // DÜZELTİLDİ: Rakip bilgilerini doğrudan işle
        if (opponentData != null) {
          // Eğer nickname ve win_rate direkt erişilebilir değilse
          // Güncellenmiş yöntem kullanarak rakip bilgilerini oluştur
          String opponentNickname = "Rakip";
          String opponentWinRate = "0.0%";
          String opponentId = "opponent_id";
          
          if (opponentData is Map<String, dynamic>) {
            // Tüm alan adlarını kontrol et ve logla
            print('DEBUG_SCREEN: opponentData anahtarları: ${opponentData.keys.toList()}');
            
            // Kullanıcı ID'si için kontrol
            if (opponentData.containsKey('userId')) {
              opponentId = opponentData['userId'];
              print('DEBUG_SCREEN: userId bulundu: $opponentId');
            } else if (opponentData.containsKey('user_id')) {
              opponentId = opponentData['user_id'];
              print('DEBUG_SCREEN: user_id bulundu: $opponentId');
            } else if (opponentData.containsKey('id')) {
              opponentId = opponentData['id'];
              print('DEBUG_SCREEN: id bulundu: $opponentId');
            }
            
            // Nickname için kontrol
            if (opponentData.containsKey('nickname')) {
              opponentNickname = opponentData['nickname'];
              print('DEBUG_SCREEN: nickname bulundu: $opponentNickname');
            } else if (opponentData.containsKey('name')) {
              opponentNickname = opponentData['name'];
              print('DEBUG_SCREEN: name bulundu: $opponentNickname');
            }
            
            // Win rate için kontrol
            if (opponentData.containsKey('win_rate')) {
              opponentWinRate = _formatWinRate(opponentData['win_rate']);
              print('DEBUG_SCREEN: win_rate bulundu: ${opponentData['win_rate']}, formatlı: $opponentWinRate');
            } else if (opponentData.containsKey('winRate')) {
              opponentWinRate = _formatWinRate(opponentData['winRate']);
              print('DEBUG_SCREEN: winRate bulundu: ${opponentData['winRate']}, formatlı: $opponentWinRate');
            }
          }
          
          opponent = UserInfo(
            userId: opponentId,
            nickname: opponentNickname,
            winRate: opponentWinRate,
            isGreenTeam: !isGreenTeam, // Rakip her zaman farklı renkte
          );
          
          print("DEBUG_SCREEN: Rakip oluşturuldu: ${opponent?.nickname}, WinRate: ${opponent?.winRate}, isGreenTeam: ${opponent?.isGreenTeam}");
        } else {
          // Veri yoksa varsayılan değerler
          opponent = UserInfo(
            userId: 'opponent_id',
            nickname: 'Rakip',
            winRate: '50.0%',
            isGreenTeam: !isGreenTeam,
          );
          print("DEBUG_SCREEN: Varsayılan rakip oluşturuldu: ${opponent?.nickname}, WinRate: ${opponent?.winRate}");
        }
      });
    };

    _viewModel.startGame();
  } catch (e) {
    print('DEBUG_SCREEN: _setupGame HATA: $e');
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Oyun başlatma hatası: $e')));
    }
  }
}