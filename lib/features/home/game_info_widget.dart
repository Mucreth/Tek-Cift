// lib/features/home/widgets/game_info_widget.dart
import 'package:flutter/material.dart';

class GameInfoWidget extends StatelessWidget {
  final String title; // Hala içeride tutuyoruz ama göstermiyoruz
  final String description;
  
  const GameInfoWidget({
    Key? key,
    required this.title,
    required this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75, // Buton genişliğiyle uyumlu
      ),
      child: Text(
        description,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 15, // Biraz daha büyük yazı boyutu
          fontWeight: FontWeight.w400, // Normal kalınlık
          color: Colors.grey[300],
          height: 1.4, // Satır aralığını arttırdım
        ),
      ),
    );
  }
}