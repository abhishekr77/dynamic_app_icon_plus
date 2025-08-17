library dynamic_app_icon_plus;

import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as path;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'src/icon_config.dart';
import 'src/build_runner.dart';

/// A Flutter plugin for dynamically changing app icons on Android.
class DynamicAppIconPlus {
  static const MethodChannel _channel = MethodChannel('dynamic_app_icon_plus');
  
  static IconConfig? _config;
  static bool _initialized = false;

  /// Changes the app icon to the specified identifier.
  /// 
  /// If [iconIdentifier] is null, empty, or unknown, it will default to the default icon.
  /// Returns `true` if the icon was successfully changed, `false` otherwise.
  /// 
  /// Throws a [StateError] if the plugin hasn't been initialized.
  static Future<bool> changeIcon(String? iconIdentifier) async {
    if (!_initialized) {
      throw StateError('DynamicAppIconPlus has not been initialized. Call initialize() first.');
    }
    
    // Handle null or empty icon identifier
    if (iconIdentifier == null || iconIdentifier.trim().isEmpty) {
      print('DynamicAppIconPlus: No icon identifier provided, defaulting to default icon');
      iconIdentifier = 'default';
    }
    
    // Check if the icon is valid (but don't throw error, just warn)
    if (!isValidIcon(iconIdentifier)) {
      print('DynamicAppIconPlus: Unknown icon identifier "$iconIdentifier", defaulting to default icon');
      iconIdentifier = 'default';
    }
    
    try {
      final bool result = await _channel.invokeMethod('changeIcon', {
        'iconIdentifier': iconIdentifier,
      });
      return result;
    } on PlatformException catch (e) {
      throw PlatformException(
        code: e.code,
        message: e.message,
        details: e.details,
      );
    }
  }

  /// Checks if the current platform supports dynamic app icons.
  /// 
  /// Currently only Android is supported.
  static Future<bool> isSupported() async {
    try {
      final bool result = await _channel.invokeMethod('isSupported');
      return result;
    } on PlatformException {
      return false;
    }
  }

  /// Gets the currently active icon identifier.
  /// 
  /// Returns the identifier of the currently active icon, or `null` if
  /// no custom icon is currently set.
  static Future<String?> getCurrentIcon() async {
    try {
      final String? result = await _channel.invokeMethod('getCurrentIcon');
      return result;
    } on PlatformException {
      return null;
    }
  }

  /// Gets the list of available icon identifiers from the platform.
  /// 
  /// Returns a list of icon identifiers that are available on the current platform.
  static Future<List<String>> getAvailableIconsFromPlatform() async {
    try {
      final List<dynamic> result = await _channel.invokeMethod('getAvailableIcons');
      return result.cast<String>();
    } on PlatformException {
      return [];
    }
  }

  /// Resets the app icon to the default icon.
  /// 
  /// Returns `true` if the icon was successfully reset, `false` otherwise.
  static Future<bool> resetToDefault() async {
    try {
      final bool result = await _channel.invokeMethod('resetToDefault');
      return result;
    } on PlatformException catch (e) {
      throw PlatformException(
        code: e.code,
        message: e.message,
        details: e.details,
      );
    }
  }

  /// Resets all activities to enabled state for development.
  /// 
  /// This method enables both MainActivity and all activity aliases,
  /// ensuring the app can be launched during development.
  /// Returns `true` if the reset was successful, `false` otherwise.
  static Future<bool> resetForDevelopment() async {
    try {
      final bool result = await _channel.invokeMethod('resetForDevelopment');
      return result;
    } on PlatformException catch (e) {
      throw PlatformException(
        code: e.code,
        message: e.message,
        details: e.details,
      );
    }
  }

