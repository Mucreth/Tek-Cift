// lib/features/home/widgets/how_to_play_button.dart
import 'package:flutter/material.dart';
import 'dart:ui';

class HowToPlayButton extends StatelessWidget {
  final int currentPage;
  
  const HowToPlayButton({
    Key? key,
    required this.currentPage,
  }) : super(key: key);

  // Güncellenmiş oyun listesi
  static final List<Map<String, dynamic>> games = [
    {
      'title': 'Tek mi Çift mi',
      'gameType': 'oddeven',
      'isAvailable': false, // Oyun henüz mevcut değil
    },
    {
      'title': 'Taş Kağıt Makas',
      'gameType': 'rps',
      'isAvailable': true, // Tek mevcut oyun
    },
    {
      'title': 'Sayı Tahmin',
      'gameType': 'number',
      'isAvailable': false, // Oyun henüz mevcut değil
    },
  ];
  
  // Oyun durumunu kontrol et
  bool _isGameAvailable() {
    if (currentPage >= 0 && currentPage < games.length) {
      return games[currentPage]['isAvailable'] as bool;
    }
    return false;
  }

    @override
  Widget build(BuildContext context) {
    // Eğer oyun mevcut değilse butonu gösterme
    if (!_isGameAvailable()) {
      return const SizedBox.shrink(); // Boş widget
    }
    
    // GestureDetector'ı dışta kullanarak tüm buton tıklanabilir olsun
    return GestureDetector(
      onTap: () => _showHowToPlay(context, currentPage),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.15),
                  Colors.grey.withOpacity(0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 0.5,
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.help_outline, color: Colors.white, size: 18),
                SizedBox(width: 4),
                Text(
                  'Nasıl Oynanır',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  void _showHowToPlay(BuildContext context, int gameIndex) {
    String gameTitle = "";
    String gameType = "";
    
    if (gameIndex >= 0 && gameIndex < games.length) {
      gameTitle = "${games[gameIndex]['title']} Nasıl Oynanır?";
      gameType = games[gameIndex]['gameType'];
    } else {
      gameTitle = "Oyun Kuralları";
      gameType = "default";
    }
    
    // Popup'ı göster
    showHowToPlayDialog(context, gameTitle, gameType);
  }
}

void showHowToPlayDialog(BuildContext context, String gameTitle, String gameType) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.grey[800]!.withOpacity(0.85),
                  Colors.grey[900]!.withOpacity(0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
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
                // Başlık
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.purple.withOpacity(0.7),
                        Colors.deepPurple.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.play_circle_outline,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          gameTitle,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                
                // İçerik (scrollable)
                Flexible(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: _buildGameContent(gameType),
                    ),
                  ),
                ),
                
