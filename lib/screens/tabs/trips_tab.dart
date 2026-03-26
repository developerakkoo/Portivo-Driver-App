import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/utils/helpers.dart';
import '../../providers/trip_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/trip_model.dart';
import '../../core/constants/app_constants.dart';
import '../../services/socket_service.dart';
import '../../widgets/notification_app_bar_action.dart';

class TripsTab extends StatefulWidget {
  const TripsTab({super.key});

  @override
  State<TripsTab> createState() => _TripsTabState();
}

class _TripsTabState extends State<TripsTab>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadData();
    }
  }

  List<TripModel> _getFilteredTrips(List<TripModel> trips) {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) return trips;
    return trips.where((trip) {
      final container = (trip.containerNumber ?? '').toLowerCase();
      final tripId = trip.tripId.toLowerCase();
      final ref = (trip.reference ?? '').toLowerCase();
      return container.contains(query) ||
          tripId.contains(query) ||
          ref.contains(query);
    }).toList();
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
        actions: [
          const NotificationAppBarAction(),
          Consumer<TripProvider>(
            builder: (context, tripProvider, _) {
              final socketService = SocketService();
              final state = socketService.connectionState;
              Color color;
              String tooltip;
              switch (state) {
                case SocketConnectionState.connected:
                  color = AppColors.success;
                  tooltip = 'Connected';
                  break;
                case SocketConnectionState.connecting:
                  color = AppColors.warning;
                  tooltip = 'Connecting...';
                  break;
                case SocketConnectionState.error:
                  color = AppColors.error;
                  tooltip = 'Connection error';
                  break;
                default:
                  color = AppColors.textMuted;
                  tooltip = 'Disconnected';
              }
              return Tooltip(
                message: tooltip,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Icon(
                    Icons.circle,
                    size: 10.0,
                    color: color,
                  ),
                ),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by container, trip ID, reference',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: AppLocalizations.of(context)!.active),
                  Tab(text: AppLocalizations.of(context)!.queued),
                  Tab(text: AppLocalizations.of(context)!.history),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActiveTab(),
          _buildQueuedTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildActiveTab() {
    return Consumer2<TripProvider, AuthProvider>(
      builder: (context, tripProvider, authProvider, _) {
        final currentDriverId = authProvider.user?.id;
        final activeTrip = tripProvider.activeTripForDriver(currentDriverId);
        final filteredActiveTrip = activeTrip == null
            ? null
            : (_getFilteredTrips([activeTrip]).isEmpty ? null : activeTrip);

        Widget content;
        if (tripProvider.isLoading && activeTrip == null) {
          content = const Center(child: CircularProgressIndicator());
        } else if (filteredActiveTrip == null) {
          content = Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 64.0,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: 16.0),
                Text(
                  _searchController.text.trim().isEmpty
                      ? AppLocalizations.of(context)!.noActiveTrip
                      : 'No trips match your search',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  _searchController.text.trim().isEmpty
                      ? AppLocalizations.of(context)!.activeTripsWillAppearHere
                      : 'Try a different search term',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          );
        } else {
          content = Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildTripCard(context, filteredActiveTrip),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadData,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: content,
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildQueuedTab() {
    return Consumer2<TripProvider, AuthProvider>(
      builder: (context, tripProvider, authProvider, _) {
        final currentDriverId = authProvider.user?.id;
        final queuedForDriver = currentDriverId != null
            ? tripProvider.queuedTrips
                .where((t) => t.driverId == currentDriverId)
                .toList()
            : tripProvider.queuedTrips;
        final filteredQueued = _getFilteredTrips(queuedForDriver);

        Widget content;
        if (tripProvider.isLoading && filteredQueued.isEmpty) {
          content = const Center(child: CircularProgressIndicator());
        } else if (filteredQueued.isEmpty) {
          final hasSearch = _searchController.text.trim().isNotEmpty;
          content = Center(
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
                  hasSearch ? 'No trips match your search' : AppLocalizations.of(context)!.noQueuedTrips,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  hasSearch ? 'Try a different search term' : AppLocalizations.of(context)!.queuedTripsWillAppearHere,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          );
        } else {
          content = ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            itemCount: filteredQueued.length,
            itemBuilder: (context, index) {
              final trip = filteredQueued[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: _buildTripCard(context, trip),
              );
            },
          );
        }

        return RefreshIndicator(
          onRefresh: _loadData,
          child: filteredQueued.isEmpty
              ? LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: content,
                      ),
                    );
                  },
                )
              : content,
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    return Consumer2<TripProvider, AuthProvider>(
      builder: (context, tripProvider, authProvider, _) {
        final currentDriverId = authProvider.user?.id;
        final historyForDriver = currentDriverId != null
            ? tripProvider.tripHistory
                .where((t) => t.driverId == currentDriverId)
                .toList()
            : tripProvider.tripHistory;
        final filteredHistory = _getFilteredTrips(historyForDriver);

        Widget content;
        if (tripProvider.isLoading && filteredHistory.isEmpty) {
          content = const Center(child: CircularProgressIndicator());
        } else if (filteredHistory.isEmpty) {
          final hasSearch = _searchController.text.trim().isNotEmpty;
          content = Center(
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
                  hasSearch ? 'No trips match your search' : AppLocalizations.of(context)!.noTripHistory,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  hasSearch ? 'Try a different search term' : AppLocalizations.of(context)!.completedTripsWillAppearHere,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          );
        } else {
          content = ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            itemCount: filteredHistory.length,
            itemBuilder: (context, index) {
              final trip = filteredHistory[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: _buildTripCard(context, trip),
              );
            },
          );
        }

        return RefreshIndicator(
          onRefresh: _loadData,
          child: filteredHistory.isEmpty
              ? LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: content,
                      ),
                    );
                  },
                )
              : content,
        );
      },
    );
  }

  Widget _buildTripCard(BuildContext context, TripModel trip) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: () {
        if (trip.status == AppConstants.tripStatusActive) {
          Navigator.of(context).pushNamed(
            '/active-trip',
            arguments: trip.id,
          );
        } else if (trip.status == AppConstants.tripStatusPlanned) {
          _showStartTripDialog(context, trip);
        } else if (trip.status == AppConstants.tripStatusPodPending) {
          Navigator.of(context).pushNamed(
            '/active-trip',
            arguments: trip.id,
          );
        } else if (trip.status == AppConstants.tripStatusCompleted ||
            trip.status == AppConstants.tripStatusCancelled) {
          Navigator.of(context).pushNamed(
            '/trip-detail',
            arguments: trip.id,
          );
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
                      if (trip.tripId.isNotEmpty) ...[
                        const SizedBox(height: 4.0),
                        Text(
                          trip.tripId,
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      if (trip.reference != null) ...[
                        const SizedBox(height: 4.0),
                        Text(
                          trip.reference!,
                          style: textTheme.bodySmall?.copyWith(
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
            const SizedBox(height: 16.0),
            _buildTripInfoRow(
              icon: Icons.inventory_2_outlined,
              label: 'Type',
              value: Helpers.getTripTypeLabel(trip.tripType),
              textTheme: textTheme,
            ),
            const SizedBox(height: 12.0),
            if (trip.pickupLocation != null || trip.dropLocation != null)
              Row(
                children: [
                  if (trip.pickupLocation != null)
                    Expanded(
                      child: _buildTripInfoRow(
                        icon: Icons.location_on_outlined,
                        label: 'Origin',
                        value: trip.pickupLocation!.address ?? 'Location',
                        textTheme: textTheme,
                      ),
                    ),
                  if (trip.pickupLocation != null && trip.dropLocation != null) ...[
                    const SizedBox(width: 16.0),
                    Icon(
                      Icons.arrow_forward,
                      color: AppColors.textSecondary,
                      size: 20.0,
                    ),
                    const SizedBox(width: 16.0),
                  ],
                  if (trip.dropLocation != null)
                    Expanded(
                      child: _buildTripInfoRow(
                        icon: Icons.location_on,
                        label: 'Destination',
                        value: trip.dropLocation!.address ?? 'Location',
                        textTheme: textTheme,
                      ),
                    ),
                ],
              ),
            if (trip.pickupLocation != null || trip.dropLocation != null)
              const SizedBox(height: 12.0),
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    color: AppColors.primary,
                    size: 20.0,
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    'Created: ${Helpers.formatDateTime(trip.createdAt)}',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
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

  Widget _buildTripInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required TextTheme textTheme,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18.0, color: AppColors.textSecondary),
        const SizedBox(width: 8.0),
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
              const SizedBox(height: 2.0),
              Text(
                value,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
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
      case AppConstants.tripStatusCancelled:
        color = AppColors.error;
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
        Helpers.getStatusLabel(status),
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