  /// Initializes the plugin with a configuration file.
  /// 
  /// This method should be called before using any other methods.
  /// The [configPath] should point to a YAML file containing icon definitions.
  /// The method will try to find the file in the following locations:
  /// 1. As an absolute path
  /// 2. In the app's assets (if added to pubspec.yaml)
  /// 3. In the app's documents directory
  static Future<void> initialize(String configPath, {bool validateFiles = true}) async {
    try {
      // Try to find the config file in multiple locations
      String? actualPath;
      
      // First, try the path as-is (absolute or relative to current directory)
      if (File(configPath).existsSync()) {
        actualPath = configPath;
      } else {
        // Try to load from assets first (most common case)
        try {
          final assetData = await rootBundle.loadString(configPath);
          _config = IconConfig.fromYamlString(assetData);
          final errors = _config!.validate(checkFiles: false); // Skip file validation for assets
          
          if (errors.isNotEmpty) {
            throw FormatException('Configuration validation failed:\n${errors.join('\n')}');
          }
          
          _initialized = true;
          return; // Successfully loaded from assets
        } catch (e) {
          // Not found in assets, continue to try file system
        }
        
        // Try to find it in common file system locations
        final possiblePaths = [
          configPath,
          path.join(Directory.current.path, configPath),
          path.join(Directory.current.path, 'assets', configPath),
          path.join(Directory.current.path, 'lib', configPath),
        ];
        
        for (final possiblePath in possiblePaths) {
          if (File(possiblePath).existsSync()) {
            actualPath = possiblePath;
            break;
          }
        }
      }
      
      if (actualPath == null) {
        throw FileSystemException(
          'Configuration file not found. Tried: $configPath, ${path.join(Directory.current.path, configPath)}, ${path.join(Directory.current.path, "assets", configPath)}, ${path.join(Directory.current.path, "lib", configPath)}. Please ensure the file exists and is added to your pubspec.yaml assets section.',
          configPath,
        );
      }
      
      _config = IconConfig.fromYamlFile(actualPath);
      final errors = _config!.validate(checkFiles: validateFiles);
      
      if (errors.isNotEmpty) {
        throw FormatException('Configuration validation failed:\n${errors.join('\n')}');
      }
      
      _initialized = true;
    } catch (e) {
      throw FormatException('Failed to initialize DynamicAppIconPlus: $e');
    }
  }

  /// Initializes the plugin with a configuration string.
  /// 
  /// This method should be called before using any other methods.
  /// The [configString] should be a valid YAML string containing icon definitions.
  static Future<void> initializeFromString(String configString, {bool validateFiles = true}) async {
    try {
      _config = IconConfig.fromYamlString(configString);
      final errors = _config!.validate(checkFiles: validateFiles);
      
      if (errors.isNotEmpty) {
        throw FormatException('Configuration validation failed:\n${errors.join('\n')}');
      }
      
      _initialized = true;
    } catch (e) {
      throw FormatException('Failed to initialize DynamicAppIconPlus: $e');
    }
  }

  /// Checks if the plugin has been initialized.
  static bool get isInitialized => _initialized;

  /// Gets the current configuration.
  /// 
  /// Returns `null` if the plugin hasn't been initialized.
  static IconConfig? get config => _config;

  /// Gets all available icon identifiers.
  /// 
  /// Returns an empty list if the plugin hasn't been initialized.
  static List<String> get availableIcons {
    if (!_initialized || _config == null) {
      return [];
    }
    return _config!.availableIcons;
  }

  /// Validates an icon identifier.
  /// 
  /// Returns `true` if the identifier exists in the configuration.
  static bool isValidIcon(String identifier) {
    if (!_initialized || _config == null) {
      return false;
    }
    return _config!.hasIcon(identifier);
  }

  /// Automatically sets up the project for dynamic app icons.
  /// 
  /// This method will:
  /// 1. Load the configuration from the specified file
  /// 2. Generate Android manifest modifications
  /// 3. Create build scripts and documentation
  /// 
  /// This is a convenience method that combines initialization and setup.
  static Future<void> setup(String configPath) async {
    final projectRoot = Directory.current.path;
    final runner = DynamicAppIconPlusBuildRunner(
      projectRoot: projectRoot,
      configPath: configPath,
    );

    await runner.run();
    await initialize(configPath);
  }

