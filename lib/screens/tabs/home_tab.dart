import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../providers/trip_provider.dart';
import '../../providers/driver_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/trip_model.dart';
import '../../core/navigation/app_navigation.dart';
import '../../widgets/notification_app_bar_action.dart';
import '../../widgets/background_location_disclosure.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final tripProvider = Provider.of<TripProvider>(context, listen: false);
    final driverProvider = Provider.of<DriverProvider>(context, listen: false);
    
    // Load all data in parallel for better performance
    await Future.wait([
      tripProvider.loadActiveTrip(refresh: true),
      tripProvider.loadQueuedTrips(refresh: true),
      driverProvider.loadProfile(refresh: true),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Porttivo Driver'),
        actions: const [NotificationAppBarAction()],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Welcome Section
                Consumer<DriverProvider>(
                  builder: (context, driverProvider, _) {
                    final driverName = driverProvider.driver?.name ?? 'Driver';
                    return _buildWelcomeSection(textTheme, driverName);
                  },
                ),
                const SizedBox(height: 32.0),

                // Active Trip Card (only when trip is assigned to this driver)
                Consumer2<TripProvider, AuthProvider>(
                  builder: (context, tripProvider, authProvider, _) {
                    final forDriver = tripProvider.activeTripForDriver(
                      authProvider.user?.id,
                    );
                    if (forDriver != null) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildActiveTripCard(context, forDriver),
                          const SizedBox(height: 24.0),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

                // Quick Stats
                Consumer3<TripProvider, DriverProvider, AuthProvider>(
                  builder: (context, tripProvider, driverProvider, authProvider, _) {
                    final forDriver = tripProvider.activeTripForDriver(
                      authProvider.user?.id,
                    );
                    return _buildQuickStats(
                      context,
                      textTheme,
                      forDriver != null ? 1 : 0,
                      tripProvider.tripHistory.length,
                      driverProvider.driver?.walletBalance ?? 0.0,
                    );
                  },
                ),
                const SizedBox(height: 32.0),

                // Queued Trips
                Consumer<TripProvider>(
                  builder: (context, tripProvider, _) {
                    if (tripProvider.queuedTrips.isNotEmpty) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Queued Trips',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16.0),
                          ...tripProvider.queuedTrips.map((trip) => Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: InkWell(
                              onTap: () {
                                _showStartTripDialog(context, trip);
                              },
                              child: _buildQueuedTripCard(
                                context,
                                trip,
                                highlight: tripProvider.isQueuedTripHighlighted(trip.id),
                              ),
                            ),
                          )),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(TextTheme textTheme, String driverName) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: AppColors.offWhite,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.dividerGrey, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.welcomeBackWithName(driverName),
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            AppLocalizations.of(context)!.readyToStartYourDay,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTripCard(BuildContext context, TripModel trip) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: () {
        Navigator.of(context).pushNamed(
          '/active-trip',
          arguments: trip.id,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: AppColors.primary, width: 2.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.inventory_2, color: AppColors.primary, size: 24.0),
                const SizedBox(width: 8.0),
                Text(
                  AppLocalizations.of(context)!.activeTrip,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            if (trip.containerNumber != null)
              Text(
                '${AppLocalizations.of(context)!.container}: ${trip.containerNumber}',
                style: textTheme.bodyLarge?.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            if (trip.reference != null) ...[
              const SizedBox(height: 4.0),
              Text(
                '${AppLocalizations.of(context)!.reference}: ${trip.reference}',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 12.0),
            Text(
              AppLocalizations.of(context)!.tapToViewDetails,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.primary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueuedTripCard(
    BuildContext context,
    TripModel trip, {
    bool highlight = false,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final statusLabel = trip.driverAcceptedAt != null ? 'Accepted' : 'Pending';
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.offWhite,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: highlight ? Colors.green : AppColors.dividerGrey,
          width: highlight ? 2.5 : 1.0,
        ),
        boxShadow: highlight
            ? [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.25),
                  blurRadius: 10,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Icon(Icons.queue, color: AppColors.textSecondary, size: 20.0),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        trip.containerNumber ?? trip.tripId,
                        style: textTheme.bodyLarge?.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                      decoration: BoxDecoration(
                        color: trip.driverAcceptedAt != null
                            ? AppColors.success.withOpacity(0.2)
                            : AppColors.textMuted.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        statusLabel,
                        style: textTheme.labelSmall?.copyWith(
                          color: trip.driverAcceptedAt != null
                              ? AppColors.success
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (trip.reference != null) ...[
                  const SizedBox(height: 4.0),
                  Text(
                    trip.reference!,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, TextTheme textTheme, int activeTrips, int completedTrips, double walletBalance) {
    final localizations = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.inventory_2,
            value: activeTrips.toString(),
            label: localizations.activeTrips,
            textTheme: textTheme,
            onTap: () => AppNavigation.instance.openTrips(subTab: 0),
          ),
        ),
        const SizedBox(width: 16.0),
        Expanded(
          child: _buildStatCard(
            icon: Icons.check_circle_outline,
            value: completedTrips.toString(),
            label: localizations.completed,
            textTheme: textTheme,
            onTap: () => AppNavigation.instance.openTrips(subTab: 2),
          ),
        ),
        const SizedBox(width: 16.0),
        Expanded(
          child: _buildStatCard(
            icon: Icons.account_balance_wallet,
            value: '₹${walletBalance.toStringAsFixed(0)}',
            label: localizations.wallet,
            textTheme: textTheme,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required TextTheme textTheme,
    VoidCallback? onTap,
  }) {
    final card = Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.offWhite,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.dividerGrey, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 32.0, color: AppColors.primary),
          const SizedBox(height: 12.0),
          Text(
            value,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.0),
      child: card,
    );
  }

  void _showStartTripDialog(BuildContext context, TripModel trip) {
    final tripProvider = Provider.of<TripProvider>(context, listen: false);
    final needsAccept = trip.driverAcceptedAt == null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(needsAccept ? 'Accept Trip' : 'Start Trip'),
        content: Text(
          needsAccept
              ? 'Do you want to accept trip ${trip.containerNumber ?? trip.tripId}? You can start it after accepting.'
              : 'Do you want to start trip ${trip.containerNumber ?? trip.tripId}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              if (needsAccept) {
                final success = await tripProvider.acceptTrip(trip.id);
                if (context.mounted) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Trip accepted! You can now start it.'),
                        backgroundColor: AppColors.success,
                    ),
                    );
                    // Show dialog again with Start Trip option
                    final updatedList = tripProvider.queuedTrips
                        .where((t) => t.id == trip.id)
                        .toList();
                    if (updatedList.isNotEmpty) {
                      _showStartTripDialog(context, updatedList.first);
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(tripProvider.error ?? 'Failed to accept trip'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              } else {
                final success = await tripProvider.startTrip(trip.id);
                if (context.mounted) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Trip started successfully!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                    await BackgroundLocationConsent.ensure(context);
                    if (!context.mounted) return;
                    Navigator.of(context).pushNamed(
                      '/active-trip',
                      arguments: trip.id,
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(tripProvider.error ?? 'Failed to start trip'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              }
            },
            child: Text(needsAccept ? 'Accept' : 'Start'),
          ),
        ],
      ),
    );
  }
}

