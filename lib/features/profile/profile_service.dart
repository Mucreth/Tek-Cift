import 'package:dio/dio.dart';

class ProfileService {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://handclash.com/api/',
    headers: {
      'X-Api-Key': 'handClash2025hsalCdnaH',
      'Content-Type': 'application/json',
    },
  ));

// Kullanıcı istatistiklerini getir
Future<Map<String, dynamic>?> getUserStatistics(String userId) async {
  try {
    final response = await _dio.get(
      'statistics.php',
      queryParameters: {'user_id': userId},
    );
    
    if (response.data['success']) {
      final statsData = response.data['data'] as Map<String, dynamic>;
      
      // Veri dönüşümleri
      statsData['total_games'] = _parseIntSafely(statsData['total_games']);
      statsData['total_wins'] = _parseIntSafely(statsData['total_wins']);
      statsData['total_losses'] = _parseIntSafely(statsData['total_losses']);
      
      // total_draws ve total_games hesaplama (API'den gelmiyorsa)
      if (!statsData.containsKey('total_draws')) {
        statsData['total_draws'] = 0; // Varsayılan olarak 0
      } else {
        statsData['total_draws'] = _parseIntSafely(statsData['total_draws']);
      }
      
      // Toplam maç sayısı kontrolü
      if (statsData['total_games'] == 0) {
        statsData['total_games'] = statsData['total_wins'] + statsData['total_losses'] + statsData['total_draws'];
      }
      
      // win_rate değerini double'a güvenli çevir
      statsData['win_rate'] = _parseDoubleSafely(statsData['win_rate']);
      
      return statsData;
    }
    return null;
  } catch (e) {
    print('İstatistik verisi alınırken hata: $e');
    return null;
  }
}

  // Son maçları getir
  Future<List<Map<String, dynamic>>> getRecentMatches(String userId) async {
    try {
      final response = await _dio.get(
        'statistics.php',
        queryParameters: {'user_id': userId},
      );

      if (response.data['success'] && response.data['data'] != null) {
        final matchesData = response.data['data']['recent_matches'] as List<dynamic>?;
        
        if (matchesData != null) {
          return matchesData.map((match) => Map<String, dynamic>.from(match)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Son maçlar yüklenirken hata: $e');
      return [];
    }
  }

  // Arkadaş listesini getir
  Future<List<Map<String, dynamic>>> getFriendsList(String userId) async {
    try {
      final response = await _dio.get(
        'friends.php',
        queryParameters: {'user_id': userId},
      );

      if (response.data['success'] && response.data['data'] != null) {
        final friendsData = response.data['data'] as List<dynamic>?;
        
        if (friendsData != null) {
          return friendsData.map((friend) => Map<String, dynamic>.from(friend)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Arkadaş listesi yüklenirken hata: $e');
      return [];
    }
  }

  // Bekleyen arkadaşlık isteklerini getir
  Future<List<Map<String, dynamic>>> getPendingRequests(String userId) async {
    try {
      final response = await _dio.get(
        'friends.php',
        queryParameters: {'pending_requests': userId},
      );

      if (response.data['success'] && response.data['data'] != null) {
        final requestsData = response.data['data'] as List<dynamic>?;
        
        if (requestsData != null) {
          return requestsData.map((request) => Map<String, dynamic>.from(request)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Bekleyen istekler yüklenirken hata: $e');
      return [];
    }
  }

  // Arkadaşlık isteğini yanıtla
  Future<bool> respondToFriendRequest(String friendshipId, String response) async {
    try {
      final res = await _dio.post(
        'friends.php?action=respond_request',
        data: {
          'friendship_id': friendshipId,
          'response': response,
        },
      );

      return res.data['success'] ?? false;
    } catch (e) {
      print('Arkadaşlık isteği yanıtlama hatası: $e');
      return false;
    }
  }

// Premium durumu getir
Future<Map<String, dynamic>?> getPremiumStatus(String userId) async {
  try {
    final response = await _dio.get(
      'premium.php',
      queryParameters: {'user_id': userId},
    );

    if (response.data['success']) {
      final premiumData = response.data['data'] as Map<String, dynamic>;
      
      // is_premium değerini boolean'a çevir
      premiumData['is_premium'] = _parseBoolSafely(premiumData['is_premium']);
      
      // Premium details yoksa boş bir harita ekle
      if (!premiumData.containsKey('premium_details')) {
        premiumData['premium_details'] = {};
      }
      
      return premiumData;
    }
    return null;
  } catch (e) {
    print('Premium durumu yüklenirken hata: $e');
    return null;
  }
}

  // Premium satın al
  Future<bool> purchasePremium(String userId, String package) async {
    try {
      final response = await _dio.post(
        'premium.php?action=purchase',
        data: {
          'user_id': userId,
          'package': package,
        },
      );

      return response.data['success'] ?? false;
    } catch (e) {
      print('Premium satın alınırken hata: $e');
      return false;
    }
  }

  // Güvenli dönüşümler için yardımcı metotlar
int _parseIntSafely(dynamic value, {int defaultValue = 0}) {
  if (value == null) return defaultValue;
  if (value is int) return value;
  return int.tryParse(value.toString()) ?? defaultValue;
}

double _parseDoubleSafely(dynamic value, {double defaultValue = 0.0}) {
  if (value == null) return defaultValue;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse(value.toString()) ?? defaultValue;
}

bool _parseBoolSafely(dynamic value) {
  if (value == null) return false;
  if (value is bool) return value;
  if (value is int) return value == 1;
  if (value is String) {
    return value == '1' || value.toLowerCase() == 'true';
  }
  return false;
}
}