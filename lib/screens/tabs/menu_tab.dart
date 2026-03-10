import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/trip_provider.dart';
import '../../providers/driver_provider.dart';

class MenuTab extends StatelessWidget {
  const MenuTab({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.menu),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            _buildMenuItem(
              context: context,
              icon: Icons.credit_card_outlined,
              title: AppLocalizations.of(context)!.fuelCards,
              onTap: () {
                Navigator.of(context).pushNamed('/fuel-cards');
              },
            ),
            _buildMenuItem(
              context: context,
              icon: Icons.local_shipping_outlined,
              title: AppLocalizations.of(context)!.trips,
              onTap: () {
                // Navigate to main scaffold with trips tab
                final navigator = Navigator.of(context);
                navigator.popUntil((route) => route.isFirst);
                navigator.pushReplacementNamed('/home');
                // Note: Tab switching will need to be handled differently
                // For now, this navigates to home, user can manually switch to trips
              },
            ),
            _buildMenuItem(
              context: context,
              icon: Icons.account_balance_wallet_outlined,
              title: AppLocalizations.of(context)!.wallet,
              onTap: () {
                Navigator.of(context).pushNamed('/wallet');
              },
            ),
            _buildMenuItem(
              context: context,
              icon: Icons.person_outline,
              title: AppLocalizations.of(context)!.profile,
              onTap: () {
                Navigator.of(context).pushNamed('/profile');
              },
            ),
            const SizedBox(height: 32.0),
            _buildLogoutButton(context, textTheme),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 4.0),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppColors.textPrimary,
              size: 24.0,
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textPrimary,
                    ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.textMuted,
              size: 20.0,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, TextTheme textTheme) {
    return SizedBox(
      height: 52.0,
      child: OutlinedButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(AppLocalizations.of(context)!.logout),
              content: Text(AppLocalizations.of(context)!.logoutConfirmation),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                TextButton(
                  onPressed: () async {
                    // Close dialog first
                    Navigator.of(context).pop();
                    
                    // Get providers before async operations
                    final navigatorContext = Navigator.of(context, rootNavigator: true);
                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                    final tripProvider = Provider.of<TripProvider>(context, listen: false);
                    final driverProvider = Provider.of<DriverProvider>(context, listen: false);
                    
                    // Perform logout
                    await authProvider.logout();
                    
                    // Clear other provider states
                    tripProvider.clearAll();
                    driverProvider.clearAll();
                    
                    // Small delay to ensure dialog is fully dismissed
                    await Future.delayed(const Duration(milliseconds: 100));
                    
                    // Navigate to login page using root navigator and clear navigation stack
                    navigatorContext.pushNamedAndRemoveUntil(
                      '/login',
                      (route) => false,
                    );
                  },
                  child: Text(
                    AppLocalizations.of(context)!.logout,
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              ],
            ),
          );
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.error),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        child: Text(
          AppLocalizations.of(context)!.logout,
          style: textTheme.labelLarge?.copyWith(
            color: AppColors.error,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

