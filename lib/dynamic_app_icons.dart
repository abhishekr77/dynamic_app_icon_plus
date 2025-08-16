library dynamic_app_icon_plus;

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'src/icon_config.dart';
import 'src/build_runner.dart';

/// A Flutter plugin for dynamically changing app icons on Android.
class DynamicAppIconPlus {
  static const MethodChannel _channel = MethodChannel('dynamic_app_icon_plus');
  
  static IconConfig? _config;
  static bool _initialized = false;

  /// Changes the app icon to the one specified by [iconIdentifier].
  /// 
  /// The [iconIdentifier] should match one of the identifiers defined in your
  /// configuration file.
  /// 
  /// Returns `true` if the icon was successfully changed, `false` otherwise.
  /// 
  /// Throws a [PlatformException] if the platform doesn't support dynamic icons
  /// or if there's an error during the icon change process.
  /// 
  /// Throws a [StateError] if the plugin hasn't been initialized.
  /// Throws an [ArgumentError] if the icon identifier is not valid.
  static Future<bool> changeIcon(String iconIdentifier) async {
    if (!_initialized) {
      throw StateError('DynamicAppIconPlus has not been initialized. Call initialize() first.');
    }
    
    if (!isValidIcon(iconIdentifier)) {
      throw ArgumentError('Invalid icon identifier: $iconIdentifier. Available icons: ${availableIcons.join(', ')}');
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

  /// Initializes the plugin with a configuration file.
  /// 
  /// This method should be called before using any other methods.
  /// The [configPath] should point to a YAML file containing icon definitions.
  static Future<void> initialize(String configPath, {bool validateFiles = true}) async {
    try {
      _config = IconConfig.fromYamlFile(configPath);
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

  /// Resets the plugin state (mainly for testing purposes)
  @visibleForTesting
  static void reset() {
    _initialized = false;
    _config = null;
  }
}
