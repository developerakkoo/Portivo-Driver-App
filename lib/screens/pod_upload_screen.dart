import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../core/theme/app_colors.dart';
import '../core/localization/app_localizations.dart';
import '../providers/trip_provider.dart';

class PODUploadScreen extends StatefulWidget {
  final String tripId;

  const PODUploadScreen({super.key, required this.tripId});

  @override
  State<PODUploadScreen> createState() => _PODUploadScreenState();
}

class _PODUploadScreenState extends State<PODUploadScreen> {
  File? _photo;
  bool _isUploading = false;
  String? _errorMessage;
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _photo = File(image.path);
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to capture image: $e';
      });
    }
  }

  Future<void> _uploadPOD() async {
    if (_photo == null) {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.pleaseCapturePhotoFirst;
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    final tripProvider = Provider.of<TripProvider>(context, listen: false);

    final success = await tripProvider.uploadPOD(widget.tripId, _photo!.path);

    if (!mounted) return;

    setState(() {
      _isUploading = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.podUploadedSuccessfully),
          backgroundColor: AppColors.success,
        ),
      );
      // Pop and return true to indicate success
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _errorMessage = tripProvider.error ?? AppLocalizations.of(context)!.failedToUploadPOD;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.uploadPODTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: AppColors.info.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.info, size: 24.0),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Text(
                      'Upload Proof of Delivery (POD) photo. This will be sent for approval.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24.0),

            // Photo Section
            Container(
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
                        'POD Photo',
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
                            height: 300.0,
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
                      height: 300.0,
                      child: OutlinedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.camera_alt, size: 48.0),
                        label: const Text('Capture POD Photo'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(24.0),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24.0),

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

            // Upload Button
            SizedBox(
              height: 52.0,
              child: ElevatedButton(
                onPressed: (_isUploading || _photo == null) ? null : _uploadPOD,
                child: _isUploading
                    ? const SizedBox(
                        height: 20.0,
                        width: 20.0,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.background),
                        ),
                      )
                    : Text(
                        AppLocalizations.of(context)!.uploadPOD,
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
}
