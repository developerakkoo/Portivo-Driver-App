import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Device/OS permissions for the driver app (location + camera for trips and milestones).
class DevicePermissionService {
  static const String _kLoginPermissionModalDismissed =
      'driver_login_permission_modal_dismissed';

  static const List<Permission> loginPromptPermissions = [
    Permission.locationWhenInUse,
    Permission.camera,
  ];

  static const List<Permission> milestonePermissions = [
    Permission.locationWhenInUse,
    Permission.camera,
  ];

  Future<Map<Permission, PermissionStatus>> requestLoginPromptPermissions() async {
    return await loginPromptPermissions.request();
  }

  Future<Map<Permission, PermissionStatus>> requestMilestonePermissions() async {
    return await milestonePermissions.request();
  }

  Future<bool> openSettings() async {
    return await openAppSettings();
  }

  /// Whether "Allow all the time" (background) location is granted. Required for
  /// tracking to continue when the app is backgrounded or the phone is locked.
  Future<bool> isBackgroundLocationGranted() async {
    return _isOk(await Permission.locationAlways.status);
  }

  /// Escalate to background ("Allow all the time") location. Must only be called
  /// after when-in-use location is already granted (OS requirement). Returns
  /// true if background location ends up granted.
  Future<bool> requestBackgroundLocation() async {
    // Background can't be requested unless foreground is granted first.
    if (!await _isLocationEffectivelyGranted()) {
      final fg = await Permission.locationWhenInUse.request();
      if (!_isOk(fg)) return false;
    }
    if (await isBackgroundLocationGranted()) return true;
    final status = await Permission.locationAlways.request();
    return _isOk(status);
  }

  static bool _isOk(PermissionStatus status) {
    return status.isGranted || status.isLimited || status.isProvisional;
  }

  Future<bool> _isLocationEffectivelyGranted() async {
    final whenInUse = await Permission.locationWhenInUse.status;
    if (_isOk(whenInUse)) return true;
    final location = await Permission.location.status;
    return _isOk(location);
  }

  Future<bool> _isCameraEffectivelyGranted() async {
    return _isOk(await Permission.camera.status);
  }

  Future<bool> areLoginGatePermissionsGranted() async {
    final loc = await _isLocationEffectivelyGranted();
    final cam = await _isCameraEffectivelyGranted();
    return loc && cam;
  }

  Future<bool> isLocationEffectivelyGranted() => _isLocationEffectivelyGranted();

  Future<bool> isCameraEffectivelyGranted() => _isCameraEffectivelyGranted();

  Future<void> markLoginPermissionModalDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kLoginPermissionModalDismissed, true);
  }

  Future<bool> shouldShowLoginPermissionModal() async {
    final ok = await areLoginGatePermissionsGranted();
    final prefs = await SharedPreferences.getInstance();

    if (ok) {
      await prefs.remove(_kLoginPermissionModalDismissed);
      return false;
    }

    if (prefs.getBool(_kLoginPermissionModalDismissed) ?? false) {
      return false;
    }

    return true;
  }
}
