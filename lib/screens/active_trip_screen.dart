import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/localization/app_localizations.dart';
import '../providers/trip_provider.dart';
import '../models/trip_model.dart';
import '../core/constants/app_constants.dart';
import '../core/config/api_config.dart';
import '../services/location_stream_service.dart';
import '../services/socket_service.dart';
import 'milestone_update_screen.dart';
import 'pod_upload_screen.dart';

class ActiveTripScreen extends StatefulWidget {
  final String tripId;

  const ActiveTripScreen({super.key, required this.tripId});

  @override
  State<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends State<ActiveTripScreen> {
  final LocationStreamService _locationStreamService = LocationStreamService();
  final SocketService _socketService = SocketService();
  bool _locationStreamActive = false;
  bool _locationStreamStartFailed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTrip();
    });
  }

  @override
  void dispose() {
    if (_locationStreamActive) {
      _locationStreamService.stop();
      _locationStreamActive = false;
    }
    _locationStreamStartFailed = false;
    super.dispose();
  }

  Future<void> _startLocationStreamIfNeeded(TripModel trip) async {
    if (trip.status != AppConstants.tripStatusActive) return;
    if (_locationStreamActive || _locationStreamStartFailed) return;

    _locationStreamService.onPositionUpdate = (lat, lng) {
      _socketService.emitDriverLocationUpdate(
        tripId: trip.id,
        latitude: lat,
        longitude: lng,
      );
    };
    final result = await _locationStreamService.start();
    if (!mounted) return;

    if (result == LocationStreamStartResult.started ||
        result == LocationStreamStartResult.alreadyRunning) {
      _locationStreamActive = true;
      return;
    }

    _locationStreamStartFailed = true;
    String? message;
    switch (result) {
      case LocationStreamStartResult.permissionDenied:
        message =
            'Location permission is required for live tracking. Enable it in system settings.';
        break;
      case LocationStreamStartResult.locationServiceDisabled:
        message =
            'Turn on location services so the transporter can see your position.';
        break;
      case LocationStreamStartResult.failed:
        message = 'Could not get GPS position. Check location settings.';
        break;
      default:
        break;
    }
    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  void _stopLocationStreamIfNeeded(TripModel trip) {
    if (trip.status == AppConstants.tripStatusActive) return;
    if (!_locationStreamActive && !_locationStreamStartFailed) return;

    _locationStreamService.stop();
    _locationStreamActive = false;
    _locationStreamStartFailed = false;
  }

  Future<void> _loadTrip() async {
    final tripProvider = Provider.of<TripProvider>(context, listen: false);
    await tripProvider.getTripById(widget.tripId);
    // Also refresh active trip if it matches to ensure socket rooms are joined
    if (tripProvider.activeTrip?.id == widget.tripId) {
      await tripProvider.loadActiveTrip(refresh: true);
    }
  }

  /// Get the current trip from provider, prioritizing selectedTrip then activeTrip
  TripModel? _getCurrentTrip(TripProvider tripProvider) {
    // First check selectedTrip (from getTripById)
    if (tripProvider.selectedTrip?.id == widget.tripId) {
      return tripProvider.selectedTrip;
    }
    // Then check activeTrip
    if (tripProvider.activeTrip?.id == widget.tripId) {
      return tripProvider.activeTrip;
    }
    // Check history as fallback
    try {
      return tripProvider.tripHistory.firstWhere(
        (t) => t.id == widget.tripId,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Active Trip'),
      ),
      body: Consumer<TripProvider>(
        builder: (context, tripProvider, _) {
          // Get trip from provider, checking selectedTrip, activeTrip, and history
          TripModel? trip;
          try {
            trip = _getCurrentTrip(tripProvider);
          } catch (e) {
            trip = null;
          }

          if (tripProvider.isLoading && trip == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (trip != null) {
            final t = trip;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (t.status == AppConstants.tripStatusActive) {
                _startLocationStreamIfNeeded(t);
              } else {
                _stopLocationStreamIfNeeded(t);
              }
            });
          }

          if (trip == null) {
            return RefreshIndicator(
              onRefresh: _loadTrip,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64.0, color: AppColors.error),
                        const SizedBox(height: 16.0),
                        Text(
                          AppLocalizations.of(context)!.tripNotFound,
                          style: textTheme.headlineSmall?.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          AppLocalizations.of(context)!.pullDownToRefresh,
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadTrip,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTripInfo(context, trip),
                  const SizedBox(height: 24.0),
                  _buildMilestoneProgress(context, trip),
                  const SizedBox(height: 24.0),
                  _buildLocations(context, trip),
                  const SizedBox(height: 24.0),
                  if (trip.status == AppConstants.tripStatusPodPending &&
                      trip.pod?.photo != null &&
                      (trip.pod!.photo?.isNotEmpty ?? false))
                    _buildPODUploadedSection(context, trip)
                  else if (trip.status == AppConstants.tripStatusPodPending &&
                      (trip.pod == null ||
                          trip.pod!.photo == null ||
                          (trip.pod!.photo?.isEmpty ?? true)))
                    _buildUploadPODButton(context, trip)
                  else if (trip.milestones.length == 4 && trip.status == AppConstants.tripStatusActive)
                    _buildUploadPODButton(context, trip)
                  else if (trip.milestones.length < 4)
                    _buildUpdateMilestoneButton(context, trip),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showContainerEditDialog(BuildContext context, TripModel trip) async {
    final controller = TextEditingController(text: trip.containerNumber ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.container),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.container,
            hintText: 'Enter container number',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim().toUpperCase()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && mounted) {
      final tripProvider = Provider.of<TripProvider>(context, listen: false);
      final success = await tripProvider.updateTrip(trip.id, {'containerNumber': result.isEmpty ? null : result});
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Container number updated'), backgroundColor: Colors.green),
          );
          _loadTrip();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tripProvider.error ?? 'Failed to update container'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildTripInfo(BuildContext context, TripModel trip) {
    final textTheme = Theme.of(context).textTheme;
    final canEditContainer = trip.status == AppConstants.tripStatusPlanned || trip.status == AppConstants.tripStatusActive;
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
          Text(
            AppLocalizations.of(context)!.tripDetails,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16.0),
          _buildInfoRow(AppLocalizations.of(context)!.tripId, trip.tripId, textTheme),
          _buildContainerRow(context, trip, textTheme, canEditContainer),
          if (trip.reference != null)
            _buildInfoRow(AppLocalizations.of(context)!.reference, trip.reference!, textTheme),
          _buildInfoRow(AppLocalizations.of(context)!.type, trip.tripType, textTheme),
          _buildInfoRow(AppLocalizations.of(context)!.status, trip.status.replaceAll('_', ' '), textTheme),
        ],
      ),
    );
  }

  Widget _buildContainerRow(BuildContext context, TripModel trip, TextTheme textTheme, bool canEdit) {
    final value = trip.containerNumber ?? 'Not set';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100.0,
            child: Text(
              AppLocalizations.of(context)!.container,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: textTheme.bodyMedium?.copyWith(
                color: trip.containerNumber != null ? AppColors.textPrimary : AppColors.textMuted,
                fontWeight: FontWeight.w500,
                fontStyle: trip.containerNumber != null ? FontStyle.normal : FontStyle.italic,
              ),
            ),
          ),
          if (canEdit)
            IconButton(
              icon: Icon(
                trip.containerNumber != null ? Icons.edit_outlined : Icons.add_circle_outline,
                size: 20.0,
                color: AppColors.primary,
              ),
              onPressed: () => _showContainerEditDialog(context, trip),
              tooltip: trip.containerNumber != null ? 'Edit container' : 'Add container',
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100.0,
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneProgress(BuildContext context, TripModel trip) {
    final textTheme = Theme.of(context).textTheme;
    final completedCount = trip.milestones.length;
    final currentMilestone = trip.currentMilestone;

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
          Text(
            'Milestone Progress',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16.0),
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
          // Show next milestone info if not all completed
          if (completedCount < 5) ...[
            const SizedBox(height: 16.0),
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.flag, color: AppColors.primary, size: 20.0),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      currentMilestone != null
                          ? '${AppLocalizations.of(context)!.nextMilestoneWithNumber(completedCount + 1).split(':')[0]}: ${currentMilestone.label ?? currentMilestone.milestoneType}'
                          : AppLocalizations.of(context)!.nextMilestoneWithNumber(completedCount + 1),
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocations(BuildContext context, TripModel trip) {
    final textTheme = Theme.of(context).textTheme;
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
          Text(
            'Locations',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16.0),
          if (trip.pickupLocation != null)
            _buildLocationRow(
              AppLocalizations.of(context)!.pickup,
              trip.pickupLocation!.address ?? 'Location',
              trip.pickupLocation!.coordinates,
              textTheme,
            ),
          if (trip.dropLocation != null) ...[
            const SizedBox(height: 12.0),
            _buildLocationRow(
              AppLocalizations.of(context)!.drop,
              trip.dropLocation!.address ?? 'Location',
              trip.dropLocation!.coordinates,
              textTheme,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationRow(
    String label,
    String address,
    dynamic coordinates,
    TextTheme textTheme,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          label == AppLocalizations.of(context)!.pickup ? Icons.upload : Icons.download,
          size: 20.0,
          color: AppColors.textSecondary,
        ),
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
              const SizedBox(height: 4.0),
              Text(
                address,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUpdateMilestoneButton(BuildContext context, TripModel trip) {
    // Calculate next milestone number based on completed milestones
    // This ensures we always use the correct next milestone number
    // Backend expects: completedMilestones + 1
    final completedMilestones = trip.milestones.length;
    final nextMilestoneNumber = completedMilestones + 1;
    
    // Don't show button if all milestones are completed
    if (nextMilestoneNumber > 5) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 52.0,
      child: ElevatedButton(
        onPressed: () async {
          // Navigate to milestone update screen
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MilestoneUpdateScreen(
                tripId: trip.id,
                milestoneNumber: nextMilestoneNumber,
              ),
            ),
          );
          // Refresh trip data when returning (socket events should have updated it, but refresh to be sure)
          if (result == true && mounted) {
            _loadTrip();
          }
        },
        child: Text(
          AppLocalizations.of(context)!.updateMilestoneWithNumber(nextMilestoneNumber),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.background,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }

  Widget _buildPODUploadedSection(BuildContext context, TripModel trip) {
    final textTheme = Theme.of(context).textTheme;
    final podPhotoUrl = trip.pod?.photo != null
        ? ApiConfig.baseUrl.replaceAll('/api', '') + trip.pod!.photo!
        : null;

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.offWhite,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.success.withOpacity(0.5), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.success, size: 24.0),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  'POD uploaded - awaiting transporter approval',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
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
                    child: Icon(Icons.broken_image, size: 48, color: AppColors.textMuted),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUploadPODButton(BuildContext context, TripModel trip) {
    return SizedBox(
      height: 52.0,
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PODUploadScreen(tripId: trip.id),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.info,
        ),
        child: Text(
          AppLocalizations.of(context)!.uploadPOD,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.background,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }

}
