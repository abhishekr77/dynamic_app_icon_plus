#!/usr/bin/env dart

import 'dart:io';
import 'package:path/path.dart' as path;
import '../lib/src/icon_config.dart';
import '../lib/src/build_config_generator.dart';
import '../lib/dynamic_app_icon_plus.dart';

/// Command-line tool for setting up dynamic app icons
void main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart run dynamic_app_icon_plus:dynamic_app_icon_plus <config_file>');
    print('   or: dart run dynamic_app_icon_plus:dynamic_app_icon_plus uninstall');
    print('');
    print('Commands:');
    print('  <config_file>  Setup dynamic app icons using the specified YAML config file');
    print('  uninstall      Remove the plugin and restore original state');
    exit(1);
  }

  final command = args.first;
  
  if (command == 'uninstall') {
    await _uninstall();
  } else {
    await _setup(command);
  }
}

Future<void> _uninstall() async {
  print('🗑️  Dynamic App Icons Uninstall');
  print('===============================');
  print('');

  try {
    final success = await DynamicAppIconPlus.uninstall();
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

Future<void> _setup(String configFile) async {
  final projectRoot = Directory.current.path;
  
  print('🎨 Dynamic App Icons Setup');
  print('==========================');
  print('');

  try {
    // Check if already set up
    final isAlreadySetup = await DynamicAppIconPlus.isSetup();
    if (isAlreadySetup) {
      final configuredIcons = await DynamicAppIconPlus.getConfiguredIcons();
      print('⚠️  Plugin is already set up!');
      print('   Currently configured icons: ${configuredIcons.join(', ')}');
      print('');
      print('Options:');
      print('1. Run setup again (will overwrite existing configuration)');
      print('2. Uninstall plugin (run: dart run dynamic_app_icon_plus:uninstall)');
      print('3. Exit');
      print('');
      
      // For now, we'll continue with setup but warn the user
      print('Continuing with setup (existing configuration will be overwritten)...');
      print('');
    }

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

    // Copy icon files to res folders
    await generator.copyIconsToRes();
    print('');

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
    print('1. Icons have been automatically copied to res folders');
    print('2. Android manifest has been updated');
    print('3. Initialize the plugin in your app:');
    print('   await DynamicAppIconPlus.initialize(\'$configFile\');');
    print('');
    print('4. Use the plugin to change icons:');
    print('   await DynamicAppIconPlus.changeIcon(\'${config.availableIcons.first}\');');
    print('');
    print('To uninstall the plugin later, run:');
    print('   dart run dynamic_app_icon_plus:uninstall');

  } catch (e) {
    print('❌ Setup failed: $e');
    exit(1);
  }
}
