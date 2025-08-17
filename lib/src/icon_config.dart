import 'dart:io';
import 'package:yaml/yaml.dart';

/// Configuration for dynamic app icons
class IconConfig {
  final Map<String, IconDefinition> icons;
  final String? defaultIcon;

  IconConfig({
    required this.icons,
    this.defaultIcon,
  });

  /// Creates an IconConfig from a YAML file
  factory IconConfig.fromYamlFile(String filePath) {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw FileSystemException('Configuration file not found', filePath);
    }

    final yamlString = file.readAsStringSync();
    return IconConfig.fromYamlString(yamlString);
  }

  /// Creates an IconConfig from a YAML string
  factory IconConfig.fromYamlString(String yamlString) {
    final yaml = loadYaml(yamlString);
    
    if (yaml is! Map) {
      throw FormatException('Invalid YAML format: expected a map');
    }

    final Map<String, IconDefinition> icons = {};
    String? defaultIcon;

    // Parse icons
    if (yaml.containsKey('icons') && yaml['icons'] is Map) {
      final iconsMap = yaml['icons'] as Map;
      
      for (final entry in iconsMap.entries) {
        final identifier = entry.key.toString();
        final iconData = entry.value;
        
        if (iconData is Map) {
          icons[identifier] = IconDefinition.fromMap(identifier, iconData);
        } else if (iconData is String) {
          // Simple format: just a path
          icons[identifier] = IconDefinition(
            identifier: identifier,
            path: iconData,
          );
        }
      }
    }

    // Parse default icon
    if (yaml.containsKey('default_icon')) {
      defaultIcon = yaml['default_icon'].toString();
    }

    return IconConfig(
      icons: icons,
      defaultIcon: defaultIcon,
    );
  }

  /// Gets an icon definition by identifier
  IconDefinition? getIcon(String identifier) {
    return icons[identifier];
  }

  /// Checks if an icon with the given identifier exists
  bool hasIcon(String identifier) {
    return icons.containsKey(identifier);
  }

  /// Gets all available icon identifiers
  List<String> get availableIcons => icons.keys.toList();

  /// Validates the configuration and returns any errors.
  /// 
  /// Returns a list of error messages, or an empty list if everything is valid.
  List<String> validate({bool checkFiles = true}) {
    final errors = <String>[];
    
    // Validate that default_icon is specified
    if (defaultIcon == null) {
      errors.add('default_icon is required in YAML configuration');
    } else {
      // Validate that default_icon references an existing icon
      if (!icons.containsKey(defaultIcon)) {
        errors.add('default_icon "$defaultIcon" references a non-existent icon. Available icons: ${icons.keys.join(', ')}');
      }
    }
    
    // Validate each icon
    for (final icon in icons.values) {
      errors.addAll(icon.validate(checkFiles: checkFiles));
    }
    
    return errors;
  }
}

/// Definition of a single app icon
class IconDefinition {
  final String identifier;
  final String path;
  final Map<String, String>? sizes;
  final String? label;
  final String? description;

  IconDefinition({
    required this.identifier,
    required this.path,
    this.sizes,
    this.label,
    this.description,
  });

  /// Creates an IconDefinition from a map (parsed from YAML)
  factory IconDefinition.fromMap(String identifier, Map map) {
    if (!map.containsKey('path')) {
      throw FormatException('Icon "$identifier" is missing required "path" field');
    }

    return IconDefinition(
      identifier: identifier,
      path: map['path'].toString(),
      sizes: map.containsKey('sizes') && map['sizes'] is Map
          ? Map<String, String>.from(map['sizes'])
          : null,
      label: map['label']?.toString(),
      description: map['description']?.toString(),
    );
  }

  /// Validates the icon definition
  List<String> validate({bool checkFiles = true}) {
    final errors = <String>[];
    
    if (identifier.isEmpty) {
      errors.add('Identifier cannot be empty');
    }

    if (path.isEmpty) {
      errors.add('Path cannot be empty');
    }

    // Check if the icon file exists (optional for testing)
    // Skip file existence check for asset paths as they're handled differently
    if (checkFiles && !path.startsWith('assets/')) {
      final file = File(path);
      if (!file.existsSync()) {
        errors.add('Icon file not found: $path');
      }
    }

    return errors;
  }

  /// Gets the icon path for a specific size (if sizes are defined)
  String getIconPath([String? size]) {
    if (size != null && sizes != null && sizes!.containsKey(size)) {
      return sizes![size]!;
    }
    return path;
  }

  @override
  String toString() {
    return 'IconDefinition(identifier: $identifier, path: $path)';
  }
}
