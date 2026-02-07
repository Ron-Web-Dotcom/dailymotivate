import 'package:flutter/material.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/category_detail_screen/category_detail_screen.dart';
import '../presentation/settings_screen/settings_screen.dart';
import '../presentation/favorites_screen/favorites_screen.dart';
import '../presentation/home_screen/home_screen.dart';
import '../presentation/categories_screen/categories_screen.dart';

class AppRoutes {
  // TODO: Add your routes here
  static const String initial = '/';
  static const String splash = '/splash-screen';
  static const String categoryDetail = '/category-detail-screen';
  static const String settings = '/settings-screen';
  static const String favorites = '/favorites-screen';
  static const String home = '/home-screen';
  static const String categories = '/categories-screen';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SplashScreen(),
    splash: (context) => const SplashScreen(),
    categoryDetail: (context) => const CategoryDetailScreen(),
    settings: (context) => const SettingsScreen(),
    favorites: (context) => const FavoritesScreen(),
    home: (context) => const HomeScreen(),
    categories: (context) => const CategoriesScreen(),
    // TODO: Add your other routes here
  };
}
