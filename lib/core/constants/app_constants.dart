class AppConstants {
  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
  static const String driverIdKey = 'driver_id';
  
  // Trip Status
  static const String tripStatusPlanned = 'PLANNED';
  static const String tripStatusActive = 'ACTIVE';
  static const String tripStatusCompleted = 'COMPLETED';
  static const String tripStatusPodPending = 'POD_PENDING';
  static const String tripStatusCancelled = 'CANCELLED';
  
  // Trip Types
  static const String tripTypeImport = 'IMPORT';
  static const String tripTypeExport = 'EXPORT';
  
  // Driver Status
  static const String driverStatusPending = 'pending';
  static const String driverStatusActive = 'active';
  static const String driverStatusInactive = 'inactive';
  static const String driverStatusBlocked = 'blocked';
  
  // Milestone Types
  static const String milestoneContainerPicked = 'CONTAINER_PICKED';
  static const String milestoneReachedLocation = 'REACHED_LOCATION';
  static const String milestoneLoadingUnloading = 'LOADING_UNLOADING';
  static const String milestoneReachedDestination = 'REACHED_DESTINATION';
  static const String milestoneTripCompleted = 'TRIP_COMPLETED';
  
  // Language Codes
  static const String languageEnglish = 'en';
  static const String languageHindi = 'hi';
  static const String languageMarathi = 'mr';
}
