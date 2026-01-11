import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'screens/login.dart';
import 'screens/language_selection.dart';
import 'screens/access_pending.dart';
import 'screens/main_scaffold.dart';
import 'screens/wallet.dart';
import 'screens/fuel_cards.dart';
import 'screens/profile.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Porttivo Driver',
      theme: AppTheme.lightTheme(),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/language-selection': (context) => const LanguageSelectionScreen(),
        '/access-pending': (context) => const AccessPendingScreen(),
        '/home': (context) => const MainScaffold(),
        '/wallet': (context) => const WalletScreen(),
        '/fuel-cards': (context) => const FuelCardsScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}
