# Dynamic App Icons

A Flutter plugin that allows you to dynamically change your app's icon on Android at runtime.

## Features

- 🎨 Change app icons dynamically without app store updates
- 📝 Simple YAML configuration for icon definitions
- 🔧 Easy-to-use API
- ✅ Validation and error handling
- 📱 Android support (iOS support coming soon)

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  dynamic_app_icons: ^0.0.1
```

### Requirements

- **Flutter**: >= 3.0.0
- **Dart**: >= 3.0.0
- **Android**: API level 21+ (Android 5.0+)

## Command-Line Tool

The plugin includes a command-line tool for easy setup:

```bash
# Set up dynamic app icons with default config file
dart run dynamic_app_icons:setup

# Set up with custom config file
dart run dynamic_app_icons:setup my_icons.yaml
```

The command-line tool will:
- ✅ Validate your configuration
- ✅ Generate Android manifest modifications
- ✅ Create build scripts
- ✅ Generate documentation
- ✅ Check for missing icon files

## Setup

### 1. Create Icon Configuration

Create a YAML file (e.g., `icon_config.yaml`) in your project root:

```yaml
# Default icon identifier (optional)
default_icon: "default"

# Icon definitions
icons:
  default:
    path: "assets/icons/default_icon.png"
    label: "Default Icon"
    description: "The default app icon"
  
  christmas:
    path: "assets/icons/christmas_icon.png"
    sizes:
      hdpi: "assets/icons/christmas_icon_hdpi.png"
      xhdpi: "assets/icons/christmas_icon_xhdpi.png"
      xxhdpi: "assets/icons/christmas_icon_xxhdpi.png"
    label: "Christmas Icon"
    description: "Festive Christmas-themed app icon"
  
  halloween:
    path: "assets/icons/halloween_icon.png"
    label: "Halloween Icon"
    description: "Spooky Halloween-themed app icon"
```

### 2. Automatic Setup (Recommended)

Run the setup command to automatically configure your project:

```bash
# Using the command-line tool
dart run dynamic_app_icons:setup icon_config.yaml

# Or using the Dart API
await DynamicAppIcons.setup('icon_config.yaml');
```

This will automatically:
- ✅ Generate Android manifest modifications
- ✅ Create activity aliases for each icon
- ✅ Generate build scripts and documentation
- ✅ Validate your configuration
- ✅ Set up everything needed for dynamic icons

### 3. Manual Setup (Alternative)

If you prefer manual setup, you'll need to:

#### Add Activity Aliases to AndroidManifest.xml

For each custom icon, add an activity alias in your `android/app/src/main/AndroidManifest.xml`:

```xml
<application
    android:label="your_app_name"
    android:name="${applicationName}"
    android:icon="@mipmap/ic_launcher">
    
    <!-- Main activity -->
    <activity
        android:name=".MainActivity"
        android:exported="true"
        android:launchMode="singleTop"
        android:theme="@style/LaunchTheme"
        android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
        android:hardwareAccelerated="true"
        android:windowSoftInputMode="adjustResize">
        <meta-data
            android:name="io.flutter.embedding.android.NormalTheme"
            android:resource="@style/NormalTheme" />
        <intent-filter android:autoVerify="true">
            <action android:name="android.intent.action.MAIN"/>
            <category android:name="android.intent.category.LAUNCHER"/>
        </intent-filter>
    </activity>
    
    <!-- Activity aliases for custom icons -->
    <activity-alias
        android:name=".christmasActivity"
        android:enabled="false"
        android:icon="@mipmap/ic_launcher_christmas"
        android:targetActivity=".MainActivity">
        <intent-filter>
            <action android:name="android.intent.action.MAIN" />
            <category android:name="android.intent.category.LAUNCHER" />
        </intent-filter>
    </activity-alias>
    
    <activity-alias
        android:name=".halloweenActivity"
        android:enabled="false"
        android:icon="@mipmap/ic_launcher_halloween"
        android:targetActivity=".MainActivity">
        <intent-filter>
            <action android:name="android.intent.action.MAIN" />
            <category android:name="android.intent.category.LAUNCHER" />
        </intent-filter>
    </activity-alias>
    
    <meta-data
        android:name="flutterEmbedding"
        android:value="2" />
