// lib/shared/widgets/custom_app_bar.dart
import 'package:flutter/material.dart';
import 'package:handclash/features/league/league_screen.dart';
import 'package:handclash/features/profile/profile_screen.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false, // Geri butonunu kaldır
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Sol - Lig Butonu
IconButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LeagueScreen()),
    );
  },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber[100],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emoji_events,
                color: Colors.amber,
              ),
            ),
          ),

          // Orta - Logo
          const Text(
            'HANDCLASH',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          // Sağ - Profil Butonu
IconButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
  },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                color: Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}