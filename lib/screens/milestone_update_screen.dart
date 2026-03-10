import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../core/theme/app_colors.dart';
import '../core/localization/app_localizations.dart';
import '../providers/trip_provider.dart';

class MilestoneUpdateScreen extends StatefulWidget {
  final String tripId;
  final int milestoneNumber;

  const MilestoneUpdateScreen({
    super.key,
    required this.tripId,
    required this.milestoneNumber,
  });

  @override
  State<MilestoneUpdateScreen> createState() => _MilestoneUpdateScreenState();
}

class _MilestoneUpdateScreenState extends State<MilestoneUpdateScreen> {
  Position? _currentPosition;
  File? _photo;
  bool _isLoadingLocation = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _errorMessage = null;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = 'Location services are disabled. Please enable them in settings.';
          _isLoadingLocation = false;
        });
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage = 'Location permissions are denied. Please grant location access.';
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage = 'Location permissions are permanently denied. Please enable them in settings.';
          _isLoadingLocation = false;
        });
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to get location: $e';
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _photo = File(image.path);
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to capture image: $e';
      });
    }
  }

  Future<void> _submitMilestone() async {
    if (_currentPosition == null) {
      setState(() {
        _errorMessage = 'Please wait for location to be fetched';
      });
      return;
    }

    // Milestone 1 requires photo
    if (widget.milestoneNumber == 1 && _photo == null) {
      setState(() {
        _errorMessage = 'Photo is required for milestone 1';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final tripProvider = Provider.of<TripProvider>(context, listen: false);

    final success = await tripProvider.updateMilestone(
      widget.tripId,
      widget.milestoneNumber,
      latitude: _currentPosition!.latitude,
      longitude: _currentPosition!.longitude,
      photoPath: _photo?.path,
    );

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.milestoneUpdatedSuccessfully),
          backgroundColor: AppColors.success,
        ),
      );
      // Pop and let the parent screen refresh via socket events
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _errorMessage = tripProvider.error ?? AppLocalizations.of(context)!.failedToUpdateMilestone;
      });
    }
  }

  String _getMilestoneLabel(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    switch (widget.milestoneNumber) {
      case 1:
        return localizations.containerPicked;
      case 2:
        return localizations.reachedLocation;
      case 3:
        return localizations.loadingUnloading;
      case 4:
        return localizations.reachedDestination;
      case 5:
        return localizations.tripCompleted;
      default:
        return 'Milestone ${widget.milestoneNumber}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.updateMilestoneTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Milestone Info
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: AppColors.offWhite,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: AppColors.dividerGrey, width: 1.0),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.flag,
                    size: 48.0,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    _getMilestoneLabel(context),
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24.0),

            // Location Section
            _buildLocationSection(textTheme),
            const SizedBox(height: 24.0),

            // Photo Section
            if (widget.milestoneNumber == 1) _buildPhotoSection(textTheme),
            if (widget.milestoneNumber == 1) const SizedBox(height: 24.0),

            // Error Message
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: AppColors.error, size: 20.0),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: textTheme.bodySmall?.copyWith(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24.0),
            ],

            // Submit Button
            SizedBox(
              height: 52.0,
              child: ElevatedButton(
                onPressed: (_isSubmitting || _isLoadingLocation || _currentPosition == null)
                    ? null
                    : _submitMilestone,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20.0,
                        width: 20.0,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.background),
                        ),
                      )
                    : Text(
                        AppLocalizations.of(context)!.update,
                        style: textTheme.labelLarge?.copyWith(
                          color: AppColors.background,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection(TextTheme textTheme) {
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
              Icon(Icons.location_on, color: AppColors.primary, size: 24.0),
              const SizedBox(width: 8.0),
              Text(
                'GPS Location',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          if (_isLoadingLocation)
            const Center(child: CircularProgressIndicator())
          else if (_currentPosition != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLocationRow('Latitude', _currentPosition!.latitude.toStringAsFixed(6), textTheme),
                const SizedBox(height: 8.0),
                _buildLocationRow('Longitude', _currentPosition!.longitude.toStringAsFixed(6), textTheme),
                const SizedBox(height: 12.0),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _getCurrentLocation,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh Location'),
                  ),
                ),
              ],
            )
          else
            Column(
              children: [
                Text(
                  'Location not available',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12.0),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _getCurrentLocation,
                    icon: const Icon(Icons.location_searching),
                    label: const Text('Get Location'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildLocationRow(String label, String value, TextTheme textTheme) {
    return Row(
      children: [
        SizedBox(
          width: 80.0,
          child: Text(
            label,
            style: textTheme.bodySmall?.copyWith(
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
    );
  }

  Widget _buildPhotoSection(TextTheme textTheme) {
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
              Icon(Icons.camera_alt, color: AppColors.primary, size: 24.0),
              const SizedBox(width: 8.0),
              Text(
                'Photo (Required)',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          if (_photo != null)
            Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: Image.file(
                    _photo!,
                    height: 200.0,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 12.0),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Retake Photo'),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              height: 200.0,
              child: OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.camera_alt, size: 48.0),
                label: Text(AppLocalizations.of(context)!.capturePhoto),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(24.0),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
