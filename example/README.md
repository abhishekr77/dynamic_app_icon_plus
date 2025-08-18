# Dynamic App Icons Example

This example demonstrates how to use the `dynamic_app_icons` plugin to change app icons dynamically.

## Quick Start

1. **Create your icon configuration** (`example_config.yaml`):
```yaml
default_icon: "default"

icons:
  default:
    path: "assets/icons/default_icon.png"
    label: "Default Icon"
  
  christmas:
    path: "assets/icons/christmas_icon.png"
    label: "Christmas Icon"
  
  halloween:
    path: "assets/icons/halloween_icon.png"
    label: "Halloween Icon"
```

2. **Run the setup command**:
```bash
dart run dynamic_app_icon_plus:dynamic_app_icon_plus example_config.yaml
```

3. **Add your icon files** to the appropriate mipmap folders:
- `android/app/src/main/res/mipmap-hdpi/ic_launcher_christmas.png`
- `android/app/src/main/res/mipmap-hdpi/ic_launcher_halloween.png`
- etc.

4. **Run the example app**:
```bash
flutter run
```

## What the Setup Does

The setup command automatically:

1. ✅ **Validates your configuration** - Checks for syntax errors and missing files
2. ✅ **Generates Android manifest** - Adds activity aliases for each icon
3. ✅ **Creates build scripts** - Generates helper scripts for future updates
4. ✅ **Generates documentation** - Creates a README with your icon setup
5. ✅ **Initializes the plugin** - Sets up everything needed for runtime

## Using the Plugin

Once set up, changing icons is simple:

```dart
// Change to Christmas icon
await DynamicAppIconPlus.changeIcon('christmas');

// Change to Halloween icon
await DynamicAppIconPlus.changeIcon('halloween');

// Reset to default
await DynamicAppIconPlus.resetToDefault();
```

## Example App Features

The example app demonstrates:

- 📱 **Icon Selection UI** - Tap to change icons
- 🔄 **Loading States** - Shows progress during icon changes
- ✅ **Success/Error Handling** - Displays feedback to users
- 📋 **Current Icon Display** - Shows which icon is currently active
- 🔄 **Reset Functionality** - Return to default icon

## Troubleshooting

If you encounter issues:

1. **Check your configuration**:
```bash
dart run dynamic_app_icons:validate example_config.yaml
```

2. **Check your configuration file** - Make sure all paths are correct
3. **Verify icon files exist** - Ensure all icon files are in the correct locations

## Next Steps

- Add more icons to your configuration
- Implement icon changes based on user preferences
- Add seasonal icon changes (Christmas, Halloween, etc.)
- Create custom icon themes for your app
