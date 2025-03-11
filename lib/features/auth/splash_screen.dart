// lib/features/auth/view/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:handclash/features/auth/auth_service.dart';
import 'package:handclash/features/home/home_screen.dart';
import 'package:handclash/shared/services/socket_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();
  final SocketService _socketService = SocketService();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

Future<void> _initializeApp() async {
    try {
      print('Starting auth process...');
      final authResult = await _authService.authenticateUser();
      print('Auth result: $authResult');  // Düzeltildi

      if (!authResult['success']) {
        print('Auth failed: ${authResult['message']}');  // Düzeltildi
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authResult['message']),
              action: SnackBarAction(
                label: 'Tekrar Dene',
                onPressed: _initializeApp,
              ),
            ),
          );
        }
        return;
      }

      print('Auth successful, connecting socket...');
      final user = authResult['user'];
      final deviceId = await _authService.getDeviceId();
      
      final socketConnected = await _socketService.connectAndAuthenticate(
        user['user_id'],
        deviceId,
      );

      print('Socket connected: $socketConnected');  // Düzeltildi

      if (!socketConnected) {
        throw Exception('Socket bağlantısı başarısız');
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
        );
      }
    } catch (e) {
      print('Error in _initializeApp: $e');  // Düzeltildi
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bir hata oluştu: $e'),
            action: SnackBarAction(
              label: 'Tekrar Dene',
              onPressed: _initializeApp,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'HANDCLASH',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ],
        ),
      ),
    );
  }
}