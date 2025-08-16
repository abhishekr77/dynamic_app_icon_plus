# Changelog

All notable changes to the `dynamic_app_icons` plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.1] - 2024-01-XX

### Added
- Initial release of dynamic_app_icons plugin
- Support for dynamically changing Android app icons at runtime
- YAML-based configuration system for icon definitions
- Command-line setup tool for automatic project configuration
- Android manifest generation with activity aliases
- Comprehensive validation and error handling
- Support for Flutter 3.0.0+ and Dart 3.0.0+
- Backward compatibility with older Flutter versions
- Simple and advanced icon configuration formats
- Optional resolution support for different screen densities
- Automatic backup and restore functionality for Android manifests
- Comprehensive test suite with 10 test cases
- Example app demonstrating plugin usage
- Detailed documentation and usage examples

### Features
- `DynamicAppIconPlus.setup()` - Automatic project setup and initialization
- `DynamicAppIconPlus.changeIcon()` - Change app icon to specified identifier
- `DynamicAppIconPlus.resetToDefault()` - Reset to default app icon
- `DynamicAppIconPlus.getCurrentIcon()` - Get currently active icon identifier
- `DynamicAppIconPlus.isSupported()` - Check platform support
- `DynamicAppIconPlus.validateSetup()` - Validate current setup
- Command-line tool: `dart run dynamic_app_icon_plus:dynamic_app_icon_plus`

### Technical Details
- Uses Flutter v2 embedding for Android
- Implements both modern and legacy plugin registration
- Method channel communication for platform-specific functionality
- YAML parsing with validation
- File system operations for configuration management
- Android PackageManager integration for icon switching
