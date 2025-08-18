# Dynamic App Icon Plus

A Flutter plugin for dynamically changing app icons on Android at runtime with simple YAML configuration. **Android only.**

## Demo
https://github.com/user-attachments/assets/3def5056-ce75-4d24-89c7-809ffa584d14

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
```

## Quick Start

### 1. Add the dependency
```yaml
dependencies:
  dynamic_app_icon_plus:
```

Then run:
```bash
flutter pub get
```

### 2. Create a configuration file
Create `icon_config.yaml` in your project root:

**⚠️ Important: All icon files must be in PNG format for Android compatibility**

```yaml
# The default_icon must reference an icon defined in the icons section below
# You can use any icon name as the default_icon
default_icon: "independance"

icons:
  # Icon names are completely dynamic - you can use any names you want
  default:
    path: "assets/images/launcher_icon.png"
    label: "Default Icon"
    description: "The default app icon"
  independance:
    path: "assets/images/card2.png"
    label: "Independence Icon"
    description: "Festive independence-themed app icon"
  # You can add as many icons as you want with any names
  christmas:
    path: "assets/images/christmas.png"
    label: "Christmas Icon"
  halloween:
    path: "assets/images/halloween.png"
    label: "Halloween Icon"
```

### 3. Run the setup tool
```bash
dart run dynamic_app_icon_plus:dynamic_app_icon_plus icon_config.yaml
```

### 4. Initialize in your app
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

// Set default icon after app is fully loaded (optional)
await DynamicAppIconPlus.setDefaultIcon();

// Get icon paths for UI display
List<String> iconPaths = DynamicAppIconPlus.availableIconPaths;

// Get detailed icon information for rich UI
List<Map<String, String>> iconDetails = DynamicAppIconPlus.availableIconDetails;
```

## Development Workflow

### During Development:
1. **Test icon changes** by calling `changeIcon()`
2. **Restart the app** to see the icon change
3. **If you encounter issues** (like app not launching), call `resetForDevelopment()` to reset all activities

### For Production:
1. **Remove the `resetForDevelopment()` call** from your production code
2. **Icon changes will work normally** with proper activity switching

## Demo

https://user-images.githubusercontent.com/abhishekr77/dynamic_app_icon_plus/main/assets/demo.mp4

## That's It! 🎉

No manual registration, no complex setup - just add the dependency, create a config file, run the setup tool, and you're ready to go!

## UI Examples

### Simple Icon List with ListView.builder
```dart
ListView.builder(
  itemCount: DynamicAppIconPlus.availableIcons.length,
  itemBuilder: (context, index) {
    final iconIdentifier = DynamicAppIconPlus.availableIcons[index];
    final iconPath = DynamicAppIconPlus.availableIconPaths[index];
    
    return ListTile(
      leading: Image.asset(iconPath, width: 48, height: 48),
      title: Text(iconIdentifier),
      onTap: () => DynamicAppIconPlus.changeIcon(iconIdentifier),
    );
  },
)
```

### Rich Icon Selection UI
```dart
ListView.builder(
  itemCount: DynamicAppIconPlus.availableIconDetails.length,
  itemBuilder: (context, index) {
    final icon = DynamicAppIconPlus.availableIconDetails[index];
    
    return Card(
      child: ListTile(
        leading: Image.asset(icon['path']!, width: 48, height: 48),
        title: Text(icon['label']!),
        subtitle: Text(icon['description']!),
        trailing: IconButton(
          icon: Icon(Icons.check_circle),
          onPressed: () => DynamicAppIconPlus.changeIcon(icon['identifier']!),
        ),
      ),
    );
  },
)
```

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

#### `setDefaultIcon()`
Sets the default icon after the app is fully loaded.
- Call this method after the app has fully initialized to avoid crashes
- This will set the icon specified in the `default_icon` field of your YAML configuration

### Properties

#### `availableIcons`
Gets a list of all available icon identifiers from the configuration.

#### `availableIconPaths`
Gets a list of all available icon paths for UI display.

#### `availableIconDetails`
Gets detailed icon information for UI display (identifier, path, label, description).

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

### Key Points:
- **`default_icon`** is mandatory and must reference an icon defined in the `icons` section
- **Icon names are completely dynamic** - you can use any names you want
- **`default_icon` acts as a fallback** - if an invalid icon is passed, it falls back to the `default_icon`

### Simple Format
```yaml
# You can use any icon name as default_icon
default_icon: "my_favorite_icon"

icons:
  my_favorite_icon: "assets/icons/favorite.png"
  christmas: "assets/icons/christmas.png"
  halloween: "assets/icons/halloween.png"
  # Add as many icons as you want with any names
  custom_icon_1: "assets/icons/custom1.png"
  custom_icon_2: "assets/icons/custom2.png"
```

### Advanced Format
```yaml
# You can use any icon name as default_icon
default_icon: "my_favorite_icon"

icons:
  my_favorite_icon:
    path: "assets/icons/favorite.png"
    label: "My Favorite Icon"
    description: "This is my favorite app icon"
  christmas:
    path: "assets/icons/christmas.png"
    label: "Christmas Icon"
    description: "Festive Christmas-themed app icon"
    sizes:
      xxhdpi: "assets/icons/christmas_xxhdpi.png"
  halloween:
    path: "assets/icons/halloween.png"
    label: "Halloween Icon"
    description: "Spooky Halloween-themed app icon"
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
- **Icon Format: PNG only** - Android app icons must be in PNG format for proper compilation

## Version Compatibility

This plugin is compatible with Flutter 3.0.0 and above, supporting a wide range of Flutter versions for maximum compatibility.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
