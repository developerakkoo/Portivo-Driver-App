import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/helpers.dart';
import '../core/config/api_config.dart';
import '../core/constants/app_constants.dart';
import '../models/trip_model.dart';
import '../providers/trip_provider.dart';

class TripDetailScreen extends StatefulWidget {
  const TripDetailScreen({super.key});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  String? _tripId;
  TripModel? _trip;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTrip();
    });
  }

  Future<void> _loadTrip() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is! String) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Invalid trip ID';
        });
      }
      return;
    }

    _tripId = args;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tripProvider = context.read<TripProvider>();
      final trip = await tripProvider.getTripById(_tripId!);
      if (mounted) {
        setState(() {
          _trip = trip;
          _isLoading = false;
          _error = trip == null ? 'Trip not found' : null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (_isLoading && _trip == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Trip Details'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_trip == null && _error != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Trip Details'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64.0,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16.0),
                Text(
                  _error!,
                  style: textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24.0),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Go Back'),
                ),
                const SizedBox(height: 12.0),
                TextButton(
                  onPressed: _loadTrip,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Consumer<TripProvider>(
      builder: (context, tripProvider, _) {
        final trip = _tripId != null
            ? (tripProvider.getTripForDetail(_tripId!) ?? _trip)!
            : _trip!;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Trip Details'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadTrip,
                tooltip: 'Refresh',
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _loadTrip,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStatusCard(trip, textTheme),
                  const SizedBox(height: 24.0),
                  _buildSectionHeader('Trip Information', textTheme),
                  const SizedBox(height: 16.0),
                  _buildInfoCard(trip, textTheme),
                  if (trip.pickupLocation != null || trip.dropLocation != null) ...[
                    const SizedBox(height: 24.0),
                    _buildSectionHeader('Locations', textTheme),
                    const SizedBox(height: 16.0),
                    _buildLocationsCard(trip, textTheme),
                  ],
                  const SizedBox(height: 24.0),
                  _buildSectionHeader('Milestone Progress', textTheme),
                  const SizedBox(height: 16.0),
                  _buildMilestoneCard(trip, textTheme),
                  if (trip.pod?.photo != null &&
                      (trip.pod!.photo?.isNotEmpty ?? false)) ...[
                    const SizedBox(height: 24.0),
                    _buildSectionHeader('Proof of Delivery', textTheme),
                    const SizedBox(height: 16.0),
                    _buildPODCard(trip, textTheme),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, TextTheme textTheme) {
    return Text(
      title,
      style: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildStatusCard(TripModel trip, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: AppColors.primary,
          width: 2.0,
        ),
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
                    Text(
                      trip.containerNumber ?? 'No container',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    if (trip.tripId.isNotEmpty) ...[
                      const SizedBox(height: 4.0),
                      Text(
                        'Trip ID: ${trip.tripId}',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 6.0,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  Helpers.getStatusLabel(trip.status),
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(TripModel trip, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.offWhite,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppColors.dividerGrey, width: 1.0),
      ),
      child: Column(
        children: [
          if (trip.reference != null)
            _buildInfoRow(
              icon: Icons.tag_outlined,
              label: 'Reference',
              value: trip.reference!,
              textTheme: textTheme,
            ),
          if (trip.reference != null) const SizedBox(height: 12.0),
          _buildInfoRow(
            icon: Icons.category_outlined,
            label: 'Trip Type',
            value: Helpers.getTripTypeLabel(trip.tripType),
            textTheme: textTheme,
          ),
          const SizedBox(height: 12.0),
          _buildInfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Created',
            value: Helpers.formatDateTime(trip.createdAt),
            textTheme: textTheme,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required TextTheme textTheme,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20.0, color: AppColors.textSecondary),
        const SizedBox(width: 12.0),
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

  Widget _buildLocationsCard(TripModel trip, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.offWhite,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppColors.dividerGrey, width: 1.0),
      ),
      child: Column(
        children: [
          if (trip.pickupLocation != null)
            _buildLocationRow(
              icon: Icons.location_on_outlined,
              label: 'Pickup',
              address: trip.pickupLocation!.address ?? 'Location',
              textTheme: textTheme,
            ),
          if (trip.pickupLocation != null && trip.dropLocation != null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Icon(
                Icons.arrow_downward,
                color: AppColors.primary,
              ),
            ),
          if (trip.dropLocation != null)
            _buildLocationRow(
              icon: Icons.location_on,
              label: 'Drop',
              address: trip.dropLocation!.address ?? 'Location',
              textTheme: textTheme,
            ),
        ],
      ),
    );
  }

  Widget _buildLocationRow({
    required IconData icon,
    required String label,
    required String address,
    required TextTheme textTheme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20.0, color: AppColors.primary),
        const SizedBox(width: 12.0),
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
                address,
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

  Widget _buildMilestoneCard(TripModel trip, TextTheme textTheme) {
    final completedCount = trip.milestones.length;
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
          LinearProgressIndicator(
            value: completedCount / 5.0,
            backgroundColor: AppColors.dividerGrey,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          const SizedBox(height: 12.0),
          Text(
            '$completedCount of 5 milestones completed',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPODCard(TripModel trip, TextTheme textTheme) {
    final podPhotoUrl = trip.pod?.photo != null
        ? ApiConfig.baseUrl.replaceAll('/api', '') + trip.pod!.photo!
        : null;
    final isApproved = trip.status == AppConstants.tripStatusCompleted;

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.offWhite,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: isApproved
              ? AppColors.success.withOpacity(0.5)
              : AppColors.warning.withOpacity(0.5),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                isApproved ? Icons.check_circle : Icons.hourglass_empty,
                color: isApproved ? AppColors.success : AppColors.warning,
                size: 24.0,
              ),
              const SizedBox(width: 8.0),
              Text(
                isApproved ? 'POD approved' : 'POD uploaded - awaiting approval',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          if (podPhotoUrl != null) ...[
            const SizedBox(height: 16.0),
            ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: Image.network(
                podPhotoUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 200,
                  color: AppColors.dividerGrey,
                  child: Center(
                    child: Icon(
                      Icons.broken_image,
                      size: 48,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
