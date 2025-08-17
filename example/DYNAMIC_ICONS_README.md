## Dynamic App Icons Setup

This project uses dynamic app icons. The following icons are available:

- **default**: Default Icon
  - The default app icon
  - Icon file: `assets/images/launcher_icon.png`

- **independance**: Christmas Icon
  - Festive Christmas-themed app icon
  - Icon file: `assets/images/card2.png`

- **payme**: Halloween Icon
  - Spooky Halloween-themed app icon
  - Icon file: `assets/images/gift.png`

- **diwali**: Diwali Icon
  - Spooky Halloween-themed app icon
  - Icon file: `assets/images/gift.png`

### Usage

```dart
// Change to a specific icon
await DynamicAppIconPlus.changeIcon('default');

// Reset to default
await DynamicAppIconPlus.resetToDefault();
```
