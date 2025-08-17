import 'dart:io';
import 'package:path/path.dart' as path;
import 'icon_config.dart';

/// Generates Android build configuration files based on icon configuration
class BuildConfigGenerator {
  final IconConfig config;
  final String projectRoot;

  BuildConfigGenerator({
    required this.config,
    required this.projectRoot,
  });

  /// Generates Android manifest modifications
  Future<void> generateAndroidManifest() async {
    final manifestPath = path.join(projectRoot, 'android', 'app', 'src', 'main', 'AndroidManifest.xml');
    final manifestFile = File(manifestPath);
    
    if (!manifestFile.existsSync()) {
      throw FileSystemException('AndroidManifest.xml not found', manifestPath);
    }

    // Create backup first
    final backupPath = path.join(projectRoot, 'android', 'app', 'src', 'main', 'AndroidManifest.xml.backup');
    if (!File(backupPath).existsSync()) {
      await manifestFile.copy(backupPath);
    }

    final content = await manifestFile.readAsString();
    
    // Remove existing activity aliases to prevent duplicates
    final cleanedContent = _removeExistingActivityAliases(content);
    
    // Inject new activity aliases
    final modifiedContent = _injectActivityAliases(cleanedContent);
    
    await manifestFile.writeAsString(modifiedContent);
  }

  /// Removes existing activity aliases from the manifest content
  String _removeExistingActivityAliases(String content) {
    // Remove all activity-alias entries and their comments
    // First, remove activity aliases with comments
    var cleanedContent = content.replaceAllMapped(
      RegExp(r'\s*<!-- Activity alias for .*? -->\s*<activity-alias[^>]*>.*?</activity-alias>\s*', dotAll: true),
      (match) => '',
    );
    
    // Then, remove any remaining activity-alias entries without comments
    cleanedContent = cleanedContent.replaceAllMapped(
      RegExp(r'\s*<activity-alias[^>]*>.*?</activity-alias>\s*', dotAll: true),
      (match) => '',
    );
    
    return cleanedContent;
  }

  /// Injects activity aliases into the AndroidManifest.xml
  String _injectActivityAliases(String manifestContent) {
    final activityAliases = _generateActivityAliases();
    
    // Find the closing </application> tag
    final applicationEndIndex = manifestContent.lastIndexOf('</application>');
    if (applicationEndIndex == -1) {
      throw FormatException('Could not find </application> tag in AndroidManifest.xml');
    }

    // Insert activity aliases before the closing application tag
    final beforeApplicationEnd = manifestContent.substring(0, applicationEndIndex);
    final afterApplicationEnd = manifestContent.substring(applicationEndIndex);
    
    return '$beforeApplicationEnd\n$activityAliases\n$afterApplicationEnd';
  }

  /// Generates activity alias XML for each icon
  String _generateActivityAliases() {
    final buffer = StringBuffer();
    
    for (final icon in config.icons.values) {
      if (icon.identifier == 'default') continue; // Skip default icon
      
      buffer.writeln('        <!-- Activity alias for ${icon.identifier} icon -->');
      buffer.writeln('        <activity-alias');
      buffer.writeln('            android:name=".${icon.identifier}Activity"');
      buffer.writeln('            android:enabled="false"');
      buffer.writeln('            android:exported="true"');
      buffer.writeln('            android:icon="@mipmap/ic_launcher_${icon.identifier}"');
      buffer.writeln('            android:targetActivity=".MainActivity">');
      buffer.writeln('            <intent-filter>');
      buffer.writeln('                <action android:name="android.intent.action.MAIN" />');
      buffer.writeln('                <category android:name="android.intent.category.LAUNCHER" />');
      buffer.writeln('            </intent-filter>');
      buffer.writeln('        </activity-alias>');
      buffer.writeln();
    }
    
    return buffer.toString().trim();
  }

  /// Generates a build script that can be run to set up the project
  Future<void> generateBuildScript() async {
    final scriptContent = _generateBuildScriptContent();
    final scriptPath = path.join(projectRoot, 'scripts', 'setup_dynamic_icons.dart');
    
    final scriptDir = Directory(path.dirname(scriptPath));
    if (!scriptDir.existsSync()) {
      scriptDir.createSync(recursive: true);
    }
    
    final scriptFile = File(scriptPath);
    await scriptFile.writeAsString(scriptContent);
  }

