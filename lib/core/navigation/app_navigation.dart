import 'package:flutter/foundation.dart';

/// Lightweight app-wide navigation coordinator so widgets (e.g. the home
/// dashboard cards) can switch the bottom-nav tab and pre-select a Trips
/// sub-tab without threading callbacks through the widget tree.
class AppNavigation extends ChangeNotifier {
  AppNavigation._();
  static final AppNavigation instance = AppNavigation._();

  /// Bottom navigation index (0 = Home, 1 = Trips, 2 = Profile).
  int _bottomIndex = 0;
  int get bottomIndex => _bottomIndex;

  /// Requested Trips sub-tab (0 = Active, 1 = Queued, 2 = History), consumed
  /// once by the Trips screen.
  int? _requestedTripsTab;
  int? get requestedTripsTab => _requestedTripsTab;

  void setBottomIndex(int index) {
    if (_bottomIndex == index && _requestedTripsTab == null) return;
    _bottomIndex = index;
    notifyListeners();
  }

  /// Open the Trips tab, optionally selecting a sub-tab
  /// (0 = Active, 1 = Queued, 2 = History).
  void openTrips({int subTab = 0}) {
    _requestedTripsTab = subTab;
    _bottomIndex = 1;
    notifyListeners();
  }

  /// Read and clear any pending Trips sub-tab request.
  int? consumeRequestedTripsTab() {
    final tab = _requestedTripsTab;
    _requestedTripsTab = null;
    return tab;
  }
}
