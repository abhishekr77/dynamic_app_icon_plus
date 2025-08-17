# Dynamic App Icon Plus

A Flutter plugin for dynamically changing app icons on Android at runtime with simple YAML configuration.

## Features

- 🎨 **Dynamic Icon Switching**: Change your app icon at runtime
- 📝 **Simple YAML Configuration**: Define icons with easy-to-use YAML format
- 🔧 **Automatic Setup**: Command-line tool for easy project setup
- 📱 **Android Support**: Full support for Android dynamic icons
- 🚀 **Zero Boilerplate**: Works out of the box with minimal setup

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  dynamic_app_icon_plus:
    git:
      url: https://github.com/abhishekr77/dynamic_app_icon_plus
      ref: main
```

## Quick Start

### 1. Create Configuration File

Create `icon_config.yaml` in your project root:

```yaml
default_icon: "default"

icons:
  default:
    path: "assets/icons/default_icon.png"
    label: "Default Icon"
    description: "The default app icon"

  christmas:
    path: "assets/icons/christmas_icon.png"
    label: "Christmas Icon"
    description: "Festive Christmas-themed app icon"

  halloween:
    path: "assets/icons/halloween_icon.png"
    label: "Halloween Icon"
    description: "Spooky Halloween-themed app icon"
```

### 2. Run Setup Tool

```bash
dart run dynamic_app_icon_plus:dynamic_app_icon_plus icon_config.yaml
```

This will automatically:
- **Copy your icon files** from assets to the appropriate res folders
- Update your Android manifest
- Generate build scripts
- Create documentation

### 3. That's It! 🎉

The setup tool now automatically copies your icon files from the paths specified in your YAML to the correct Android res folders. No manual copying needed!

### 4. Use in Your App

```dart
import 'package:dynamic_app_icon_plus/dynamic_app_icon_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize the plugin
  await DynamicAppIconPlus.initialize('icon_config.yaml');
  
  // For development: reset all activities to enabled state
  await DynamicAppIconPlus.resetForDevelopment();
  
  runApp(MyApp());
}

// Change icon
await DynamicAppIconPlus.changeIcon('christmas');

// Reset to default
await DynamicAppIconPlus.resetToDefault();

// Get current icon
String currentIcon = await DynamicAppIconPlus.getCurrentIcon();
```

## Development Workflow

### During Development:
1. **Always call `resetForDevelopment()`** after initialization to keep all activities enabled
2. **Test icon changes** by calling `changeIcon()`
3. **Restart the app** to see the icon change
4. **If you can't run the app**, call `resetForDevelopment()` again

### For Production:
1. **Remove the `resetForDevelopment()` call** from your production code
2. **Icon changes will work normally** with proper activity switching

## That's It! 🎉

No manual registration, no complex setup - just add the dependency, create a config file, run the setup tool, and you're ready to go!

## API Reference

### Methods

#### `initialize(String configPath)`
Initializes the plugin with a configuration file.

#### `changeIcon(String? iconIdentifier)`
Changes the app icon to the specified identifier.
- If `iconIdentifier` is null, empty, or unknown, it defaults to the default icon
- No errors are thrown for invalid icons - they automatically fallback to default

#### `resetToDefault()`
Resets the app icon to the default icon.

#### `getCurrentIcon()`
Gets the currently active icon identifier.

#### `isSupported()`
Checks if the current platform supports dynamic app icons.

#### `resetForDevelopment()`
Resets all activities to enabled state for development.

#### `getAvailableIconsFromPlatform()`
Gets the list of available icon identifiers from the platform.

### Properties

#### `availableIcons`
Gets a list of all available icon identifiers from the configuration.

#### `isInitialized`
Checks if the plugin has been initialized.

## Error Handling

The plugin now provides graceful error handling:

```dart
// These all work and default to the default icon
await DynamicAppIconPlus.changeIcon(null);
await DynamicAppIconPlus.changeIcon('');
await DynamicAppIconPlus.changeIcon('unknown_icon');
await DynamicAppIconPlus.changeIcon('invalid');

// This works normally
await DynamicAppIconPlus.changeIcon('christmas');
```

## Configuration Format

### Simple Format
```yaml
default_icon: "default"

icons:
  default: "assets/icons/default.png"
  christmas: "assets/icons/christmas.png"
  halloween: "assets/icons/halloween.png"
```

### Advanced Format
```yaml
default_icon: "default"

icons:
  default:
    path: "assets/icons/default.png"
    label: "Default Icon"
    description: "The default app icon"
  
  christmas:
    path: "assets/icons/christmas.png"
    sizes:
      mdpi: "assets/icons/christmas_48x48.png"
      hdpi: "assets/icons/christmas_72x72.png"
      xhdpi: "assets/icons/christmas_96x96.png"
      xxhdpi: "assets/icons/christmas_144x144.png"
      xxxhdpi: "assets/icons/christmas_192x192.png"
    label: "Christmas Icon"
    description: "Festive Christmas-themed app icon"
```

### Advanced Format with Specific Resolutions
```yaml
default_icon: "default"

icons:
  default:
    path: "assets/images/launcher_icon.png"
    sizes:
      mdpi: "assets/images/launcher_icon_48x48.png"
      hdpi: "assets/images/launcher_icon_72x72.png"
      xhdpi: "assets/images/launcher_icon_96x96.png"
      xxhdpi: "assets/images/launcher_icon_144x144.png"
      xxxhdpi: "assets/images/launcher_icon_192x192.png"
    label: "Default Icon"
    description: "The default app icon"

  independance:
    path: "assets/images/card2.png"
    sizes:
      mdpi: "assets/images/card2_48x48.png"
      hdpi: "assets/images/card2_72x72.png"
      xhdpi: "assets/images/card2_96x96.png"
      xxhdpi: "assets/images/card2_144x144.png"
      xxxhdpi: "assets/images/card2_192x192.png"
    label: "Independence Icon"
    description: "Independence day themed icon"
```

## Resolution Guidelines

When using specific resolution paths, use these dimensions:
- **mdpi**: 48x48 px
- **hdpi**: 72x72 px  
- **xhdpi**: 96x96 px
- **xxhdpi**: 144x144 px
- **xxxhdpi**: 192x192 px

The plugin will automatically copy the appropriate resolution file to each density folder.

## Requirements

- Flutter SDK: >=3.0.0
- Android: API level 21+ (Android 5.0+)
- Android Gradle Plugin: 7.0+

## Version Compatibility

This plugin is compatible with Flutter 3.0.0 and above, supporting a wide range of Flutter versions for maximum compatibility.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
