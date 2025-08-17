import 'dart:io';
import 'dart:async';
import 'package:path/path.dart' as path;

/// Command-line tool for uninstalling dynamic app icons
void main(List<String> args) async {
  print('🗑️  Dynamic App Icons Uninstall');
  print('===============================');
  print('');

  try {
    final success = await _performUninstall();
    if (success) {
      print('');
      print('✅ Uninstall completed successfully!');
      print('The plugin has been removed and your project restored to its original state.');
    } else {
      print('');
      print('❌ Uninstall failed. Please check the error messages above.');
      exit(1);
    }
  } catch (e) {
    print('❌ Uninstall failed: $e');
    exit(1);
  }
}

Future<bool> _performUninstall() async {
  try {
    final projectRoot = Directory.current.path;
    
    // 1. Restore AndroidManifest.xml from backup if it exists
    final manifestPath = path.join(projectRoot, 'android', 'app', 'src', 'main', 'AndroidManifest.xml');
    final backupPath = path.join(projectRoot, 'android', 'app', 'src', 'main', 'AndroidManifest.xml.backup');
    
    final manifestFile = File(manifestPath);
    final backupFile = File(backupPath);
    
    if (manifestFile.existsSync()) {
      if (backupFile.existsSync()) {
        await backupFile.copy(manifestPath);
        print('✅ AndroidManifest.xml restored from backup');
      } else {
        // If no backup, remove activity aliases manually
        await _removeActivityAliases(manifestPath);
        print('✅ Activity aliases removed from AndroidManifest.xml');
      }
    } else {
      print('ℹ️  AndroidManifest.xml not found, skipping manifest cleanup');
    }

    // 2. Delete generated icon files
    await _removeGeneratedIcons(projectRoot);
    print('✅ Generated icon files removed');

    print('🎉 Uninstall completed successfully!');
    return true;
  } catch (e) {
    print('❌ Uninstall failed: $e');
    return false;
  }
}

Future<void> _removeActivityAliases(String manifestPath) async {
  final manifestFile = File(manifestPath);
  if (!manifestFile.existsSync()) {
    throw FileSystemException('AndroidManifest.xml not found', manifestPath);
  }

  final content = await manifestFile.readAsString();
  
  // Remove all activity-alias entries
  final cleanedContent = content.replaceAllMapped(
    RegExp(r'\s*<!-- Activity alias for .*? -->\s*<activity-alias[^>]*>.*?</activity-alias>\s*', dotAll: true),
    (match) => '',
  );

  await manifestFile.writeAsString(cleanedContent);
}

Future<void> _removeGeneratedIcons(String projectRoot) async {
  final resBasePath = path.join(projectRoot, 'android', 'app', 'src', 'main', 'res');
  final densities = ['mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi'];

  for (final density in densities) {
    final densityPath = path.join(resBasePath, 'mipmap-$density');
    final densityDir = Directory(densityPath);
    
    if (densityDir.existsSync()) {
      // Remove all ic_launcher_*.png files except the default ic_launcher.png
      final files = densityDir.listSync();
      for (final file in files) {
        if (file is File && file.path.contains('ic_launcher_') && !file.path.endsWith('ic_launcher.png')) {
          await file.delete();
        }
      }
    }
  }
}
