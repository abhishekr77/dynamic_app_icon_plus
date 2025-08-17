#!/usr/bin/env dart

import 'dart:io';
import 'dart:async';
import 'package:path/path.dart' as path;

import '../lib/src/icon_config.dart';
import '../lib/src/build_config_generator.dart';

/// Command-line tool for setting up dynamic app icons
/// This tool can run setup or uninstall operations
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

Future<bool> _isSetup() async {
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

Future<List<String>> _getConfiguredIcons() async {
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

Future<void> _setup(String configFile) async {
  final projectRoot = Directory.current.path;
  
  print('🎨 Dynamic App Icons Setup');
  print('==========================');
  print('');

  try {
    // Check if already set up
    final isAlreadySetup = await _isSetup();
    if (isAlreadySetup) {
      final configuredIcons = await _getConfiguredIcons();
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
