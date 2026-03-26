import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/localization/app_localizations.dart';
import 'providers/auth_provider.dart';
import 'providers/driver_provider.dart';
import 'providers/trip_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/notification_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login.dart';
import 'screens/language_selection.dart';
import 'screens/access_pending.dart';
import 'screens/main_scaffold.dart';
import 'screens/wallet.dart';
import 'screens/fuel_cards.dart';
import 'screens/fuel_qr_screen.dart';
import 'screens/profile.dart';
import 'screens/active_trip_screen.dart';
import 'screens/pod_upload_screen.dart';
import 'screens/trip_detail_screen.dart';
import 'screens/notifications_screen.dart';
import 'services/storage_service.dart';

/// Custom delegate that uses a specific locale regardless of MaterialApp's locale
class _AppLocalizationsDelegateWithLocale extends LocalizationsDelegate<AppLocalizations> {
  final Locale locale;
  
  const _AppLocalizationsDelegateWithLocale(this.locale);

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale _) async {
    return AppLocalizations(this.locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegateWithLocale old) => old.locale != locale;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await StorageService().init();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),
        ChangeNotifierProvider(
          create: (context) {
            final driverProvider = DriverProvider();
            final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
            driverProvider.setLocaleProvider(localeProvider);
            return driverProvider;
          },
        ),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(
          create: (context) {
            final notifications = Provider.of<NotificationProvider>(context, listen: false);
            return TripProvider(
              onTripDriverAssigned: () {
                notifications.refreshUnreadCount();
              },
            );
          },
        ),
      ],
      child: Consumer2<LocaleProvider, DriverProvider>(
        builder: (context, localeProvider, driverProvider, _) {
          // Load locale from driver profile when available
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (driverProvider.driver != null && mounted) {
              localeProvider.loadLocaleFromProfile(driverProvider);
            }
          });

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Porttivo Driver',
            theme: AppTheme.lightTheme(),
            // Use English locale for Material/Cupertino widgets (they don't support hi/mr)
            // but our custom AppLocalizations will still provide translations for hi/mr
            locale: const Locale('en'),
            supportedLocales: const [
              Locale('en'),
              Locale('hi'),
              Locale('mr'),
            ],
            localizationsDelegates: [
              // Use custom delegate that loads AppLocalizations with driver's preferred locale
              // even though MaterialApp locale is 'en' (for Material widget compatibility)
              _AppLocalizationsDelegateWithLocale(
                localeProvider.currentLocale ?? const Locale('en'),
              ),
            ],
            initialRoute: '/splash',
            routes: {
              '/splash': (context) => const SplashScreen(),
              '/login': (context) => const LoginScreen(),
              '/language-selection': (context) => const LanguageSelectionScreen(),
              '/access-pending': (context) => const AccessPendingScreen(),
              '/home': (context) => const MainScaffold(),
              '/wallet': (context) => const WalletScreen(),
              '/fuel-cards': (context) => const FuelCardsScreen(),
              '/fuel-qr': (context) => const FuelQRScreen(),
              '/profile': (context) => const ProfileScreen(),
              '/notifications': (context) => const NotificationsScreen(),
            },
            onGenerateRoute: (settings) {
              if (settings.name == '/active-trip') {
                final tripId = settings.arguments as String;
                return MaterialPageRoute(
                  builder: (_) => ActiveTripScreen(tripId: tripId),
                );
              }
              if (settings.name == '/trip-detail') {
                final tripId = settings.arguments as String;
                return MaterialPageRoute(
                  builder: (_) => TripDetailScreen(),
                  settings: RouteSettings(
                    name: '/trip-detail',
                    arguments: tripId,
                  ),
                );
              }
              if (settings.name == '/pod-upload') {
                final tripId = settings.arguments as String;
                return MaterialPageRoute(
                  builder: (_) => PODUploadScreen(tripId: tripId),
                );
              }
              return null;
            },
          );
        },
      ),
    );
  }
}

