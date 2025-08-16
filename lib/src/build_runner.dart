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

      // Generate Android manifest modifications
      await generator.generateAndroidManifest();
      
      // Generate build script
      await generator.generateBuildScript();
      
      // Generate documentation
      final readmeSection = generator.generateReadmeSection();
      final readmePath = path.join(projectRoot, 'DYNAMIC_ICONS_README.md');
      await File(readmePath).writeAsString(readmeSection);

      print('✅ Build completed successfully');
      print('   - Android manifest updated');
      print('   - Build script generated');
      print('   - Documentation generated');
      print('   - Available icons: ${config.availableIcons.join(', ')}');

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
