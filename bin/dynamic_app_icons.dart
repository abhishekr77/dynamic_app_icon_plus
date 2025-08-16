#!/usr/bin/env dart

import 'dart:io';
import 'package:path/path.dart' as path;
import '../lib/src/icon_config.dart';
import '../lib/src/build_config_generator.dart';

/// Command-line tool for setting up dynamic app icons
void main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart run dynamic_app_icon_plus:dynamic_app_icon_plus [config_file]');
    print('');
    print('Options:');
    print('  config_file    Path to the YAML configuration file (default: icon_config.yaml)');
    print('');
    print('Examples:');
    print('  dart run dynamic_app_icon_plus:dynamic_app_icon_plus');
    print('  dart run dynamic_app_icon_plus:dynamic_app_icon_plus my_icons.yaml');
    exit(1);
  }

  final configFile = args.first;
  final projectRoot = Directory.current.path;
  
  print('🎨 Dynamic App Icons Setup');
  print('==========================');
  print('');

  try {
    // Load configuration
    print('📋 Loading configuration from $configFile...');
    final config = IconConfig.fromYamlFile(configFile);
    
    // Validate configuration
    final configErrors = config.validate();
    if (configErrors.isNotEmpty) {
      print('❌ Configuration validation failed:');
      for (final error in configErrors) {
        print('   - $error');
      }
      exit(1);
    }
    
    print('✅ Configuration loaded successfully');
    print('   Available icons: ${config.availableIcons.join(', ')}');
    print('');

    // Create build config generator
    final generator = BuildConfigGenerator(
      config: config,
      projectRoot: projectRoot,
    );

    // Validate icon files
    print('🔍 Validating icon files...');
    final fileErrors = generator.validateIconFiles();
    if (fileErrors.isNotEmpty) {
      print('⚠️  Warning: Some icon files are missing:');
      for (final error in fileErrors) {
        print('   - $error');
      }
      print('');
      print('Please add the missing icon files before building your app.');
      print('');
    } else {
      print('✅ All icon files found');
      print('');
    }

    // Generate Android manifest modifications
    print('📱 Setting up Android manifest...');
    try {
      await generator.generateAndroidManifest();
      print('✅ Android manifest updated successfully');
    } catch (e) {
      print('❌ Failed to update Android manifest: $e');
      print('');
      print('Please make sure you have an Android project set up.');
      exit(1);
    }

    // Generate build script
    print('📜 Generating build script...');
    await generator.generateBuildScript();
    print('✅ Build script generated at scripts/setup_dynamic_icons.dart');
    print('');

    // Generate README section
    print('📖 Generating documentation...');
    final readmeSection = generator.generateReadmeSection();
    final readmePath = path.join(projectRoot, 'DYNAMIC_ICONS_README.md');
    await File(readmePath).writeAsString(readmeSection);
    print('✅ Documentation generated at DYNAMIC_ICONS_README.md');
    print('');

    print('🎉 Setup completed successfully!');
    print('');
    print('Next steps:');
    print('1. Add your icon files to the appropriate mipmap folders:');
    print('   - android/app/src/main/res/mipmap-hdpi/');
    print('   - android/app/src/main/res/mipmap-mdpi/');
    print('   - android/app/src/main/res/mipmap-xhdpi/');
    print('   - android/app/src/main/res/mipmap-xxhdpi/');
    print('   - android/app/src/main/res/mipmap-xxxhdpi/');
    print('');
    print('2. Initialize the plugin in your app:');
    print('   await DynamicAppIconPlus.initialize(\'$configFile\');');
    print('');
    print('3. Use the plugin to change icons:');
    print('   await DynamicAppIconPlus.changeIcon(\'${config.availableIcons.first}\');');
    print('');

  } catch (e) {
    print('❌ Setup failed: $e');
    exit(1);
  }
}
