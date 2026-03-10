import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../providers/trip_provider.dart';
import '../../models/trip_model.dart';
import '../../core/constants/app_constants.dart';
import 'package:intl/intl.dart';

class TripsTab extends StatefulWidget {
  const TripsTab({super.key});

  @override
  State<TripsTab> createState() => _TripsTabState();
}

class _TripsTabState extends State<TripsTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final tripProvider = Provider.of<TripProvider>(context, listen: false);
    // Load all trip data in parallel for better performance
    await Future.wait([
      tripProvider.loadActiveTrip(refresh: true),
      tripProvider.loadQueuedTrips(refresh: true),
      tripProvider.loadTripHistory(refresh: true),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.trips),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: AppLocalizations.of(context)!.active),
            Tab(text: AppLocalizations.of(context)!.queued),
            Tab(text: AppLocalizations.of(context)!.history),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildActiveTab(),
            _buildQueuedTab(),
            _buildHistoryTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTab() {
    return Consumer<TripProvider>(
      builder: (context, tripProvider, _) {
        if (tripProvider.isLoading && tripProvider.activeTrip == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (tripProvider.activeTrip == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.local_shipping_outlined,
                  size: 64.0,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: 16.0),
                Text(
                  AppLocalizations.of(context)!.noActiveTrip,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  AppLocalizations.of(context)!.activeTripsWillAppearHere,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: _buildTripCard(context, tripProvider.activeTrip!),
        );
      },
    );
  }

  Widget _buildQueuedTab() {
    return Consumer<TripProvider>(
      builder: (context, tripProvider, _) {
        if (tripProvider.isLoading && tripProvider.queuedTrips.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (tripProvider.queuedTrips.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.queue_outlined,
                  size: 64.0,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: 16.0),
                Text(
                  AppLocalizations.of(context)!.noQueuedTrips,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  AppLocalizations.of(context)!.queuedTripsWillAppearHere,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          itemCount: tripProvider.queuedTrips.length,
          itemBuilder: (context, index) {
            final trip = tripProvider.queuedTrips[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _buildTripCard(context, trip),
            );
          },
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    return Consumer<TripProvider>(
      builder: (context, tripProvider, _) {
        if (tripProvider.isLoading && tripProvider.tripHistory.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (tripProvider.tripHistory.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history_outlined,
                  size: 64.0,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: 16.0),
                Text(
                  AppLocalizations.of(context)!.noTripHistory,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  AppLocalizations.of(context)!.completedTripsWillAppearHere,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          itemCount: tripProvider.tripHistory.length,
          itemBuilder: (context, index) {
            final trip = tripProvider.tripHistory[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _buildTripCard(context, trip),
            );
          },
        );
      },
    );
  }

  Widget _buildTripCard(BuildContext context, TripModel trip) {
    final textTheme = Theme.of(context).textTheme;
    final dateFormat = DateFormat('MMM dd, yyyy');

    return InkWell(
      onTap: () {
        if (trip.status == AppConstants.tripStatusActive) {
          Navigator.of(context).pushNamed(
            '/active-trip',
            arguments: trip.id,
          );
        } else if (trip.status == AppConstants.tripStatusPlanned) {
          // Show start trip dialog
          _showStartTripDialog(context, trip);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: AppColors.offWhite,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: AppColors.dividerGrey, width: 1.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (trip.containerNumber != null)
                        Text(
                          trip.containerNumber!,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      if (trip.reference != null) ...[
                        const SizedBox(height: 4.0),
                        Text(
                          trip.reference!,
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                _buildStatusChip(trip.status),
              ],
            ),
            const SizedBox(height: 12.0),
            Row(
              children: [
                Icon(Icons.local_shipping, size: 16.0, color: AppColors.textSecondary),
                const SizedBox(width: 4.0),
                Text(
                  trip.tripType,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 16.0),
                Icon(Icons.calendar_today, size: 16.0, color: AppColors.textSecondary),
                const SizedBox(width: 4.0),
                Text(
                  dateFormat.format(trip.createdAt),
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            if (trip.milestones.isNotEmpty) ...[
              const SizedBox(height: 12.0),
              LinearProgressIndicator(
                value: trip.milestones.length / 5.0,
                backgroundColor: AppColors.dividerGrey,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
              const SizedBox(height: 4.0),
              Text(
                '${trip.milestones.length}/5 milestones completed',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case AppConstants.tripStatusActive:
        color = AppColors.info;
        break;
      case AppConstants.tripStatusCompleted:
        color = AppColors.success;
        break;
      case AppConstants.tripStatusPodPending:
        color = AppColors.warning;
        break;
      case AppConstants.tripStatusPlanned:
        color = AppColors.textSecondary;
        break;
      default:
        color = AppColors.textMuted;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(
          color: color,
          fontSize: 12.0,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showStartTripDialog(BuildContext context, TripModel trip) {
    final tripProvider = Provider.of<TripProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Trip'),
        content: Text('Do you want to start trip ${trip.containerNumber ?? trip.tripId}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await tripProvider.startTrip(trip.id);
              if (context.mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Trip started successfully!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
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
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }
}
