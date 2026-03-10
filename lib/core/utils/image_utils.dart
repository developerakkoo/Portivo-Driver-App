import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Image utility class for compression and resizing
class ImageUtils {
  /// Maximum file size in bytes (2MB)
  static const int maxFileSizeBytes = 2 * 1024 * 1024;
  
  /// Maximum image width/height for compression
  static const int maxImageDimension = 1920;
  
  /// Quality for JPEG compression (0-100)
  static const int jpegQuality = 85;

  /// Compress and resize image if needed
  /// Returns the path to the compressed image file
  static Future<String> compressImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        throw Exception('Image file does not exist');
      }

      // Check file size
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

      // Read image bytes
      final imageBytes = await file.readAsBytes();
      
      // Decode image
      img.Image? image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Resize if needed
      if (image.width > maxImageDimension || image.height > maxImageDimension) {
        if (kDebugMode) {
          print('ImageUtils: Resizing image from ${image.width}x${image.height}');
        }
        image = img.copyResize(
          image,
          width: image.width > image.height ? maxImageDimension : null,
          height: image.height > image.width ? maxImageDimension : null,
          maintainAspect: true,
        );
        if (kDebugMode) {
          print('ImageUtils: Resized to ${image.width}x${image.height}');
        }
      }

      // Compress image
      Uint8List compressedBytes;
      final extension = path.extension(imagePath).toLowerCase();
      
      if (extension == '.png') {
        // PNG compression
        compressedBytes = Uint8List.fromList(img.encodePng(image));
      } else {
        // JPEG compression (default)
        compressedBytes = Uint8List.fromList(
          img.encodeJpg(image, quality: jpegQuality),
        );
      }

      // Check if compression helped
      if (compressedBytes.length >= fileSize) {
        if (kDebugMode) {
          print('ImageUtils: Compression did not reduce size, using original');
        }
        return imagePath;
      }

      // Save compressed image to temporary file
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
      // Return original path if compression fails
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

  /// Check if image needs compression
  static Future<bool> needsCompression(String imagePath) async {
    final fileSize = await getFileSize(imagePath);
    return fileSize > maxFileSizeBytes;
  }
}
