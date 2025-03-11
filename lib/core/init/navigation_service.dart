// lib/core/init/navigation_service.dart
import 'package:flutter/material.dart';

class NavigationService {
  static final NavigationService _instance = NavigationService._init();
  static NavigationService get instance => _instance;

  NavigationService._init();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey();

  Future<void> navigateToPage({required String path, Object? data}) async {
    await navigatorKey.currentState!.pushNamed(path, arguments: data);
  }

  void back() {
    navigatorKey.currentState!.pop();
  }
}