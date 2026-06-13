import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens the device's native maps app in turn-by-turn directions mode,
/// using the device's current location as the origin (Ola/Uber style).
///
/// The destination is the trip stop (pickup or drop). We never pass an origin
/// so the maps app uses live GPS as the starting point and begins navigation.
class NavigationLauncher {
  /// Launches driving directions to [destLat], [destLng].
  ///
  /// Tries, in order:
  ///   * Android: `google.navigation:` (starts turn-by-turn immediately)
  ///   * iOS: Google Maps app (`comgooglemaps://`), then Apple Maps
  ///   * All platforms: the universal Google Maps web/app link
  ///
  /// Returns `true` if any candidate launched successfully.
  static Future<bool> startDirections({
    required double destLat,
    required double destLng,
    String? destLabel,
  }) async {
    final candidates = <Uri>[];

    if (!kIsWeb && Platform.isAndroid) {
      candidates.add(Uri.parse('google.navigation:q=$destLat,$destLng&mode=d'));
      candidates.add(Uri.parse('geo:$destLat,$destLng?q=$destLat,$destLng'));
    } else if (!kIsWeb && Platform.isIOS) {
      candidates.add(
        Uri.parse('comgooglemaps://?daddr=$destLat,$destLng&directionsmode=driving'),
      );
      candidates.add(
        Uri.parse('https://maps.apple.com/?daddr=$destLat,$destLng&dirflg=d'),
      );
    }

    // Universal fallback: opens the Google Maps app if installed, else the browser.
    candidates.add(
      Uri.parse(
        'https://www.google.com/maps/dir/?api=1'
        '&destination=$destLat,$destLng'
        '&travelmode=driving'
        '&dir_action=navigate',
      ),
    );

    for (final uri in candidates) {
      try {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) return true;
      } catch (_) {
        // Scheme not handled on this device; try the next candidate.
      }
    }
    return false;
  }
}
