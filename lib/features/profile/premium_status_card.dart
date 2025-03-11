import 'package:flutter/material.dart';
import 'package:handclash/features/profile/profile_service.dart';

import 'dart:ui';

class PremiumStatusCard extends StatefulWidget {
  final String? userId;

  const PremiumStatusCard({
    super.key,
    required this.userId,
  });

  @override
  State<PremiumStatusCard> createState() => _PremiumStatusCardState();
}

class _PremiumStatusCardState extends State<PremiumStatusCard> {
  final ProfileService _profileService = ProfileService();
  Map<String, dynamic>? _premiumData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPremiumStatus();
  }

  Future<void> _loadPremiumStatus() async {
    if (widget.userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final premiumData = await _profileService.getPremiumStatus(widget.userId!);
      
      setState(() {
        _premiumData = premiumData;
        _isLoading = false;
      });
    } catch (e) {
      print('Premium durumu yüklenirken hata: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _purchasePremium(String package) async {
    setState(() => _isLoading = true);

    try {
      final success = await _profileService.purchasePremium(widget.userId!, package);
      
      if (success) {
        await _loadPremiumStatus();
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Premium satın alınırken hata: $e');
      setState(() => _isLoading = false);
    }
  }

@override
Widget build(BuildContext context) {
  if (_isLoading) {
    return const SizedBox(
      height: 100,
      child: Center(child: CircularProgressIndicator()),
    );
  }

  // Boolean'a dönüştürme
  final bool isPremium = _parseBoolSafely(_premiumData?['is_premium']);
  final Map<String, dynamic>? premiumDetails = _premiumData?['premium_details'];

  return isPremium ? _buildPremiumCard(premiumDetails) : _buildNonPremiumCard();
}

// Boolean'a güvenli dönüşüm
bool _parseBoolSafely(dynamic value) {
  if (value == null) return false;
  if (value is bool) return value;
  if (value is int) return value == 1;
  if (value is String) {
    return value == '1' || value.toLowerCase() == 'true';
  }
  return false;
}

  Widget _buildPremiumCard(Map<String, dynamic>? details) {
    final String endDate = details?['end_date'] ?? '';
    final List<dynamic> featuresData = details?['features'] ?? [];
    final Map<String, dynamic> features = {};
    
    // Özellik listesini işle
    if (featuresData is List) {
      for (var feature in featuresData) {
        if (feature is Map) {
          features.addAll(Map<String, dynamic>.from(feature));
        }
      }
    }

    // Kalan süreyi hesapla
    String remainingTime = '';
    if (endDate.isNotEmpty) {
      try {
        final DateTime end = DateTime.parse(endDate);
        final DateTime now = DateTime.now();
        final Duration remaining = end.difference(now);
        
        if (remaining.inDays > 0) {
          remainingTime = '${remaining.inDays} gün kaldı';
        } else if (remaining.inHours > 0) {
          remainingTime = '${remaining.inHours} saat kaldı';
        } else {
          remainingTime = '${remaining.inMinutes} dakika kaldı';
        }
      } catch (e) {
        remainingTime = 'Süre hesaplanamadı';
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.amber.withOpacity(0.6),
                Colors.purple.withOpacity(0.6),
              ],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Premium başlık
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Premium Aktif',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.black.withOpacity(0.2),
                    ),
                    child: Text(
                      remainingTime,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Premium özellikleri
              _buildFeatureList(features),
              
              const SizedBox(height: 16),
              
              // Yenileme butonu
              _buildPremiumButton(
                title: 'Üyeliği Uzat',
                onPressed: () => _showPremiumPackages(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNonPremiumCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withOpacity(0.1),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Premium başlık
              const Row(
                children: [
                  Icon(
                    Icons.star_border,
                    color: Colors.white,
                    size: 24,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Premium Üyelik',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Premium açıklaması
              Text(
                'Premium üyelik ile reklamsız deneyim, özel kozmetik ürünler ve daha fazla avantaja sahip olun!',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Premium özellikleri
              Column(
                children: [
                  _buildFeatureItem(
                    icon: Icons.block,
                    title: 'Reklamsız deneyim',
                    isActive: false,
                  ),
                  _buildFeatureItem(
                    icon: Icons.face,
                    title: 'Özel avatar seçenekleri',
                    isActive: false,
                  ),
                  _buildFeatureItem(
                    icon: Icons.auto_awesome,
                    title: 'Özel efektler',
                    isActive: false,
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Satın alma butonu
              _buildPremiumButton(
                title: 'Premium Satın Al',
                onPressed: () => _showPremiumPackages(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureList(Map<String, dynamic> features) {
    final List<Widget> featureWidgets = [];
    
    if (features.containsKey('no_ads')) {
      featureWidgets.add(_buildFeatureItem(
        icon: Icons.block,
        title: 'Reklamsız deneyim',
        isActive: features['no_ads'] ?? false,
      ));
    }
    
    if (features.containsKey('custom_avatar')) {
      featureWidgets.add(_buildFeatureItem(
        icon: Icons.face,
        title: 'Özel avatar seçenekleri',
        isActive: features['custom_avatar'] ?? false,
      ));
    }
    
    if (features.containsKey('special_effects')) {
      featureWidgets.add(_buildFeatureItem(
        icon: Icons.auto_awesome,
        title: 'Özel efektler',
        isActive: features['special_effects'] ?? false,
      ));
    }
    
    if (features.containsKey('stats_analysis')) {
      featureWidgets.add(_buildFeatureItem(
        icon: Icons.insert_chart,
        title: 'Detaylı istatistik analizi',
        isActive: features['stats_analysis'] ?? false,
      ));
    }
    
    if (features.containsKey('priority_support')) {
      featureWidgets.add(_buildFeatureItem(
        icon: Icons.support_agent,
        title: 'Öncelikli destek',
        isActive: features['priority_support'] ?? false,
      ));
    }
    
    if (features.containsKey('exclusive_items')) {
      featureWidgets.add(_buildFeatureItem(
        icon: Icons.card_giftcard,
        title: 'Özel kozmetik ürünler',
        isActive: features['exclusive_items'] ?? false,
      ));
    }
    
    // En fazla 3 özellik göster
    return Column(
      children: featureWidgets.take(3).toList(),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required bool isActive,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: isActive ? Colors.white : Colors.white.withOpacity(0.3),
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: isActive ? Colors.white : Colors.white.withOpacity(0.3),
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            isActive ? Icons.check_circle : Icons.check_circle_outline,
            color: isActive ? Colors.green : Colors.white.withOpacity(0.3),
            size: 14,
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumButton({
    required String title,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.amber,
              Colors.purple,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _showPremiumPackages(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Premium Paketleri',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              _buildPackageOption(
                title: 'Aylık Premium',
                price: '9.99',
                duration: '1 Ay',
                package: 'monthly',
              ),
              const SizedBox(height: 12),
              _buildPackageOption(
                title: 'Yıllık Premium',
                price: '99.99',
                duration: '1 Yıl',
                package: 'yearly',
                isBestValue: true,
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.withOpacity(0.2),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'İptal',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPackageOption({
    required String title,
    required String price,
    required String duration,
    required String package,
    bool isBestValue = false,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _purchasePremium(package);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.amber.withOpacity(isBestValue ? 0.6 : 0.4),
              Colors.purple.withOpacity(isBestValue ? 0.6 : 0.4),
            ],
          ),
          border: Border.all(
            color: isBestValue 
                ? Colors.amber
                : Colors.white.withOpacity(0.2),
            width: isBestValue ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
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
                  Text(
                    duration,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$price ₺',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (isBestValue)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.green.withOpacity(0.3),
                    ),
                    child: const Text(
                      'En iyi değer',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}