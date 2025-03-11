import 'package:flutter/material.dart';
import 'dart:ui';

class ProfileSettingsWidget extends StatelessWidget {
  final VoidCallback? onEditProfile;
  final VoidCallback? onChangeNickname;
  final VoidCallback? onSupport;
  final VoidCallback? onLogout;

  const ProfileSettingsWidget({
    super.key,
    this.onEditProfile,
    this.onChangeNickname,
    this.onSupport,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Color(0xFF5E60CE).withOpacity(0.3),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          const Row(
            children: [
              Icon(
                Icons.settings,
                color: Colors.white,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Ayarlar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Ayarlar Menüsü
          _buildSettingsItem(
            icon: Icons.edit,
            title: 'Profili Düzenle',
            onTap: onEditProfile,
          ),
          
          _buildSettingsItem(
            icon: Icons.person,
            title: 'Kullanıcı Adı Değiştir',
            onTap: onChangeNickname,
          ),
          
          _buildSettingsItem(
            icon: Icons.support_agent,
            title: 'Destek',
            onTap: onSupport,
          ),
          
          _buildSettingsItem(
            icon: Icons.exit_to_app,
            title: 'Çıkış Yap',
            color: Colors.red.shade300,
            onTap: onLogout,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    Color? color,
    VoidCallback? onTap,
  }) {
    final itemColor = color ?? Colors.white;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
        child: Row(
          children: [
            Icon(
              icon,
              color: itemColor,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: itemColor,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              color: itemColor.withOpacity(0.7),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}