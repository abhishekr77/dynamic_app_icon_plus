import 'dart:io';
import 'dart:async';
import 'package:path/path.dart' as path;

import '../lib/src/icon_config.dart';
import '../lib/src/build_config_generator.dart';

/// Command-line tool for setting up dynamic app icons
void main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart run dynamic_app_icon_plus:setup <config_file>');
    print('');
    print('Examples:');
    print('  dart run dynamic_app_icon_plus:setup icon_config.yaml');
    print('  dart run dynamic_app_icon_plus:setup my_icons.yaml');
    exit(1);
  }

  final configFile = args.first;
  await _setup(configFile);
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