                // Alt kısım
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.grey[800]!.withOpacity(0.5),
                        Colors.grey[900]!.withOpacity(0.5),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Center(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 5,
                        shadowColor: Colors.purple.withOpacity(0.3),
                      ),
                      child: const Text(
                        'Anladım',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

// İçerik oluşturucu metod
Widget _buildGameContent(String gameType) {
  switch (gameType) {
    case 'rps':
      return _buildRockPaperScissorsGuide();
    case 'oddeven':
      return _buildOddEvenGuide();
    case 'number':
      return _buildNumberGuessGuide();
    default:
      return _buildDefaultGuide();
  }
}

// Taş Kağıt Makas içeriği
Widget _buildRockPaperScissorsGuide() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildSectionTitle("Oyunun Amacı"),
      _buildParagraph(
        "Taş Kağıt Makas oyununda amaç, hedeflenen kazanma sayısına (3 veya 5) ilk ulaşmaktır. "
        "Seçtiğiniz hamlenin rakibinizin hamlesini yenmesi gerekir."
      ),
      const SizedBox(height: 16),
      
      _buildSectionTitle("Nasıl Oynanır?"),
      _buildParagraph(
        "• Her roundda taş, kağıt veya makas seçeneklerinden birini seçersiniz.\n"
        "• Taş makası yener, kağıt taşı yener, makas kağıdı yener.\n"
        "• Aynı hamleyi yaparsanız berabere olur."
      ),
      const SizedBox(height: 16),
      
      _buildSectionTitle("Joker Sistemi"),
      _buildParagraph(
        "Üç tip joker kullanabilirsiniz:"
      ),
      
      _buildJokerExplanation(
        "Blok Jokeri", 
        Icons.block,
        "Rakibinizin bir sonraki turda kullanabileceği iki hamleyi rastgele bloke eder."
      ),
      
      _buildJokerExplanation(
        "Kanca Jokeri", 
        Icons.visibility_off,
        "Rakibinizin bu turda kullandığı hamleyi bir sonraki tur için bloke eder."
      ),
      
      _buildJokerExplanation(
        "Bahis Jokeri", 
        Icons.monetization_on,
        "Kazanırsanız elde edeceğiniz altın miktarını iki katına çıkarır."
      ),
      
      const SizedBox(height: 16),
      
      _buildSectionTitle("Oyun Akışı"),
      _buildParagraph(
        "1. Hazırlık aşamasında her iki oyuncu da hazır olmalıdır.\n"
        "2. Kart seçim aşamasında hamlenizi yaparsınız.\n"
        "3. Kartlar açılır ve sonuç belirlenir.\n"
        "4. Joker seçim aşamasında isterseniz joker kullanabilirsiniz.\n"
        "5. Joker etkileri uygulanır ve bir sonraki round başlar."
      ),
    ],
  );
}

// Tek Çift içeriği
Widget _buildOddEvenGuide() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildSectionTitle("Oyunun Amacı"),
      _buildParagraph(
        "Tek Çift oyununda amaç, hedeflenen kazanma sayısına (3 veya 5) ilk ulaşmaktır. "
        "Rakibinizin seçimiyle sizin seçiminiz farklı olduğunda ve sizin seçiminiz değer olarak yüksekse kazanırsınız."
      ),
      const SizedBox(height: 16),
      
      _buildSectionTitle("Nasıl Oynanır?"),
      _buildParagraph(
        "• Her roundda TEK veya ÇİFT seçeneklerinden birini seçersiniz.\n"
        "• Eğer rakibinizle aynı seçimi yaparsanız, berabere olur.\n"
        "• Farklı seçimler yaparsanız, ÇİFT seçimi TEK seçimini yener."
      ),
      const SizedBox(height: 16),
      
      _buildSectionTitle("Joker Sistemi"),
      _buildParagraph(
        "Üç tip joker kullanabilirsiniz:"
      ),
      
      _buildJokerExplanation(
        "Blok Jokeri", 
        Icons.block,
        "Rakibinizin bir sonraki turda bir hamlesini bloke eder (TEK veya ÇİFT)."
      ),
      
      _buildJokerExplanation(
        "Kanca Jokeri", 
        Icons.visibility_off,
        "Rakibinizin bu turda kullandığı hamleyi bir sonraki tur için bloke eder."
      ),
      
      _buildJokerExplanation(
        "Bahis Jokeri", 
        Icons.monetization_on,
        "Kazanırsanız elde edeceğiniz altın miktarını iki katına çıkarır."
      ),
      
      const SizedBox(height: 16),
      
      _buildSectionTitle("Oyun Akışı"),
      _buildParagraph(
        "1. Hazırlık aşamasında her iki oyuncu da hazır olmalıdır.\n"
        "2. Kart seçim aşamasında TEK veya ÇİFT seçersiniz.\n"
        "3. Kartlar açılır ve sonuç belirlenir.\n"
        "4. Joker seçim aşamasında isterseniz joker kullanabilirsiniz.\n"
        "5. Joker etkileri uygulanır ve bir sonraki round başlar."
      ),
    ],
  );
}

