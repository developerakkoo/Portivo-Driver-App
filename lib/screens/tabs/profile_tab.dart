import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/driver_provider.dart';
import '../../providers/trip_provider.dart';
import '../../core/constants/app_constants.dart';
import 'package:intl/intl.dart';
import '../../widgets/notification_app_bar_action.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
  }

  void _loadProfile() {
    final driverProvider = Provider.of<DriverProvider>(context, listen: false);
    driverProvider.loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.profileTitle),
        actions: const [NotificationAppBarAction()],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            _loadProfile();
          },
          child: Consumer<DriverProvider>(
            builder: (context, driverProvider, _) {
              if (driverProvider.isLoading && driverProvider.driver == null) {
                return const Center(child: CircularProgressIndicator());
              }

              final driver = driverProvider.driver;
              if (driver == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64.0, color: AppColors.error),
                      const SizedBox(height: 16.0),
                      Text(
                        'Failed to load profile',
                        style: textTheme.headlineSmall?.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (driverProvider.error != null) ...[
                        const SizedBox(height: 8.0),
                        Text(
                          driverProvider.error!,
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildProfileHeader(textTheme, driver),
                    const SizedBox(height: 32.0),
                    _buildProfileInfo(textTheme, driver),
                    const SizedBox(height: 24.0),
                    _buildLanguageSection(context, driver),
                    const SizedBox(height: 32.0),
                    _buildLogoutButton(context, textTheme),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(TextTheme textTheme, dynamic driver) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50.0,
          backgroundColor: AppColors.offWhite,
          child: Icon(
            Icons.person,
            size: 50.0,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 16.0),
        Text(
          driver.name ?? 'Driver',
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          'ID: ${driver.id.substring(0, 8)}...',
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileInfo(TextTheme textTheme, dynamic driver) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.offWhite,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.dividerGrey, width: 1.0),
      ),
      child: Column(
        children: [
          _buildInfoItem(
            icon: Icons.phone_outlined,
            label: 'Mobile Number',
            value: driver.mobile,
            textTheme: textTheme,
          ),
          const Divider(height: 1.0),
          if (driver.transporter != null)
            _buildInfoItem(
              icon: Icons.business_outlined,
              label: 'Transporter',
              value: driver.transporter.company ?? driver.transporter.name,
              textTheme: textTheme,
            ),
          if (driver.transporter != null) const Divider(height: 1.0),
          _buildInfoItem(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Wallet Balance',
            value: '₹${driver.walletBalance.toStringAsFixed(2)}',
            textTheme: textTheme,
          ),
          const Divider(height: 1.0),
          _buildInfoItem(
            icon: Icons.info_outline,
            label: 'Status',
            value: driver.status.toUpperCase(),
            textTheme: textTheme,
          ),
          const Divider(height: 1.0),
          _buildInfoItem(
            icon: Icons.calendar_today_outlined,
            label: 'Member Since',
            value: dateFormat.format(driver.createdAt),
            textTheme: textTheme,
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSection(BuildContext context, dynamic driver) {
    final textTheme = Theme.of(context).textTheme;
    final driverProvider = Provider.of<DriverProvider>(context, listen: false);

    final localizations = AppLocalizations.of(context)!;
    final languages = [
      {'code': AppConstants.languageEnglish, 'name': localizations.english},
      {'code': AppConstants.languageHindi, 'name': localizations.hindi},
      {'code': AppConstants.languageMarathi, 'name': localizations.marathi},
    ];

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.offWhite,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.dividerGrey, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.language, color: AppColors.primary, size: 24.0),
              const SizedBox(width: 8.0),
              Text(
                AppLocalizations.of(context)!.languagePreference,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          ...languages.map((lang) {
            return RadioListTile<String>(
              title: Text(lang['name']!),
              value: lang['code']!,
              groupValue: driver.language ?? AppConstants.languageEnglish,
              onChanged: driverProvider.isLoading
                  ? null
                  : (value) async {
                      if (value != null) {
                        final success = await driverProvider.updateLanguage(value);
                        if (context.mounted) {
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(AppLocalizations.of(context)!.languagePreferenceUpdated),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(driverProvider.error ?? AppLocalizations.of(context)!.failedToUpdateLanguage),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      }
                    },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required TextTheme textTheme,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.textPrimary,
            size: 24.0,
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  value,
                  style: textTheme.bodyLarge?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
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
                    Navigator.of(context).pop();

                    final navigatorContext = Navigator.of(context, rootNavigator: true);
                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                    final tripProvider = Provider.of<TripProvider>(context, listen: false);
                    final driverProvider = Provider.of<DriverProvider>(context, listen: false);

                    await authProvider.logout();
                    tripProvider.clearAll();
                    driverProvider.clearAll();

                    await Future.delayed(const Duration(milliseconds: 100));

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