  /// Generates the content for the build script
  String _generateBuildScriptContent() {
    return '''
import 'dart:io';
import 'package:path/path.dart' as path;

/// Auto-generated script to set up dynamic app icons
/// Run this script after adding new icons to your configuration

void main() async {
  print('Setting up dynamic app icons...');
  
  final projectRoot = Directory.current.path;
  final manifestPath = path.join(projectRoot, 'android', 'app', 'src', 'main', 'AndroidManifest.xml');
  
  if (!File(manifestPath).existsSync()) {
    print('Error: AndroidManifest.xml not found at \$manifestPath');
    exit(1);
  }
  
  print('✓ AndroidManifest.xml found');
  print('✓ Activity aliases will be generated automatically');
  print('✓ Make sure to add your icon files to the appropriate mipmap folders');
  print('');
  print('Available icons: ${config.availableIcons.join(', ')}');
  print('');
  print('Setup complete! You can now use DynamicAppIconPlus.changeIcon() in your app.');
}
''';
  }

  /// Generates a README section for the generated configuration
  String generateReadmeSection() {
    final buffer = StringBuffer();
    
    buffer.writeln('## Dynamic App Icons Setup');
    buffer.writeln();
    buffer.writeln('This project uses dynamic app icons. The following icons are available:');
    buffer.writeln();
    
    for (final icon in config.icons.values) {
      buffer.writeln('- **${icon.identifier}**: ${icon.label ?? icon.identifier}');
      if (icon.description != null) {
        buffer.writeln('  - ${icon.description}');
      }
      buffer.writeln('  - Icon file: `${icon.path}`');
      buffer.writeln();
    }
    
    buffer.writeln('### Usage');
    buffer.writeln();
    buffer.writeln('```dart');
    buffer.writeln('// Change to a specific icon');
    buffer.writeln('await DynamicAppIconPlus.changeIcon(\'${config.availableIcons.first}\');');
    buffer.writeln();
    buffer.writeln('// Reset to default');
    buffer.writeln('await DynamicAppIconPlus.resetToDefault();');
    buffer.writeln('```');
    
    return buffer.toString();
  }

  /// Validates that all required icon files exist
  List<String> validateIconFiles() {
    final errors = <String>[];
    
    for (final icon in config.icons.values) {
      final iconPath = path.join(projectRoot, icon.path);
      if (!File(iconPath).existsSync()) {
        errors.add('Icon file not found: ${icon.path}');
      }
    }
    
    return errors;
  }

  /// Copies icon files from assets to res folders
  Future<void> copyIconsToRes() async {
    print('📁 Copying icon files to res folders...');
    
    final resBasePath = path.join(projectRoot, 'android', 'app', 'src', 'main', 'res');
    final densities = ['mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi'];
    
    for (final icon in config.icons.values) {
      // Copy to each density folder
      for (final density in densities) {
        final densityPath = path.join(resBasePath, 'mipmap-$density');
        final densityDir = Directory(densityPath);
        
        if (!densityDir.existsSync()) {
          densityDir.createSync(recursive: true);
        }
        
        final targetFileName = icon.identifier == 'default' 
            ? 'ic_launcher.png' 
            : 'ic_launcher_${icon.identifier}.png';
        final targetPath = path.join(densityPath, targetFileName);
        
        // Determine source path for this density
        String sourcePath;
        if (icon.sizes != null && icon.sizes!.containsKey(density)) {
          // Use specific resolution path if available
          sourcePath = path.join(projectRoot, icon.sizes![density]!);
          print('📱 Using specific ${density} resolution: ${icon.sizes![density]}');
        } else {
          // Fall back to main path
          sourcePath = path.join(projectRoot, icon.path);
          print('📱 Using main path for ${density}: ${icon.path}');
        }
        
        final sourceFile = File(sourcePath);
        
        if (!sourceFile.existsSync()) {
          print('⚠️  Warning: Source icon file not found: $sourcePath');
          continue;
        }
        
        try {
          await sourceFile.copy(targetPath);
          print('✅ Copied ${icon.identifier} to mipmap-$density/$targetFileName');
        } catch (e) {
          print('❌ Failed to copy ${icon.identifier} to mipmap-$density: $e');
        }
      }
    }
    
    print('📁 Icon copying completed!');
  }

  /// Runs the build process
  Future<void> run() async {
    print('🎨 Dynamic App Icons Build Runner');
    print('==================================');
    print('');

    try {
      // Validate configuration
      final configErrors = config.validate();
      if (configErrors.isNotEmpty) {
        throw FormatException('Configuration validation failed:\n${configErrors.join('\n')}');
      }

      // Copy icon files to res folders
      await copyIconsToRes();
      print('');

      // Validate icon files
      print('🔍 Validating icon files...');
      final fileErrors = validateIconFiles();
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
        await generateAndroidManifest();
        print('✅ Android manifest updated successfully');
      } catch (e) {
        print('❌ Failed to update Android manifest: $e');
        print('');
        print('Please make sure you have an Android project set up.');
        exit(1);
      }

      // Generate build script
      print('📜 Generating build script...');
      await generateBuildScript();
      print('✅ Build script generated at scripts/setup_dynamic_icons.dart');
      print('');

      // Generate README section
      print('📖 Generating documentation...');
      final readmeSection = generateReadmeSection();
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
}
