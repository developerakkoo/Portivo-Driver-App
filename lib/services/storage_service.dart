/// Platform-specific storage service implementation
/// 
/// Uses conditional imports to select the appropriate implementation:
/// - Web: Uses SharedPreferences only (via storage_service_stub.dart)
/// - Mobile: Uses SharedPreferences + FlutterSecureStorage (via storage_service_io.dart)
export 'storage_service_stub.dart' if (dart.library.io) 'storage_service_io.dart';
