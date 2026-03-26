import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../core/localization/app_localizations.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/image_utils.dart';
import '../providers/trip_provider.dart';
import '../services/device_permission_service.dart';

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
  final DevicePermissionService _permService = DevicePermissionService();
  final ImagePicker _imagePicker = ImagePicker();

  Position? _currentPosition;
  final List<File> _photos = [];
  bool _isSubmitting = false;
  bool _isLoadingLocation = true;
  String? _errorMessage;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveLocation());
  }

  Future<void> _resolveLocation() async {
    if (!mounted) return;
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
      _errorMessage = null;
      _currentPosition = null;
    });

    try {
      await _permService.requestMilestonePermissions();

      if (!await _permService.isLocationEffectivelyGranted()) {
        if (!mounted) return;
        setState(() {
          _isLoadingLocation = false;
          _locationError =
              'Location permission is required. Tap Retry after granting, or open system settings.';
        });
        return;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          _isLoadingLocation = false;
          _locationError =
              'Location services are off. Turn on GPS/location in system settings, then tap Retry.';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 30),
      );

      if (!mounted) return;
      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingLocation = false;
        _locationError = 'Could not get location: $e';
      });
    }
  }

  Future<void> _openSystemSettings() async {
    await _permService.openSettings();
  }

  Future<void> _pickImage() async {
    setState(() => _errorMessage = null);

    if (!await _permService.isCameraEffectivelyGranted()) {
      await _permService.requestMilestonePermissions();
    }
    if (!await _permService.isCameraEffectivelyGranted()) {
      setState(() {
        _errorMessage =
            'Camera permission is required to capture milestone photos. Grant it in settings if needed.';
      });
      return;
    }

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _photos.add(File(image.path));
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to capture image: $e';
      });
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
  }

  Future<void> _submitMilestone() async {
    if (_isLoadingLocation || _currentPosition == null) {
      setState(() {
        _errorMessage = 'Wait until your location is ready, or fix the issue above and tap Retry.';
      });
      return;
    }

    if (_photos.isEmpty) {
      setState(() {
        _errorMessage = 'At least one photo is required for this milestone';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final tripProvider = Provider.of<TripProvider>(context, listen: false);

    final photoPathsToUpload = <String>[];
    for (var i = 0; i < _photos.length; i++) {
      try {
        final watermarked = await ImageUtils.addWatermark(
          _photos[i].path,
          timestamp: DateTime.now(),
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude,
        );
        photoPathsToUpload.add(watermarked);
      } catch (e) {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
            _errorMessage = 'Failed to add watermark to photo ${i + 1}: $e';
          });
        }
        return;
      }
    }

    final success = await tripProvider.updateMilestone(
      widget.tripId,
      widget.milestoneNumber,
      latitude: _currentPosition!.latitude,
      longitude: _currentPosition!.longitude,
      photoPaths: photoPathsToUpload,
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
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _errorMessage =
            tripProvider.error ?? AppLocalizations.of(context)!.failedToUpdateMilestone;
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
    final canSubmit = !_isSubmitting &&
        !_isLoadingLocation &&
        _currentPosition != null &&
        _locationError == null;

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

            _buildLocationCard(textTheme),

            const SizedBox(height: 24.0),

            _buildPhotoSection(textTheme),
            const SizedBox(height: 24.0),

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

            SizedBox(
              height: 52.0,
              child: ElevatedButton(
                onPressed: (_isSubmitting || !canSubmit) ? null : _submitMilestone,
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

  Widget _buildLocationCard(TextTheme textTheme) {
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
              Icon(Icons.my_location, color: AppColors.primary, size: 24.0),
              const SizedBox(width: 8.0),
              Text(
                'Location for milestone',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          if (_isLoadingLocation) ...[
            Row(
              children: [
                const SizedBox(
                  width: 28.0,
                  height: 28.0,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Text(
                    'Getting your location…',
                    style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ] else if (_locationError != null) ...[
            Text(
              _locationError!,
              style: textTheme.bodyMedium?.copyWith(color: AppColors.error),
            ),
            const SizedBox(height: 12.0),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _resolveLocation,
                    child: const Text('Retry'),
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _openSystemSettings,
                    child: const Text('Settings'),
                  ),
                ),
              ],
            ),
          ] else if (_currentPosition != null) ...[
            Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.success, size: 22.0),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    'Location ready (${_currentPosition!.latitude.toStringAsFixed(5)}, ${_currentPosition!.longitude.toStringAsFixed(5)})',
                    style: textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhotoSection(TextTheme textTheme) {
    const double cellSize = 88.0;
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
                'Photos (Required)',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          Wrap(
            spacing: 12.0,
            runSpacing: 12.0,
            children: [
              ..._photos.asMap().entries.map((entry) {
                final index = entry.key;
                final photo = entry.value;
                return SizedBox(
                  width: cellSize,
                  height: cellSize,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.file(
                          photo,
                          width: cellSize,
                          height: cellSize,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: -6.0,
                        right: -6.0,
                        child: GestureDetector(
                          onTap: () => _removePhoto(index),
                          child: Container(
                            padding: const EdgeInsets.all(4.0),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 4.0,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.close, size: 16.0, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              SizedBox(
                width: cellSize,
                height: cellSize,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.6),
                        width: 2.0,
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.add, size: 36.0, color: AppColors.primary),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