// Sayı Tahmin içeriği
Widget _buildNumberGuessGuide() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildSectionTitle("Oyunun Amacı"),
      _buildParagraph(
        "Sayı Tahmin oyununda amaç, doğru sayıyı rakibinizden daha az denemede bulmaktır. "
        "Her denemenizde aldığınız ipuçlarını iyi değerlendirmelisiniz."
      ),
      const SizedBox(height: 16),
      
      _buildSectionTitle("Nasıl Oynanır?"),
      _buildParagraph(
        "• Her roundda 1-100 arasında bir sayı tahmin edersiniz.\n"
        "• Tahminlerinize göre 'Çok Yüksek', 'Yüksek', 'Düşük' veya 'Çok Düşük' ipuçları alırsınız.\n"
        "• Sayıyı doğru tahmin ettiğinizde round biter.\n"
        "• En az denemeyle bulan oyuncu kazanır."
      ),
      const SizedBox(height: 16),
      
      _buildSectionTitle("Joker Sistemi"),
      _buildParagraph(
        "Üç tip joker kullanabilirsiniz:"
      ),
      
      _buildJokerExplanation(
        "İpucu Jokeri", 
        Icons.lightbulb_outline,
        "Size daha kesin bir ipucu verir, sayıya yaklaşmanızı kolaylaştırır."
      ),
      
      _buildJokerExplanation(
        "Aralık Jokeri", 
        Icons.all_inclusive,
        "Sayının bulunduğu aralığı daraltır (örn: 35-65 gibi)."
      ),
      
      _buildJokerExplanation(
        "Bahis Jokeri", 
        Icons.monetization_on,
        "Kazanırsanız elde edeceğiniz altın miktarını iki katına çıkarır."
      ),
      
      const SizedBox(height: 16),
      
      _buildSectionTitle("Oyun Akışı"),
      _buildParagraph(
        "1. Her iki oyuncu da hazır olduğunda round başlar.\n"
        "2. Sırayla tahminler yaparsınız ve ipuçları alırsınız.\n"
        "3. Doğru sayıyı bulan ilk oyuncu o roundu kazanır.\n"
        "4. Joker kullanmak isteyip istemediğiniz sorulur.\n"
        "5. Sonraki round başlar ve bu şekilde devam eder."
      ),
    ],
  );
}

// Varsayılan içerik
Widget _buildDefaultGuide() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildSectionTitle("Oyun Kuralları"),
      _buildParagraph(
        "Jokerlerin Genel Kullanımı:\n\n"
        "• Blok Jokeri: Rakibinizin bir sonraki turda kullanabileceği hamleleri bloke eder.\n\n"
        "• Kanca Jokeri: Rakibinizin mevcut hamlelerini bir sonraki tur için bloke eder.\n\n"
        "• Bahis Jokeri: Kazanırsanız elde edeceğiniz altın miktarını iki katına çıkarır."
      ),
      const SizedBox(height: 16),
      
      _buildSectionTitle("Oyun Tipleri"),
      _buildParagraph(
        "Taş Kağıt Makas: Klasik oyun. Taş makası, kağıt taşı, makas kağıdı yener.\n\n"
        "Tek Çift: Oyuncular TEK veya ÇİFT seçer. Eğer aynı seçimi yaparlarsa berabere olur. Farklı seçim yaptıklarında ÇİFT, TEK'i yener.\n\n"
        "Sayı Tahmin: Gizli bir sayıyı bulmak için ipuçlarını kullanarak tahminler yaparsınız."
      ),
      const SizedBox(height: 16),
      
      _buildParagraph(
        "Oyunlara ilişkin daha detaylı bilgileri, ilgili oyun seçiliyken 'Nasıl Oynanır?' kılavuzundan öğrenebilirsiniz."
      ),
    ],
  );
}

// Bölüm başlığı
Widget _buildSectionTitle(String title) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10.0),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.purple.withOpacity(0.7),
            Colors.deepPurple.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ),
  );
}

// Paragraf
Widget _buildParagraph(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12.0, left: 8.0),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        color: Colors.white,
        height: 1.4,
      ),
    ),
  );
}

// Joker açıklaması
Widget _buildJokerExplanation(String title, IconData icon, String description) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12.0, left: 8.0),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.05),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: Colors.purple.withOpacity(0.3),
        width: 1,
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.purple.withOpacity(0.7),
                Colors.deepPurple.withOpacity(0.7),
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}