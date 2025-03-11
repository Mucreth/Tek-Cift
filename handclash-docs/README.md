# Handclash Game Documentation

## 🎮 Proje Özeti
Handclash, klasik el oyunlarını (Taş-Kağıt-Makas, Tek mi Çift mi vb.) modern bir yaklaşımla birleştiren, çevrimiçi rekabetçi bir mobil oyun platformudur. Joker sistemi, bahis mekanizması ve lig yapısı ile oyunlara stratejik bir derinlik katmaktadır.

## 🎯 Temel Özellikler

### Oyun Sistemi
- Çeşitli el oyunları (sürekli genişleyen oyun havuzu)
- 5 veya 9 roundluk maçlar
- Stratejik joker sistemi (3 farklı tip)
- Gerçek zamanlı çevrimiçi eşleşme
- Bilgisayara karşı pratik modu

### Lig ve Bahis Sistemi
- 8 farklı lig seviyesi (Bronze'dan Legend'a)
- Lig bazlı bahis limitleri
- Rekabetçi sıralama sistemi
- Aylık/Yıllık/Tüm zamanlar lider tabloları

### Sosyal Özellikler
- Arkadaşlık sistemi
- Özel maç odaları
- Quick chat ve emote sistemi
- Son rakiplerle tekrar oynama

### Ekonomi Sistemi
- Gold bazlı ekonomi
- Premium üyelik özellikleri
- Günlük bonus sistemi
- Reklam izleyerek gold kazanma

## 📁 Proje Yapısı
handclash-docs/
├── diagrams/           # Sistem diyagramları
├── specifications/     # Teknik özellikler
├── json-structures/    # Veri modelleri
└── README.md          # Bu dosya

## 🛠 Teknik Altyapı
- Frontend: Flutter
- Backend: Karar verilemedi
- Veritabanı: Kendi sunucumuz
- Cache: Karar verilmedi
- Realtime: AWS Websoket

## 🔒 Güvenlik Özellikleri
- Apple Sign-in entegrasyonu
- Device ID bazlı kullanıcı sistemi
- Anti-hile mekanizmaları
- Güvenli ödeme sistemi

## 📊 Sistem Bileşenleri
- Kullanıcı yönetimi
- Eşleşme sistemi
- Ödeme sistemi
- İstatistik sistemi
- Destek sistemi
- Bakım ve güncelleme sistemi

## 💡 Geliştirme Kaynakları
- [Teknik Şartname](specifications/technical-specs.md)
- [Oyun Mekanikleri](specifications/game-mechanics.md)
- [Ekonomi Sistemi](specifications/economy-system.md)
- [Kullanıcı Sistemi](specifications/user-system.md)

## 🤝 İletişim ve Destek
Proje ile ilgili sorularınız için [destek sistemini](specifications/technical-specs.md#destek-sistemi) kullanabilirsiniz.

## 🎲 Gelecek Özellikler
- Yeni oyun tipleri
- Turnuva sistemi
- Sezon sistemi
- Özel etkinlikler