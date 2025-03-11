import 'package:flutter/material.dart';
import 'dart:ui';

class GoldIndicatorWidget extends StatelessWidget {
  final int gold;
  final double height;
  final bool showIcon;
  final bool showBorder;

  const GoldIndicatorWidget({
    super.key,
    required this.gold,
    this.height = 40,
    this.showIcon = true,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          height: height,
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
            border: showBorder ? Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 0.5,
            ) : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showIcon) ...[
                Icon(Icons.monetization_on, color: Colors.amber[300], size: height * 0.5),
                const SizedBox(width: 4),
              ],
              Text(
                _formatGold(gold),
                style: TextStyle(
                  fontSize: height * 0.35,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[300],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Büyük altın miktarlarını formatla (örn: 1.2M, 350K gibi)
  String _formatGold(int gold) {
    if (gold >= 1000000) {
      return '${(gold / 1000000).toStringAsFixed(1)}M';
    } else if (gold >= 1000) {
      return '${(gold / 1000).toStringAsFixed(1)}K';
    } else {
      return gold.toString();
    }
  }
}