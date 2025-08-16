import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dynamic_app_icons/dynamic_app_icons.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  const MethodChannel channel = MethodChannel('dynamic_app_icons');
  final log = <MethodCall>[];

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      log.add(methodCall);
      switch (methodCall.method) {
        case 'isSupported':
          return true;
        case 'changeIcon':
          return true;
        case 'getCurrentIcon':
          return 'test_icon';
        case 'resetToDefault':
          return true;
        default:
          return null;
      }
    });
  });

  tearDown(() {
    log.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    // Reset plugin state between tests
    DynamicAppIcons.reset();
  });

  group('DynamicAppIcons', () {
    test('isSupported returns true on Android', () async {
      final result = await DynamicAppIcons.isSupported();
      expect(result, true);
      expect(log, hasLength(1));
      expect(log.first.method, 'isSupported');
    });

    test('changeIcon calls platform method with correct arguments', () async {
      // Initialize the plugin first
      await DynamicAppIcons.initializeFromString('''
icons:
  test_icon:
    path: "test/path.png"
''', validateFiles: false);

      final result = await DynamicAppIcons.changeIcon('test_icon');
      expect(result, true);
      expect(log, hasLength(1)); // Only changeIcon call
      expect(log.last.method, 'changeIcon');
      expect(log.last.arguments, {'iconIdentifier': 'test_icon'});
    });

    test('changeIcon throws StateError when not initialized', () async {
      expect(
        () => DynamicAppIcons.changeIcon('test_icon'),
        throwsA(isA<StateError>()),
      );
    });

    test('changeIcon throws ArgumentError for invalid icon', () async {
      await DynamicAppIcons.initializeFromString('''
icons:
  valid_icon:
    path: "test/path.png"
''', validateFiles: false);

      expect(
        () => DynamicAppIcons.changeIcon('invalid_icon'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('getCurrentIcon returns current icon identifier', () async {
      final result = await DynamicAppIcons.getCurrentIcon();
      expect(result, 'test_icon');
      expect(log, hasLength(1));
      expect(log.first.method, 'getCurrentIcon');
    });

    test('resetToDefault calls platform method', () async {
      final result = await DynamicAppIcons.resetToDefault();
      expect(result, true);
      expect(log, hasLength(1));
      expect(log.first.method, 'resetToDefault');
    });

    test('availableIcons returns list of configured icons', () async {
      await DynamicAppIcons.initializeFromString('''
icons:
  icon1:
    path: "path1.png"
  icon2:
    path: "path2.png"
''', validateFiles: false);

      final icons = DynamicAppIcons.availableIcons;
      expect(icons, containsAll(['icon1', 'icon2']));
    });

    test('isValidIcon returns true for valid icons', () async {
      await DynamicAppIcons.initializeFromString('''
icons:
  valid_icon:
    path: "test/path.png"
''', validateFiles: false);

      expect(DynamicAppIcons.isValidIcon('valid_icon'), true);
      expect(DynamicAppIcons.isValidIcon('invalid_icon'), false);
    });

    test('isInitialized returns correct state', () async {
      expect(DynamicAppIcons.isInitialized, false);
      
      await DynamicAppIcons.initializeFromString('''
icons:
  test_icon:
    path: "test/path.png"
''', validateFiles: false);

      expect(DynamicAppIcons.isInitialized, true);
    });

    test('config returns configuration object', () async {
      await DynamicAppIcons.initializeFromString('''
icons:
  test_icon:
    path: "test/path.png"
    label: "Test Icon"
''', validateFiles: false);

      final config = DynamicAppIcons.config;
      expect(config, isNotNull);
      expect(config!.icons.containsKey('test_icon'), true);
      expect(config.icons['test_icon']!.label, 'Test Icon');
    });
  });
}
