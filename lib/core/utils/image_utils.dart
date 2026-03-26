import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Image utility class for compression and resizing
/// Targets <500KB for nginx compatibility (client_max_body_size often 1MB)
class ImageUtils {
  /// Target max size to stay under nginx limits (500KB)
  static const int targetMaxBytes = 500 * 1024;
  
  /// Compress images larger than this (600KB)
  static const int maxFileSizeBytes = 600 * 1024;
  
  /// Maximum image width/height for compression
  static const int maxImageDimension = 1920;
  
  /// Quality for JPEG compression (0-100)
  static const int jpegQuality = 85;

  /// Compress and resize image if needed
  /// Returns the path to the compressed image file (targets <500KB)
  static Future<String> compressImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        throw Exception('Image file does not exist');
      }

      final fileSize = await file.length();
      if (fileSize <= maxFileSizeBytes) {
        if (kDebugMode) {
          print('ImageUtils: Image size ($fileSize bytes) is within limit, no compression needed');
        }
        return imagePath;
      }

      if (kDebugMode) {
        print('ImageUtils: Compressing image from $fileSize bytes');
      }

      final imageBytes = await file.readAsBytes();
      img.Image? decoded = img.decodeImage(imageBytes);
      if (decoded == null) {
        throw Exception('Failed to decode image');
      }
      img.Image image = decoded;

      int currentQuality = jpegQuality;
      int currentDimension = maxImageDimension;
      Uint8List compressedBytes = Uint8List.fromList(
        img.encodeJpg(image, quality: currentQuality),
      );

      // Iteratively reduce until under target
      while (compressedBytes.length > targetMaxBytes &&
          (currentQuality > 30 || currentDimension > 640)) {
        if (currentQuality > 30) {
          currentQuality = (currentQuality - 15).clamp(30, 100);
          compressedBytes = Uint8List.fromList(
            img.encodeJpg(image, quality: currentQuality),
          );
        }
        if (compressedBytes.length > targetMaxBytes && currentDimension > 640) {
          currentDimension = (currentDimension * 0.75).round().clamp(640, 1920);
          image = img.copyResize(
            image,
            width: image.width > image.height ? currentDimension : null,
            height: image.height > image.width ? currentDimension : null,
            maintainAspect: true,
          );
          compressedBytes = Uint8List.fromList(
            img.encodeJpg(image, quality: currentQuality),
          );
        }
      }

      if (compressedBytes.length >= fileSize) {
        if (kDebugMode) {
          print('ImageUtils: Compression did not reduce size, using original');
        }
        return imagePath;
      }

      final tempDir = await getTemporaryDirectory();
      final fileName = path.basenameWithoutExtension(imagePath);
      final compressedPath = path.join(
        tempDir.path,
        '${fileName}_compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      final compressedFile = File(compressedPath);
      await compressedFile.writeAsBytes(compressedBytes);

      if (kDebugMode) {
        print('ImageUtils: Compressed image saved to $compressedPath');
        print('ImageUtils: Original size: $fileSize bytes, Compressed size: ${compressedBytes.length} bytes');
      }

      return compressedPath;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('ImageUtils: Error compressing image: $e');
        print('Stack: $stackTrace');
      }
      return imagePath;
    }
  }

  /// Get image file size in bytes
  static Future<int> getFileSize(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      if (kDebugMode) {
        print('ImageUtils: Error getting file size: $e');
      }
      return 0;
    }
  }

  /// Check if image needs compression (e.g. >600KB for nginx safety)
  static Future<bool> needsCompression(String imagePath) async {
    final fileSize = await getFileSize(imagePath);
    return fileSize > maxFileSizeBytes;
  }

  /// Add timestamp and location watermark to image
  /// Returns path to watermarked image file
  static Future<String> addWatermark(
    String imagePath, {
    required DateTime timestamp,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        throw Exception('Image file does not exist');
      }

      final imageBytes = await file.readAsBytes();
      img.Image? image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      final timestampStr = '${timestamp.toIso8601String()}';
      final locationStr = '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';

      // Use arial24 font (built-in)
      final font = img.arial24;
      final textColor = img.ColorRgba8(255, 255, 255, 230);
      final shadowColor = img.ColorRgba8(0, 0, 0, 180);

      // Draw at bottom-left with slight padding; add shadow for readability
      const padding = 12;
      final y1 = image.height - padding - 48;
      final y2 = image.height - padding - 24;

      // Shadow offset
      img.drawString(image, timestampStr, font: font, x: padding + 1, y: y1 + 1, color: shadowColor);
      img.drawString(image, locationStr, font: font, x: padding + 1, y: y2 + 1, color: shadowColor);
      // Main text
      img.drawString(image, timestampStr, font: font, x: padding, y: y1, color: textColor);
      img.drawString(image, locationStr, font: font, x: padding, y: y2, color: textColor);

      final tempDir = await getTemporaryDirectory();
      final watermarkedPath = path.join(
        tempDir.path,
        'watermarked_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      final watermarkedFile = File(watermarkedPath);
      await watermarkedFile.writeAsBytes(img.encodeJpg(image, quality: jpegQuality));

      return watermarkedPath;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('ImageUtils: Error adding watermark: $e');
        print('Stack: $stackTrace');
      }
      return imagePath;
    }
  }
}
