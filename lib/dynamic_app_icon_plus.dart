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

  /// Changes the app icon to the specified icon.
  /// 
  /// The [iconIdentifier] should match one of the identifiers defined in the configuration.
  /// If the identifier is null, empty, or unknown, it will default to the configured default icon.
  /// 
  /// Throws a [StateError] if the plugin hasn't been initialized.
  static Future<bool> changeIcon(String? iconIdentifier) async {
    if (!_initialized) {
      throw StateError('DynamicAppIconPlus has not been initialized. Call initialize() first.');
    }
    
    // Handle null or empty icon identifier
    if (iconIdentifier == null || iconIdentifier.trim().isEmpty) {
      final defaultIcon = _config?.defaultIcon ?? 'default';
      print('DynamicAppIconPlus: No icon identifier provided, defaulting to configured default icon: $defaultIcon');
      iconIdentifier = defaultIcon;
    }
    
    // Check if the icon is valid (but don't throw error, just warn)
    if (!isValidIcon(iconIdentifier)) {
      final defaultIcon = _config?.defaultIcon ?? 'default';
      print('DynamicAppIconPlus: Unknown icon identifier "$iconIdentifier", defaulting to configured default icon: $defaultIcon');
      iconIdentifier = defaultIcon;
    }
    
    try {
      final bool result = await _channel.invokeMethod('changeIcon', {
        'iconIdentifier': iconIdentifier,
        'availableIcons': availableIcons, // Pass available icons from YAML config
        'defaultIcon': _config?.defaultIcon ?? 'default', // Pass configured default icon
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

  /// Gets the current icon identifier.
  /// 
  /// Returns the identifier of the currently active icon, or `null` if
  /// no custom icon is currently set.
  static Future<String?> getCurrentIcon() async {
    try {
      final String? result = await _channel.invokeMethod('getCurrentIcon', {
        'availableIcons': availableIcons, // Pass available icons from YAML config
      });
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
      final bool result = await _channel.invokeMethod('resetToDefault', {
        'availableIcons': availableIcons, // Pass available icons from YAML config
        'defaultIcon': _config?.defaultIcon ?? 'default', // Pass configured default icon
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

  /// Resets all activities to enabled state for development.
  /// 
  /// This method enables both MainActivity and all activity aliases,
  /// ensuring the app can be launched during development.
  /// Returns `true` if the reset was successful, `false` otherwise.
  static Future<bool> resetForDevelopment() async {
    try {
      final bool result = await _channel.invokeMethod('resetForDevelopment', {
        'availableIcons': availableIcons, // Pass available icons from YAML config
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

  /// Initializes the plugin with a configuration file.
  /// 
  /// This method should be called before using any other methods.
  /// The [configPath] should point to a YAML file containing icon definitions.
  /// The method will try to find the file in the following locations:
  /// 1. As an absolute path
  /// 2. In the app's assets (if added to pubspec.yaml)
  /// 3. In the app's documents directory
  static Future<void> initialize(String configPath, {bool validateFiles = true, bool setDefaultIcon = false}) async {
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
          
          // Automatically set the default icon if requested (but don't fail if it doesn't work)
          if (setDefaultIcon && _config!.defaultIcon != null) {
            try {
              // Add a small delay to ensure the app is fully loaded
              await Future.delayed(Duration(milliseconds: 500));
              await changeIcon(_config!.defaultIcon);
              print('DynamicAppIconPlus: Default icon set successfully on initialization: ${_config!.defaultIcon}');
            } catch (e) {
              print('DynamicAppIconPlus: Warning - Could not set default icon during initialization: $e');
              print('DynamicAppIconPlus: You can manually set the default icon later using changeIcon() or setDefaultIcon()');
            }
          }
          
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
      
      // Automatically set the default icon if requested (but don't fail if it doesn't work)
      if (setDefaultIcon && _config!.defaultIcon != null) {
        try {
          // Add a small delay to ensure the app is fully loaded
          await Future.delayed(Duration(milliseconds: 500));
          await changeIcon(_config!.defaultIcon);
          print('DynamicAppIconPlus: Default icon set successfully on initialization: ${_config!.defaultIcon}');
        } catch (e) {
          print('DynamicAppIconPlus: Warning - Could not set default icon during initialization: $e');
          print('DynamicAppIconPlus: You can manually set the default icon later using changeIcon() or setDefaultIcon()');
        }
      }
      
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
  /// 4. Automatically set the default icon (disabled by default to prevent crashes)
  /// 
  /// This is a convenience method that combines initialization and setup.
  static Future<void> setup(String configPath, {bool setDefaultIcon = false}) async {
    final projectRoot = Directory.current.path;
    final runner = DynamicAppIconPlusBuildRunner(
      projectRoot: projectRoot,
      configPath: configPath,
    );

    await runner.run();
    await initialize(configPath, setDefaultIcon: setDefaultIcon);
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

  /// Sets the default icon after the app is fully loaded.
  /// 
  /// This method should be called after the app has fully initialized to avoid crashes.
  /// It will set the icon specified in the default_icon field of your YAML configuration.
  static Future<bool> setDefaultIcon() async {
    if (!_initialized) {
      throw StateError('DynamicAppIconPlus has not been initialized. Call initialize() first.');
    }
    
    if (_config?.defaultIcon == null) {
      print('DynamicAppIconPlus: No default icon configured in YAML');
      return false;
    }
    
    try {
      final result = await changeIcon(_config!.defaultIcon);
      if (result) {
        print('DynamicAppIconPlus: Default icon set successfully: ${_config!.defaultIcon}');
      }
      return result;
    } catch (e) {
      print('DynamicAppIconPlus: Error setting default icon: $e');
      return false;
    }
  }

  /// Resets the plugin state (mainly for testing purposes)
  @visibleForTesting
  static void reset() {
    _initialized = false;
    _config = null;
  }
}
