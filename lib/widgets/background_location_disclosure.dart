import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/device_permission_service.dart';

/// Prominent in-app disclosure for background location, shown BEFORE the OS
/// permission prompt to satisfy Google Play / App Store policy. Explains that
/// Porttivo collects location in the background to share live trip progress
/// with the transporter, even when the app is closed or not in use.
class BackgroundLocationConsent {
  BackgroundLocationConsent._();

  static const String _kDisclosureShownKey =
      'driver_bg_location_disclosure_shown';

  /// Ensure the driver has seen the disclosure and (ideally) granted background
  /// location. Safe to call after a trip is started. No-op if already granted.
  static Future<void> ensure(BuildContext context) async {
    final permissions = DevicePermissionService();
    if (await permissions.isBackgroundLocationGranted()) return;

    final prefs = await SharedPreferences.getInstance();
    final alreadyShown = prefs.getBool(_kDisclosureShownKey) ?? false;
    if (alreadyShown) return;
    if (!context.mounted) return;

    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _DisclosureDialog(),
    );

    await prefs.setBool(_kDisclosureShownKey, true);

    if (accepted == true) {
      await permissions.requestBackgroundLocation();
    }
  }
}

class _DisclosureDialog extends StatelessWidget {
  const _DisclosureDialog();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      icon: const Icon(Icons.location_on, size: 36),
      title: const Text('Share live location during trips'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Porttivo collects your location in the background to share live '
            'trip progress with the transporter and customer — even when the '
            'app is closed or not in use.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Text(
            'Location is shared only while you have an active trip, and stops '
            'as soon as the trip is completed or you log out.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Text(
            'On the next screen, please choose "Allow all the time" to keep '
            'tracking working while your phone is locked.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Not now'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Continue'),
        ),
      ],
    );
  }
}
