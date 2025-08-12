import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class FileUtils {
  /// Get the appropriate directory for saving PDF files
  static Future<Directory> getPdfDirectory() async {
    Directory? directory;
    
    if (Platform.isAndroid) {
      // First try to get Downloads folder
      try {
        final downloadsDir = Directory('/storage/emulated/0/Download/TelecomField');
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }
        // Test write permission
        final testFile = File('${downloadsDir.path}/.test');
        await testFile.writeAsString('test');
        await testFile.delete();
        directory = downloadsDir;
      } catch (e) {
        print('Cannot access Downloads: $e');
        // Fallback to external storage
        try {
          final externalDir = await getExternalStorageDirectory();
          if (externalDir != null) {
            directory = Directory('${externalDir.path}/TelecomField');
            if (!await directory.exists()) {
              await directory.create(recursive: true);
            }
          }
        } catch (e) {
          print('Cannot access external storage: $e');
        }
      }
    }
    
    // Final fallback to app documents
    if (directory == null) {
      final appDir = await getApplicationDocumentsDirectory();
      directory = Directory('${appDir.path}/TelecomField');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
    }
    
    return directory;
  }

  /// Request necessary permissions for file operations
  static Future<bool> requestFilePermissions() async {
    if (Platform.isAndroid) {
      // Get Android version
      final androidInfo = await _getAndroidVersion();
      
      List<Permission> permissions = [];
      
      if (androidInfo >= 30) {
        // Android 11+ (API 30+)
        permissions = [
          Permission.camera,
          Permission.manageExternalStorage,
        ];
      } else if (androidInfo >= 23) {
        // Android 6+ (API 23+)
        permissions = [
          Permission.camera,
          Permission.storage,
        ];
      } else {
        // Older Android versions
        permissions = [
          Permission.camera,
        ];
      }
      
      Map<Permission, PermissionStatus> statuses = await permissions.request();
      
      // Check if all permissions are granted
      bool allGranted = statuses.values.every(
        (status) => status == PermissionStatus.granted
      );
      
      if (!allGranted) {
        print('Some permissions were denied');
        // Try to handle specific permission cases
        for (var entry in statuses.entries) {
          if (entry.value == PermissionStatus.denied) {
            print('${entry.key} permission denied');
          } else if (entry.value == PermissionStatus.permanentlyDenied) {
            print('${entry.key} permission permanently denied');
          }
        }
      }
      
      return allGranted;
    } else {
      // iOS - camera permission is usually enough
      final cameraStatus = await Permission.camera.request();
      return cameraStatus == PermissionStatus.granted;
    }
  }

  /// Check if we have write permission to directory
  static Future<bool> canWriteToDirectory(Directory directory) async {
    try {
      final testFile = File('${directory.path}/.write_test');
      await testFile.writeAsString('test write permission');
      final exists = await testFile.exists();
      if (exists) {
        await testFile.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Cannot write to ${directory.path}: $e');
      return false;
    }
  }

  /// Get Android API version
  static Future<int> _getAndroidVersion() async {
    if (Platform.isAndroid) {
      try {
        // This is a simplified approach
        // In a real app, you might want to use device_info_plus plugin
        return 30; // Assume modern Android for now
      } catch (e) {
        return 23; // Default to API 23
      }
    }
    return 0;
  }

  /// Create directory if it doesn't exist
  static Future<void> ensureDirectoryExists(Directory directory) async {
    if (!await directory.exists()) {
      try {
        await directory.create(recursive: true);
      } catch (e) {
        print('Error creating directory ${directory.path}: $e');
        throw Exception('Cannot create directory: ${directory.path}');
      }
    }
  }

  /// Get file size in human readable format
  static String getReadableFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double size = bytes.toDouble();
    
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    
    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }

  /// Clean up old files (older than 30 days)
  static Future<void> cleanupOldFiles(Directory directory) async {
    try {
      if (!await directory.exists()) return;
      
      final now = DateTime.now();
      final cutoffDate = now.subtract(const Duration(days: 30));
      
      await for (var entity in directory.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          if (stat.modified.isBefore(cutoffDate)) {
            try {
              await entity.delete();
              print('Deleted old file: ${entity.path}');
            } catch (e) {
              print('Error deleting ${entity.path}: $e');
            }
          }
        }
      }
    } catch (e) {
      print('Error during cleanup: $e');
    }
  }
}