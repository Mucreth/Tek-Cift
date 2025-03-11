import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:handclash/core/constants/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Kullanıcı ID'sini tutacak olan değişken
  String userId = '';

  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://handclash.com/api/',
    headers: {
      'X-Api-Key': 'handClash2025hsalCdnaH',
      'Content-Type': 'application/json',
    },
  ));

  Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString('device_id');

    if (deviceId != null) {
      return deviceId;
    }

    final deviceInfo = DeviceInfoPlugin();
    
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      deviceId = androidInfo.id;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      deviceId = iosInfo.identifierForVendor;
    }

    deviceId ??= 'device_${DateTime.now().millisecondsSinceEpoch}';
    await prefs.setString('device_id', deviceId);
    return deviceId;
  }

  Future<Map<String, dynamic>> authenticateUser() async {
    try {
      final deviceId = await getDeviceId();
      
      print('API İsteği Gönderiliyor:');
      print('URL: ${_dio.options.baseUrl}users.php?action=start');
      print('Headers: ${_dio.options.headers}');
      print('Data: {"device_id": "$deviceId"}');
      
      final response = await _dio.post(
        'users.php?action=start',
        data: {'device_id': deviceId},
      );

      print('API Yanıtı:');
      print(response.data);

      if (response.data['success']) {
        final userData = response.data['data'] as Map<String, dynamic>;
        final userId = userData['user_id'] as String;
        
        // Kullanıcı ID'sini sınıf değişkenine kaydet
        this.userId = userId;
        
        // İstatistikleri al
        final statsResponse = await _dio.get(
          'statistics.php',
          queryParameters: {'user_id': userId},
        );
        
        final stats = statsResponse.data['data'] as Map<String, dynamic>? ?? {};
        
        // Ensure win_rate is properly converted to double
        final double winRate = (stats['win_rate'] is int) 
            ? (stats['win_rate'] as int).toDouble()
            : (stats['win_rate'] as num?)?.toDouble() ?? 0.0;
        
        // Kullanıcı bilgilerini kaydet
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id', userId);
        await prefs.setString('nickname', userData['nickname'] as String? ?? 'Player');
        
        // current_gold değerini sunucudan alıp kullan (sabit değer kullanma)
        final currentGold = userData['current_gold'] is int 
          ? userData['current_gold'] 
          : int.tryParse(userData['current_gold']?.toString() ?? '1000') ?? 1000;
        await prefs.setInt('current_gold', currentGold);
        await prefs.setDouble('win_rate', winRate);

        return {
          'success': true,
          'user': {
            'user_id': userId,
            'nickname': userData['nickname'] as String? ?? 'Player',
            'current_gold': currentGold,
            'win_rate': winRate,
          },
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Bilinmeyen bir hata oluştu',
        };
      }
    } catch (e) {
      print('Hata detayı:');
      if (e is DioException) {
        print('Status code: ${e.response?.statusCode}');
        print('Response data: ${e.response?.data}');
        print('Headers: ${e.response?.headers}');
      }
      return {
        'success': false,
        'message': 'Bağlantı hatası: $e',
      };
    }
  }

  // Mevcut kullanıcı ID'sini alma metodu
// AuthService sınıfında
String getCurrentUserId() {
  // Eğer userId değişkeni boşsa, SharedPreferences'dan yüklemeyi deneyelim
  if (userId.isEmpty) {
    print('userId boş, SharedPreferences\'dan yükleniyor...');
    // Burada asenkron işlem sorun olabilir, yükleme başlar ama hemen sonuç dönmez
    _loadUserIdFromPrefs().then((_) {
      print('SharedPreferences\'dan yüklendi: userId=$userId');
    });
  }
  print('getCurrentUserId çağrıldı, userId=$userId');
  return userId;
}

  // SharedPreferences'dan kullanıcı ID'sini yükleme
  Future<void> _loadUserIdFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      userId = prefs.getString('user_id') ?? '';
    } catch (e) {
      print('Kullanıcı ID yükleme hatası: $e');
    }
  }

  Future<String> updateUserLeague(int currentGold) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    
    if (userId == null) return AppConstants.defaultLeague;
    
    // Altına göre lig belirle
    String newLeague = AppConstants.defaultLeague;
    
    // En yüksekten başlayarak uygun ligi bul
    for (int i = AppConstants.allLeagues.length - 1; i >= 0; i--) {
      final league = AppConstants.allLeagues[i];
      final minGold = AppConstants.leagueLimits[league]!['next_league_min'];
      
      if (i == 0 || currentGold >= minGold) {
        newLeague = i == 0 ? AppConstants.allLeagues[0] : AppConstants.allLeagues[i];
        break;
      }
    }
    
    try {
      // Sunucuya lig güncellemesi gönder
      await _dio.post(
        'users.php?action=update_league',
        data: {
          'user_id': userId,
          'current_league': newLeague,
        },
      );
      
      // Lokalde de güncelle
      await prefs.setString('current_league', newLeague);
      
      return newLeague;
    } catch (e) {
      print('Lig güncelleme hatası: $e');
      return prefs.getString('current_league') ?? AppConstants.defaultLeague;
    }
  }

  // getCurrentUser fonksiyonunda da lig kontrolü ekle
  Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    
    // Kullanıcı ID'sini sınıf değişkenine de kaydet
    this.userId = userId ?? '';
    
    if (userId != null) {
      try {
        // Kullanıcı detaylarını API'den al
        final userResponse = await _dio.get(
          'users.php',
          queryParameters: {'user_id': userId},
        );
        
        if (userResponse.data['success']) {
          final userData = userResponse.data['data'] as Map<String, dynamic>;
          
          // Güncel bilgileri SharedPreferences'a kaydet
          await prefs.setString('nickname', userData['nickname'] as String? ?? 'Player');
          
          // String to int dönüşümü için güvenli metot
          int currentGold = 1000;
          if (userData['current_gold'] != null) {
            if (userData['current_gold'] is int) {
              currentGold = userData['current_gold'];
            } else if (userData['current_gold'] is String) {
              currentGold = int.tryParse(userData['current_gold']) ?? 1000;
            }
          }
          
          await prefs.setInt('current_gold', currentGold);
          
          // Altına göre ligi kontrol et ve güncelle
          String currentLeague = userData['current_league'] as String? ?? AppConstants.defaultLeague;
          final updatedLeague = await updateUserLeague(currentGold);
          
          return {
            'user_id': userId,
            'nickname': userData['nickname'] as String? ?? 'Player',
            'current_gold': currentGold,
            'current_league': updatedLeague,
          };
        }
      } catch (e) {
        print('Kullanıcı bilgileri alınamadı: $e');
        // Hata durumunda cache'deki bilgileri döndür
        return {
          'user_id': userId,
          'nickname': prefs.getString('nickname') ?? 'Player',
          'current_gold': prefs.getInt('current_gold') ?? 1000,
          'current_league': prefs.getString('current_league') ?? AppConstants.defaultLeague,
        };
      }
    }
    return null;
  }
}