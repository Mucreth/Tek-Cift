// lib/features/game/game_enums.dart

enum GamePhase {
  // Hazırlık fazları
  preparation,    // Oyuncuların hazır olmasını bekleme
  everyoneReady,  // Herkes hazır bildirimi
  cardSelect,     // Kart seçim uyarısı
  
  // Oyun fazları
  playing,        // Aktif kart seçim süresi
  revealing,      // Kartların açılma animasyonu
  roundResult,    // Round sonucunun gösterilmesi
  
  // Joker fazları
  jokerSelect,    // Joker seçim süresi
  jokerReveal,    // Jokerlerin gösterilmesi
  jokerResult,    // Joker etkilerinin uygulanması
  jokerSkipped,      // Joker fazı atlandı (yeni eklendi)
  
  // Bitiş fazları
  roundEnd,       // Round sonu özeti
  gameOver        // Oyun sonu
}

enum TimerStatus {
  // Hazırlık durumları
  preparation,     // "Hazırlık: X sn"
  everyoneReady,  // "Herkes Hazır!"
  cardSelect,     // "Kart Seç!"
  
  // Oyun durumları
  countdown,       // "5,4,3,2,1"
  revealing,      // "Kartlar Açılıyor..."
  roundResult,    // "Yeşil/Kırmızı Kazandı!"
  
  // Joker durumları
  jokerTime,      // "Joker: X sn"
  jokerReveal,    // "Jokerler Gösteriliyor..."
  jokerResult,    // "X Joker Kullandı"
  jokerSkipped,      // Joker fazı atlandı (yeni eklendi)
  
  // Bitiş durumları
  roundEnd,       // "Round X Bitti"
  gameOver        // "Oyun Bitti"
}

enum JokerType {
  block,  // Rakibin 2 kartını bloke eder (Server'da BLOCK)
  blind,  // Kartlar gizli oynanır (Server'da artık HOOK)
  bet,    // Bahis 2'ye katlanır (Server'da BET)
  none    // Joker kullanılmadı
}

enum GameResult {
  win,   // Kazanma
  lose,  // Kaybetme
  draw   // Beraberlik
}

enum PlayerSide {
  green,
  red
}

enum MoveType {
  rock,
  paper,
  scissors,
  odd,
  even,
  none
}

enum GameMatchState {
  searching,    // Rakip aranıyor
  opponentFound,// Rakip bulundu
  ready,        // Hazırlık aşaması
  starting      // Oyun başlıyor
}