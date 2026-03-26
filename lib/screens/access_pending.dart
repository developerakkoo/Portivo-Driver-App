import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/localization/app_localizations.dart';

class AccessPendingScreen extends StatelessWidget {
  const AccessPendingScreen({super.key});

  void _handleContactTransporter(BuildContext context) {
    // TODO: Implement contact transporter functionality
    // This could open a phone dialer, email, or in-app messaging
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Transporter'),
        content: const Text('This feature will allow you to contact your transporter. Implementation coming soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon
              Icon(
                Icons.pending_actions,
                size: 80.0,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: 32.0),

              // Title
              Text(
                AppLocalizations.of(context)!.accessPending,
                style: textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16.0),

              // Message
              Text(
                AppLocalizations.of(context)!.accessPendingMessage,
                style: textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48.0),

              // Contact Transporter Button
              SizedBox(
                height: 52.0,
                child: ElevatedButton(
                  onPressed: () => _handleContactTransporter(context),
                  child: Text(
                    AppLocalizations.of(context)!.contactTransporter,
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
      ),
    );
  }
}

