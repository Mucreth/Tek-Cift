// lib/features/game/widgets/game_action_bar.dart - Düzeltme
// Rakip için takım rengine göre arkaplan rengini değiştirme

import 'package:flutter/material.dart';
import 'package:handclash/core/constants/app_colors.dart';
import 'package:handclash/features/game/game_enums.dart';

class GameActionBar extends StatelessWidget {
 final String playerName;
 final String winRate;
 final int blockJokerCount;
 final int blindJokerCount;
 final int betJokerCount;
 final Set<JokerType> usedJokers;
 final JokerType? activeJoker;
 final VoidCallback? onAddFriend;
 final VoidCallback? onChat;
 final bool isGreenTeam; // Rakip için takım rengi parametresi eklendi

 const GameActionBar({
   Key? key,
   required this.playerName,
   required this.winRate,
   required this.blockJokerCount,
   required this.blindJokerCount,
   required this.betJokerCount,
   required this.usedJokers,
   required this.isGreenTeam, // Rakip için takım rengi parametresi zorunlu yapıldı
   this.activeJoker,
   this.onAddFriend,
   this.onChat,
 }) : super(key: key);

 @override
 Widget build(BuildContext context) {
   // Takım rengine göre arkaplan rengi seçimi
   final Color backgroundColor = isGreenTeam 
       ? AppColors.greenSecondary  // Yeşil takım için
       : AppColors.redSecondary;   // Kırmızı takım için

   // Takım rengine göre bilgi paneli rengi seçimi
   final Color infoPanelColor = isGreenTeam
       ? const Color(0xFF192418)  // Yeşil takım için koyu yeşil
       : const Color(0xFF2A1111); // Kırmızı takım için koyu kırmızı

   return Container(
     margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
     padding: const EdgeInsets.all(10),
     decoration: ShapeDecoration(
       color: backgroundColor, // Dinamik renk kullanımı
       shape: const RoundedRectangleBorder(
         borderRadius: BorderRadius.only(
           topLeft: Radius.circular(20),
           topRight: Radius.circular(20),
           bottomLeft: Radius.circular(0),
           bottomRight: Radius.circular(0),
         ),
       ),
     ),
     child: Column(
       children: [
         // Oyuncu bilgisi alanı
         Container(
           width: double.infinity,
           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
           decoration: ShapeDecoration(
             color: infoPanelColor, // Dinamik renk kullanımı
             shape: RoundedRectangleBorder(
               borderRadius: BorderRadius.circular(10),
             ),
           ),
           child: Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               Text(
                 playerName,
                 style: const TextStyle(
                   color: Colors.white,
                   fontSize: 16,
                   fontWeight: FontWeight.w600,
                   height: 1,
                 ),
               ),
               Text(
                 'Win Rate: $winRate',
                 style: const TextStyle(
                   color: Colors.white,
                   fontSize: 16,
                   fontWeight: FontWeight.w400,
                   height: 1,
                 ),
               ),
             ],
           ),
         ),
       ],
     ),
   );
 }

 Widget _buildJokerIndicator(JokerType type, IconData icon, int count, Color color) {
   final bool isUsed = usedJokers.contains(type);
   final bool isActive = activeJoker == type;
   
   return Container(
     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
     decoration: BoxDecoration(
       color: isUsed 
           ? Colors.grey.withOpacity(0.2) 
           : color.withOpacity(0.2),
       borderRadius: BorderRadius.circular(10),
       border: isActive ? Border.all(
         color: color,
         width: 2,
       ) : null,
       boxShadow: isActive ? [
         BoxShadow(
           color: color.withOpacity(0.5),
           blurRadius: 6,
           spreadRadius: 1,
         ),
       ] : null,
     ),
     child: Row(
       children: [
         Icon(
           icon,
           color: isUsed ? Colors.grey : color,
           size: 18,
         ),
         const SizedBox(width: 4),
         Text(
           count.toString(),
           style: TextStyle(
             color: isUsed ? Colors.grey : color,
             fontSize: 14,
             fontWeight: FontWeight.bold,
           ),
         ),
       ],
     ),
   );
 }
}