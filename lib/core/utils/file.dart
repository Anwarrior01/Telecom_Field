import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class FileUtils {
  /// Get the appropriate directory for saving PDF files
  static Future<Directory> getPdfDirectory() async {
    Directory? directory;
    
    if (Platform.isAndroid) {
      // Try to use Downloads folder first
      directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        // Fallback to external storage
        directory = await getExternalStorageDirectory();
        if (directory != null) {
          directory = Directory('${directory.path}/TelecomField');
          if (!await directory.exists()) {
            await directory.create(recursive: true);
          }
        }
      }
    } else if (Platform.isIOS) {
      directory = await getApplicationDocumentsDirectory();
    }
    
    // Final fallback
    directory ??= await getApplicationDocumentsDirectory();
    
    return directory;
  }

  /// Request necessary permissions for file operations
  static Future<bool> requestFilePermissions() async {
    if (Platform.isAndroid) {
      final permissions = [
        Permission.camera,
        Permission.storage,
        Permission.manageExternalStorage,
      ];
      
      Map<Permission, PermissionStatus> statuses = 
          await permissions.request();
      
      return statuses.values.every((status) => status == PermissionStatus.granted);
    } else {
      return true;
    }
  }
}