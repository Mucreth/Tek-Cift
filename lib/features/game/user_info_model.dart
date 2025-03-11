// lib/features/game/user_info_model.dart
class UserInfo {
  final String userId;
  final String nickname;
  final String winRate;
  final bool isGreenTeam;

  UserInfo({
    required this.userId,
    required this.nickname,
    required this.winRate,
    required this.isGreenTeam,
  });

  // user_info_model.dart için güncelleme
  factory UserInfo.fromJson(Map<String, dynamic> json, {required bool isGreenTeam}) {
    // Win rate'i doğru formatlayalım
    String formattedWinRate;
    
    if (json.containsKey('win_rate')) {
      // Önce sayısal değere dönüştürüp sonra formatlayalım
      double winRateValue = 0.0;
      
      if (json['win_rate'] is double) {
        winRateValue = json['win_rate'];
      } else if (json['win_rate'] is int) {
        winRateValue = (json['win_rate'] as int).toDouble();
      } else {
        // String'den double'a çevirmeyi dene
        winRateValue = double.tryParse(json['win_rate'].toString().replaceAll(',', '.')) ?? 0.0;
      }
      
      // Formatla: 1 decimal basamaklı ve % işareti
      formattedWinRate = '${winRateValue.toStringAsFixed(1)}%';
    } else if (json.containsKey('winRate')) {
      // Eğer winRate zaten string olarak varsa
      String winRateStr = json['winRate'];
      if (!winRateStr.endsWith('%')) {
        winRateStr = '$winRateStr%';
      }
      formattedWinRate = winRateStr;
    } else {
      formattedWinRate = '0.0%';
    }
    
    return UserInfo(
      userId: json['id'] ?? json['userId'] ?? json['user_id'] ?? '',
      nickname: json['nickname'] ?? 'Player',
      winRate: formattedWinRate, // Formatlanmış değeri kullan
      isGreenTeam: isGreenTeam,
    );
  }
  
  // copyWith metodu (daha önce vardı, ekliyorum)
  UserInfo copyWith({
    String? userId,
    String? nickname,
    String? winRate,
    bool? isGreenTeam,
  }) {
    return UserInfo(
      userId: userId ?? this.userId,
      nickname: nickname ?? this.nickname,
      winRate: winRate ?? this.winRate,
      isGreenTeam: isGreenTeam ?? this.isGreenTeam,
    );
  }
}