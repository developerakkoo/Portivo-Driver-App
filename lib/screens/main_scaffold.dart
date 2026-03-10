import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/localization/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../services/socket_service.dart';
import 'tabs/home_tab.dart';
import 'tabs/trips_tab.dart';
import 'tabs/menu_tab.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _connectSocket();
    });
  }

  void _connectSocket() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user != null) {
      final socketService = SocketService();
      socketService.connect().then((_) {
        socketService.joinDriverRoom(user.id);
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
        icon: const Icon(Icons.local_shipping_outlined),
        selectedIcon: const Icon(Icons.local_shipping),
        label: localizations.trips,
      ),
      NavigationDestination(
        icon: const Icon(Icons.menu_outlined),
        selectedIcon: const Icon(Icons.menu),
        label: localizations.menu,
      ),
    ];
  }

  void _onDestinationSelected(int index) {
    if (index != _currentIndex) {
      setState(() {
        _currentIndex = index;
      });
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
          MenuTab(),
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

