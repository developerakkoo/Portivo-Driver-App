import 'package:flutter/widgets.dart';

/// Tracks foreground/background state app-wide so non-widget services (e.g. the
/// live-location heartbeat) can report the driver app's `appState` to the API.
class AppLifecycleTracker with WidgetsBindingObserver {
  AppLifecycleTracker._();
  static final AppLifecycleTracker instance = AppLifecycleTracker._();

  AppLifecycleState _state = AppLifecycleState.resumed;
  bool _registered = false;

  /// Register once (e.g. from the root widget's initState).
  void register() {
    if (_registered) return;
    _registered = true;
    WidgetsBinding.instance.addObserver(this);
  }

  void unregister() {
    if (!_registered) return;
    _registered = false;
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _state = state;
  }

  /// API-friendly value: `foreground`, `background`, or `inactive`.
  String get appStateLabel {
    switch (_state) {
      case AppLifecycleState.resumed:
        return 'foreground';
      case AppLifecycleState.inactive:
        return 'inactive';
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        return 'background';
    }
  }
}
