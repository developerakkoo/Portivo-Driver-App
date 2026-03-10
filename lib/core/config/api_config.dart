/// API Configuration class
class ApiConfig {
  // Environment configuration
  static const String _environment = String.fromEnvironment('ENV', defaultValue: 'production');
  
  // Base URLs based on environment
  static String get baseUrl {
    switch (_environment) {
      case 'development':
        return 'http://localhost:3000/api';
      case 'staging':
        return 'https://staging-api.port.porttivo.com/api';
      case 'production':
      default:
        return 'https://api.port.porttivo.com/api';
    }
  }
  
  // Socket.IO Server URL - Use the same base URL as baseUrl (without /api)
  static String get socketUrl {
    switch (_environment) {
      case 'development':
        return 'http://localhost:3000';
      case 'staging':
        return 'https://staging-api.port.porttivo.com';
      case 'production':
      default:
        return 'https://api.port.porttivo.com';
    }
  }
  
  // API Endpoints
  static const String sendOTP = '/auth/send-otp';
  static const String refreshToken = '/auth/refresh';
  
  // Driver endpoints
  static const String driverProfile = '/drivers/profile';
  static const String driverLanguage = '/drivers/language';
  static const String driverActiveTrip = '/drivers/trips/active';
  static const String driverQueuedTrips = '/drivers/trips/queued';
  static const String driverTripHistory = '/drivers/trips/history';
  
  // Trip endpoints
  static const String trips = '/trips';
  static String tripById(String id) => '/trips/$id';
  static String tripStart(String id) => '/trips/$id/start';
  static String tripComplete(String id) => '/trips/$id/complete';
  static String tripMilestone(String id, int milestoneNumber) => '/trips/$id/milestones/$milestoneNumber';
  static String tripCurrentMilestone(String id) => '/trips/$id/current-milestone';
  static String tripTimeline(String id) => '/trips/$id/timeline';
  static String tripPOD(String id) => '/trips/$id/pod';
  
  // Timeout settings
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);
  
  // Retry configuration
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  static const double retryBackoffMultiplier = 2.0;
  
  // Socket.IO configuration
  static const Duration socketReconnectDelay = Duration(seconds: 2);
  static const int socketMaxReconnectAttempts = 5;
  static const Duration socketHeartbeatInterval = Duration(seconds: 30);
  static const Duration socketConnectionTimeout = Duration(seconds: 10);
}
