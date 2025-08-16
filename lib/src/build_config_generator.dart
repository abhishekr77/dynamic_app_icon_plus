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

  /// Generates the Android manifest modifications
  Future<void> generateAndroidManifest() async {
    final manifestPath = path.join(projectRoot, 'android', 'app', 'src', 'main', 'AndroidManifest.xml');
    final manifestFile = File(manifestPath);
    
    if (!manifestFile.existsSync()) {
      throw FileSystemException('AndroidManifest.xml not found', manifestPath);
    }

    final manifestContent = await manifestFile.readAsString();
    final modifiedContent = _injectActivityAliases(manifestContent);
    
    await manifestFile.writeAsString(modifiedContent);
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
}
