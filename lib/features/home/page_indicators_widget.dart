// lib/features/home/widgets/page_indicators_widget.dart
import 'package:flutter/material.dart';

class PageIndicatorsWidget extends StatelessWidget {
  final int currentPage;
  final int pageCount;
  
  const PageIndicatorsWidget({
    Key? key,
    required this.currentPage,
    required this.pageCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      // clipBehavior: Clip.none - Bu özelliği Stack'e vereceğiz
      child: Stack(
        // Taşmayı engellememek için
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Sayfa indikatörleri - Ekranın tam ortasında
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                pageCount,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  width: index == currentPage ? 24.0 : 8.0,
                  height: 8.0,
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: index == currentPage
                        ? Colors.white
                        : Colors.white.withOpacity(0.4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}