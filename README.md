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
- Update your Android manifest
- Generate build scripts
- Create documentation

### 3. Add Icon Files

Add your icon files to the appropriate mipmap folders:
- `android/app/src/main/res/mipmap-hdpi/`
- `android/app/src/main/res/mipmap-mdpi/`
- `android/app/src/main/res/mipmap-xhdpi/`
- `android/app/src/main/res/mipmap-xxhdpi/`
- `android/app/src/main/res/mipmap-xxxhdpi/`

### 4. Use in Your App

```dart
import 'package:dynamic_app_icon_plus/dynamic_app_icon_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize the plugin
  await DynamicAppIconPlus.initialize('icon_config.yaml');
  
  runApp(MyApp());
}

// Change icon
await DynamicAppIconPlus.changeIcon('christmas');

// Reset to default
await DynamicAppIconPlus.resetToDefault();

// Get current icon
String currentIcon = await DynamicAppIconPlus.getCurrentIcon();
```

## That's It! 🎉

No manual registration, no complex setup - just add the dependency, create a config file, run the setup tool, and you're ready to go!

## API Reference

### Methods

#### `initialize(String configPath)`
Initializes the plugin with a configuration file.

#### `changeIcon(String iconIdentifier)`
Changes the app icon to the specified identifier.

#### `resetToDefault()`
Resets the app icon to the default icon.

#### `getCurrentIcon()`
Gets the currently active icon identifier.

#### `isSupported()`
Checks if the current platform supports dynamic app icons.

### Properties

#### `availableIcons`
Gets a list of all available icon identifiers.

#### `isInitialized`
Checks if the plugin has been initialized.

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
      hdpi: "assets/icons/christmas_hdpi.png"
      xhdpi: "assets/icons/christmas_xhdpi.png"
    label: "Christmas Icon"
    description: "Festive Christmas-themed app icon"
```

## Requirements

- Flutter SDK: >=3.0.0
- Android: API level 21+ (Android 5.0+)
- Android Gradle Plugin: 7.0+

## Version Compatibility

This plugin is compatible with Flutter 3.0.0 and above, supporting a wide range of Flutter versions for maximum compatibility.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
