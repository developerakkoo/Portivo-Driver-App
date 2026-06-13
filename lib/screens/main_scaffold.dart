import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/localization/app_localizations.dart';
import '../core/navigation/app_navigation.dart';
import '../providers/auth_provider.dart';
import '../providers/driver_provider.dart';
import '../providers/notification_provider.dart';
import '../services/socket_service.dart';
import '../services/device_permission_service.dart';
import '../widgets/device_permission_modal.dart';
import 'tabs/home_tab.dart';
import 'tabs/trips_tab.dart';
import 'tabs/profile_tab.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;
  final DevicePermissionService _devicePermissionService = DevicePermissionService();

  @override
  void initState() {
    super.initState();
    _currentIndex = AppNavigation.instance.bottomIndex;
    AppNavigation.instance.addListener(_onNavChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _connectSocket();
      _maybeShowPermissionModal();
      _syncNotifications();
    });
  }

  @override
  void dispose() {
    AppNavigation.instance.removeListener(_onNavChanged);
    super.dispose();
  }

  void _onNavChanged() {
    if (!mounted) return;
    if (_currentIndex != AppNavigation.instance.bottomIndex) {
      setState(() {
        _currentIndex = AppNavigation.instance.bottomIndex;
      });
    }
  }

  Future<void> _syncNotifications() async {
    if (!mounted) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.isAuthenticated) {
      final notifications = Provider.of<NotificationProvider>(context, listen: false);
      await notifications.syncUnreadBadge();
    }
  }

  Future<void> _maybeShowPermissionModal() async {
    if (!mounted) return;
    try {
      final show = await _devicePermissionService.shouldShowLoginPermissionModal();
      if (!mounted || !show) return;
      await DevicePermissionModal.show(context);
    } catch (e) {
      if (kDebugMode) {
        print('MainScaffold: permission modal: $e');
      }
    }
  }

  void _connectSocket() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user != null) {
      final socketService = SocketService();
      socketService.connect().then((_) {
        socketService.joinDriverRoom(user.id);
      });
    } else if (authProvider.isAuthenticated) {
      final driverProvider = Provider.of<DriverProvider>(context, listen: false);
      driverProvider.loadProfile(refresh: true).then((_) {
        final d = driverProvider.driver;
        if (d != null && mounted) {
          authProvider.syncUserFromDriver(d);
          final socketService = SocketService();
          socketService.connect().then((_) {
            socketService.joinDriverRoom(d.id);
          });
        }
      });
    }
  }

  List<NavigationDestination> _buildDestinations(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return [
      NavigationDestination(
        icon: const Icon(Icons.home_outlined),
        selectedIcon: const Icon(Icons.home),
        label: localizations.home,
      ),
      NavigationDestination(
        icon: const Icon(Icons.inventory_2_outlined),
        selectedIcon: const Icon(Icons.inventory_2),
        label: localizations.trips,
      ),
      NavigationDestination(
        icon: const Icon(Icons.person_outline),
        selectedIcon: const Icon(Icons.person),
        label: localizations.profile,
      ),
    ];
  }

  void _onDestinationSelected(int index) {
    if (index != _currentIndex) {
      AppNavigation.instance.setBottomIndex(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          HomeTab(),
          TripsTab(),
          ProfileTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onDestinationSelected,
        backgroundColor: AppColors.background,
        elevation: 0,
        indicatorColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        animationDuration: const Duration(milliseconds: 200),
        destinations: _buildDestinations(context),
        height: 70.0,
      ),
    );
  }
}