  /// Validates the current setup and returns any errors.
  /// 
  /// Returns a list of error messages, or an empty list if everything is valid.
  static Future<List<String>> validateSetup(String configPath) async {
    final projectRoot = Directory.current.path;
    final runner = DynamicAppIconPlusBuildRunner(
      projectRoot: projectRoot,
      configPath: configPath,
    );

    return await runner.validate();
  }

  /// Creates a backup of the Android manifest before making changes.
  static Future<void> backupAndroidManifest() async {
    final projectRoot = Directory.current.path;
    final runner = DynamicAppIconPlusBuildRunner(
      projectRoot: projectRoot,
      configPath: 'icon_config.yaml', // Default config path
    );

    await runner.backupAndroidManifest();
  }

  /// Restores the Android manifest from backup.
  static Future<void> restoreAndroidManifest() async {
    final projectRoot = Directory.current.path;
    final runner = DynamicAppIconPlusBuildRunner(
      projectRoot: projectRoot,
      configPath: 'icon_config.yaml', // Default config path
    );

    await runner.restoreAndroidManifest();
  }

  /// Uninstalls the plugin and restores the original state
  /// This will:
  /// 1. Remove all activity aliases from AndroidManifest.xml
  /// 2. Delete all generated icon files from res folders
  /// 3. Restore the original AndroidManifest.xml if backup exists
  /// 4. Clear plugin configuration
  static Future<bool> uninstall() async {
    try {
      if (!_initialized) {
        print('⚠️  Plugin not initialized. Nothing to uninstall.');
        return true;
      }

      print('🗑️  Uninstalling DynamicAppIconPlus...');

      // Get project root (assuming we're in the app directory)
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

      // 3. Clear plugin state
      _config = null;
      _initialized = false;
      print('✅ Plugin configuration cleared');

      print('🎉 Uninstall completed successfully!');
      return true;
    } catch (e) {
      print('❌ Uninstall failed: $e');
      return false;
    }
  }

  /// Checks if the plugin is already set up in the current project
  /// Returns true if activity aliases are already present in AndroidManifest.xml
  static Future<bool> isSetup() async {
    try {
      final projectRoot = Directory.current.path;
      final manifestPath = path.join(projectRoot, 'android', 'app', 'src', 'main', 'AndroidManifest.xml');
      
      final manifestFile = File(manifestPath);
      if (!manifestFile.existsSync()) {
        return false;
      }

      final content = await manifestFile.readAsString();
      
      // Check if activity-alias entries exist
      return content.contains('<activity-alias') && content.contains('android:name=".');
    } catch (e) {
      return false;
    }
  }

  /// Gets the list of currently configured icons from AndroidManifest.xml
  static Future<List<String>> getConfiguredIcons() async {
    try {
      final projectRoot = Directory.current.path;
      final manifestPath = path.join(projectRoot, 'android', 'app', 'src', 'main', 'AndroidManifest.xml');
      
      final manifestFile = File(manifestPath);
      if (!manifestFile.existsSync()) {
        return [];
      }

      final content = await manifestFile.readAsString();
      
      // Extract icon names from activity-alias entries
      final iconNames = <String>[];
      final regex = RegExp(r'android:name="\.(\w+)Activity"');
      final matches = regex.allMatches(content);
      
      for (final match in matches) {
        final iconName = match.group(1);
        if (iconName != null && iconName != 'Main') {
          iconNames.add(iconName);
        }
      }
      
      return iconNames.toSet().toList(); // Remove duplicates
    } catch (e) {
      return [];
    }
  }

  /// Removes activity aliases from AndroidManifest.xml
  static Future<void> _removeActivityAliases(String manifestPath) async {
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

  /// Removes generated icon files from res folders
  static Future<void> _removeGeneratedIcons(String projectRoot) async {
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

  /// Resets the plugin state (mainly for testing purposes)
  @visibleForTesting
  static void reset() {
    _initialized = false;
    _config = null;
  }
}