</application>
```

#### Add Icon Resources

Place your icon files in the appropriate `mipmap` folders:
- `android/app/src/main/res/mipmap-hdpi/`
- `android/app/src/main/res/mipmap-mdpi/`
- `android/app/src/main/res/mipmap-xhdpi/`
- `android/app/src/main/res/mipmap-xxhdpi/`
- `android/app/src/main/res/mipmap-xxxhdpi/`

## Usage

### 1. Quick Setup (Recommended)

```dart
import 'package:dynamic_app_icons/dynamic_app_icons.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Automatic setup and initialization
  await DynamicAppIcons.setup('icon_config.yaml');
  
  runApp(MyApp());
}
```

### 2. Manual Initialization

```dart
import 'package:dynamic_app_icons/dynamic_app_icons.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize with configuration file
  await DynamicAppIcons.initialize('icon_config.yaml');
  
  runApp(MyApp());
}
```

### 2. Change App Icon

```dart
// Change to Christmas icon
try {
  bool success = await DynamicAppIcons.changeIcon('christmas');
  if (success) {
    print('Icon changed successfully!');
  }
} catch (e) {
  print('Failed to change icon: $e');
}
```

### 3. Reset to Default

```dart
// Reset to default icon
try {
  bool success = await DynamicAppIcons.resetToDefault();
  if (success) {
    print('Icon reset successfully!');
  }
} catch (e) {
  print('Failed to reset icon: $e');
}
```

### 4. Check Available Icons

```dart
// Get all available icon identifiers
List<String> availableIcons = DynamicAppIcons.availableIcons;
print('Available icons: $availableIcons');

// Check if an icon is valid
bool isValid = DynamicAppIcons.isValidIcon('christmas');
print('Christmas icon is valid: $isValid');
```

### 5. Get Current Icon

```dart
// Get the currently active icon identifier
String? currentIcon = await DynamicAppIcons.getCurrentIcon();
print('Current icon: $currentIcon');
```

## API Reference

### Methods

#### `setup(String configPath)`
Automatically sets up the project and initializes the plugin. This is the recommended way to get started.

#### `initialize(String configPath)`
Initializes the plugin with a configuration file.

#### `initializeFromString(String configString)`
Initializes the plugin with a YAML configuration string.

#### `changeIcon(String iconIdentifier)`
Changes the app icon to the specified identifier.

#### `resetToDefault()`
Resets the app icon to the default icon.

#### `getCurrentIcon()`
Gets the currently active icon identifier.

#### `isSupported()`
Checks if the current platform supports dynamic app icons.

#### `validateSetup(String configPath)`
Validates the current setup and returns any errors.

#### `backupAndroidManifest()`
Creates a backup of the Android manifest before making changes.

#### `restoreAndroidManifest()`
Restores the Android manifest from backup.

### Properties

#### `isInitialized`
Returns `true` if the plugin has been initialized.

#### `config`
Returns the current configuration object.

#### `availableIcons`
Returns a list of all available icon identifiers.

## Configuration Format

The YAML configuration supports two formats for icon definitions:

### Simple Format
```yaml
icons:
  my_icon: "assets/icons/my_icon.png"
```

### Advanced Format
```yaml
icons:
  my_icon:
    path: "assets/icons/my_icon.png"
    sizes:
      hdpi: "assets/icons/my_icon_hdpi.png"
      xhdpi: "assets/icons/my_icon_xhdpi.png"
    label: "My Icon"
    description: "Description of my icon"
```

## Error Handling

The plugin provides comprehensive error handling:

```dart
try {
  await DynamicAppIcons.changeIcon('invalid_icon');
} on ArgumentError catch (e) {
  print('Invalid icon identifier: $e');
} on StateError catch (e) {
  print('Plugin not initialized: $e');
} on PlatformException catch (e) {
  print('Platform error: ${e.message}');
}
```

## Version Compatibility

| Flutter Version | Plugin Version | Status |
|----------------|----------------|--------|
| 3.0.0 - 3.9.x  | ^0.0.1         | ✅ Supported |
| 3.10.0 - 3.24.x| ^0.0.1         | ✅ Supported |
| 4.0.0+         | ^0.0.1         | ✅ Supported |

## Limitations

- Currently only supports Android
- Requires app restart to apply icon changes
- Each custom icon requires an activity alias in AndroidManifest.xml
- Icon files must be properly placed in mipmap folders

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
