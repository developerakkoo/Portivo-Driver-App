import 'package:flutter/foundation.dart';

/// Utility class for safe JSON parsing that handles populated objects,
/// nested structures, and inconsistent response formats from the API.
class JsonParser {
  /// Safely extract ID from a value that can be:
  /// - A string (direct ID)
  /// - A populated object with _id or id field
  /// - null
  /// Returns null if value is null or cannot be extracted
  static String? extractId(dynamic value) {
    if (value == null) return null;
    
    if (value is String) {
      return value.isEmpty ? null : value;
    }
    
    if (value is Map) {
      // Handle populated objects - try _id first, then id
      final id = value['_id'] ?? value['id'];
      if (id != null) {
        return id.toString();
      }
      return null;
    }
    
    try {
      return value.toString();
    } catch (e) {
      if (kDebugMode) {
        print('JsonParser: Error extracting ID from $value: $e');
      }
      return null;
    }
  }

  /// Safely extract a string value from dynamic input
  static String extractString(dynamic value, String defaultValue) {
    if (value == null) return defaultValue;
    
    if (value is String) {
      return value;
    }
    
    if (value is Map) {
      final id = value['_id'] ?? value['id'];
      if (id != null) {
        return id.toString();
      }
      return value.toString();
    }
    
    try {
      return value.toString();
    } catch (e) {
      if (kDebugMode) {
        print('JsonParser: Error extracting string from $value: $e');
      }
      return defaultValue;
    }
  }

  /// Safely extract a list from dynamic input
  static List<T> extractList<T>(
    dynamic value,
    T Function(Map<String, dynamic>) parser,
  ) {
    if (value == null) return [];
    
    if (value is List) {
      try {
        return value
            .where((item) => item != null && item is Map)
            .map((item) => parser(item as Map<String, dynamic>))
            .toList();
      } catch (e) {
        if (kDebugMode) {
          print('JsonParser: Error parsing list: $e');
        }
        return [];
      }
    }
    
    return [];
  }

  /// Safely extract a double value from dynamic input
  static double extractDouble(dynamic value, double defaultValue) {
    if (value == null) return defaultValue;
    
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? defaultValue;
    }
    
    return defaultValue;
  }

  /// Safely extract an int value from dynamic input
  static int extractInt(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? defaultValue;
    }
    
    return defaultValue;
  }

  /// Safely extract a boolean value from dynamic input
  static bool extractBool(dynamic value, bool defaultValue) {
    if (value == null) return defaultValue;
    
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true';
    }
    if (value is int) {
      return value != 0;
    }
    
    return defaultValue;
  }

  /// Safely extract a DateTime from dynamic input
  static DateTime? extractDateTime(dynamic value) {
    if (value == null) return null;
    
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        if (kDebugMode) {
          print('JsonParser: Error parsing DateTime from string: $e');
        }
        return null;
      }
    }
    
    return null;
  }
}
