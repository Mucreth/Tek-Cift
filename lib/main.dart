// lib/main.dart
import 'package:flutter/material.dart';
import 'package:handclash/features/auth/splash_screen.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Handclash',
      debugShowCheckedModeBanner: false, // Debug banner'ı kaldır
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5C6BC0), // Indigo tonu
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}