## Dynamic App Icons Setup

This project uses dynamic app icons. The following icons are available:

- **default**: Default Icon
  - The default app icon
  - Icon file: `assets/icons/default_icon.png`

- **christmas**: Christmas Icon
  - Festive Christmas-themed app icon
  - Icon file: `assets/icons/christmas_icon.png`

- **halloween**: Halloween Icon
  - Spooky Halloween-themed app icon
  - Icon file: `assets/icons/halloween_icon.png`

- **new_year**: new_year
  - Icon file: `assets/icons/new_year_icon.png`

### Usage

```dart
// Change to a specific icon
await DynamicAppIconPlus.changeIcon('default');

// Reset to default
await DynamicAppIconPlus.resetToDefault();
```
