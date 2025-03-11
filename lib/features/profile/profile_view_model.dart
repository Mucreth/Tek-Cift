import 'package:flutter/foundation.dart';
import 'package:handclash/features/auth/auth_service.dart';
import 'package:handclash/features/profile/profile_service.dart';
import 'package:handclash/shared/models/user_model.dart';

class ProfileViewModel with ChangeNotifier {
  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();
  
  UserProfile? _userProfile;
  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> _pendingRequests = [];
  Map<String, dynamic>? _premiumData;
  
  bool _isLoading = true;
  String? _error;

  // Getters
  UserProfile? get userProfile => _userProfile;
  List<Map<String, dynamic>> get friends => _friends;
  List<Map<String, dynamic>> get pendingRequests => _pendingRequests;
  Map<String, dynamic>? get premiumData => _premiumData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Profil verilerini yükle
// Profil verilerini yükle
Future<void> loadProfileData() async {
  _setLoading(true);
  _clearError();

  try {
    // Kullanıcı bilgilerini al
    final userData = await _authService.getCurrentUser();
    
    if (userData != null) {
      final String userId = userData['user_id'];
      
      // İstatistikleri al
      final statsData = await _profileService.getUserStatistics(userId);
      
      // UserProfile nesnesini oluştur
      _userProfile = UserProfile.fromMap(userData, statsData);
      
      // Arkadaş listesini al
      _friends = await _profileService.getFriendsList(userId);
      
      // Bekleyen istekleri al
      _pendingRequests = await _profileService.getPendingRequests(userId);
      
      // Premium durumunu al
      _premiumData = await _profileService.getPremiumStatus(userId);
      
      _setLoading(false);
    } else {
      _setError('Kullanıcı bilgileri alınamadı');
      _setLoading(false);
    }
  } catch (e) {
    _setError('Profil yüklenirken hata oluştu: $e');
    _setLoading(false);
  }
}

  // Arkadaşlık isteğini yanıtla
  Future<bool> respondToFriendRequest(String friendshipId, String response) async {
    try {
      final success = await _profileService.respondToFriendRequest(friendshipId, response);
      
      if (success) {
        // Bekleyen istekleri güncelle
        if (_userProfile != null) {
          _pendingRequests = await _profileService.getPendingRequests(_userProfile!.userId);
          
          // Eğer kabul edildiyse arkadaş listesini de güncelle
          if (response == 'accept') {
            _friends = await _profileService.getFriendsList(_userProfile!.userId);
          }
        }
        
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      _setError('İstek yanıtlanırken hata oluştu: $e');
      return false;
    }
  }

  // Premium satın al
  Future<bool> purchasePremium(String package) async {
    if (_userProfile == null) return false;

    try {
      final success = await _profileService.purchasePremium(_userProfile!.userId, package);
      
      if (success) {
        // Premium durumunu güncelle
        _premiumData = await _profileService.getPremiumStatus(_userProfile!.userId);
        
        // Kullanıcı profilini güncelle (premium durumu değişti)
        final userData = await _authService.getCurrentUser();
        if (userData != null) {
          final statsData = await _profileService.getUserStatistics(_userProfile!.userId);
          _userProfile = UserProfile.fromMap(userData, statsData);
        }
        
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      _setError('Premium satın alınırken hata oluştu: $e');
      return false;
    }
  }

  // Loading state'i güncelle
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Hata mesajını güncelle
  void _setError(String? errorMessage) {
    _error = errorMessage;
    notifyListeners();
  }

  // Hata mesajını temizle
  void _clearError() {
    _error = null;
  }
}