## Dynamic App Icons Setup

This project uses dynamic app icons. The following icons are available:

- **levelup**: Level Up
  - The default app icon
  - Icon file: `assets/images/levelup.png`

- **christmas**: Christmas Icon
  - Festive Christmas-themed app icon
  - Icon file: `assets/images/christmas.png`

- **halloween**: Halloween Icon
  - Spooky Halloween-themed app icon
  - Icon file: `assets/images/halloween.png`

- **diwali**: diwali
  - Icon file: `assets/images/diwali.png`

### Usage

```dart
// Change to a specific icon
await DynamicAppIconPlus.changeIcon('levelup');

// Reset to default
await DynamicAppIconPlus.resetToDefault();
```
