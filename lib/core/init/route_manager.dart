// lib/core/init/route_manager.dart
import 'package:flutter/material.dart';
import 'package:handclash/features/auth/splash_screen.dart';
import 'package:handclash/features/home/home_screen.dart';
import 'package:handclash/features/league/league_screen.dart';
import 'package:handclash/features/profile/profile_screen.dart';
import '../constants/app_constants.dart';

class RouteManager {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppConstants.splashRoute:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      
      case AppConstants.homeRoute:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      
      case AppConstants.profileRoute:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      
      case AppConstants.leagueRoute:
        return MaterialPageRoute(builder: (_) => const LeagueScreen());
      
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Route ${settings.name} bulunamadı'),
            ),
          ),
        );
    }
  }
}