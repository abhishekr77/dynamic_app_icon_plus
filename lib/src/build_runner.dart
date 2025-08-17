import 'dart:io';
import 'package:path/path.dart' as path;
import 'icon_config.dart';
import 'build_config_generator.dart';

/// Build runner for dynamic app icons
/// This can be integrated with Flutter's build system
class DynamicAppIconPlusBuildRunner {
  final String projectRoot;
  final String configPath;

  DynamicAppIconPlusBuildRunner({
    required this.projectRoot,
    required this.configPath,
  });

  /// Runs the build process
  Future<void> run() async {
    print('🎨 Dynamic App Icons Build Runner');
    print('==================================');
    print('');

    try {
      // Load configuration
      final config = IconConfig.fromYamlFile(configPath);
      
      // Validate configuration
      final configErrors = config.validate();
      if (configErrors.isNotEmpty) {
        throw FormatException('Configuration validation failed:\n${configErrors.join('\n')}');
      }

      // Create generator
      final generator = BuildConfigGenerator(
        config: config,
        projectRoot: projectRoot,
      );

      // Copy icon files to res folders
      await generator.copyIconsToRes();
      print('');

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

      // Generate documentation
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
      print('   await DynamicAppIconPlus.initialize(\'icon_config.yaml\');');
      print('');
      print('4. Use the plugin to change icons:');
      print('   await DynamicAppIconPlus.changeIcon(\'default\');');

    } catch (e) {
      print('❌ Build failed: $e');
      rethrow;
    }
  }

  /// Validates the current setup
  Future<List<String>> validate() async {
    final errors = <String>[];

    try {
      final config = IconConfig.fromYamlFile(configPath);
      errors.addAll(config.validate());

      final generator = BuildConfigGenerator(
        config: config,
        projectRoot: projectRoot,
      );

      errors.addAll(generator.validateIconFiles());

      // Check if Android manifest exists
      final manifestPath = path.join(projectRoot, 'android', 'app', 'src', 'main', 'AndroidManifest.xml');
      if (!File(manifestPath).existsSync()) {
        errors.add('AndroidManifest.xml not found at $manifestPath');
      }

    } catch (e) {
      errors.add('Failed to load configuration: $e');
    }

    return errors;
  }

  /// Creates a backup of the Android manifest
  Future<void> backupAndroidManifest() async {
    final manifestPath = path.join(projectRoot, 'android', 'app', 'src', 'main', 'AndroidManifest.xml');
    final backupPath = path.join(projectRoot, 'android', 'app', 'src', 'main', 'AndroidManifest.xml.backup');
    
    final manifestFile = File(manifestPath);
    if (manifestFile.existsSync()) {
      await manifestFile.copy(backupPath);
      print('✅ Android manifest backed up to AndroidManifest.xml.backup');
    }
  }

  /// Restores the Android manifest from backup
  Future<void> restoreAndroidManifest() async {
    final manifestPath = path.join(projectRoot, 'android', 'app', 'src', 'main', 'AndroidManifest.xml');
    final backupPath = path.join(projectRoot, 'android', 'app', 'src', 'main', 'AndroidManifest.xml.backup');
    
    final backupFile = File(backupPath);
    if (backupFile.existsSync()) {
      await backupFile.copy(manifestPath);
      print('✅ Android manifest restored from backup');
    } else {
      print('⚠️  No backup found to restore');
    }
  }
}
