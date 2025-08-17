import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dynamic_app_icon_plus/dynamic_app_icon_plus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  const MethodChannel channel = MethodChannel('dynamic_app_icon_plus');
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
    DynamicAppIconPlus.reset();
  });

  group('DynamicAppIconPlus', () {
    test('isSupported returns true on Android', () async {
      final result = await DynamicAppIconPlus.isSupported();
      expect(result, true);
      expect(log, hasLength(1));
      expect(log.first.method, 'isSupported');
    });

    test('changeIcon calls platform method with correct arguments', () async {
      // Initialize the plugin first
      await DynamicAppIconPlus.initializeFromString('''
icons:
  test_icon:
    path: "test/path.png"
''', validateFiles: false);

      final result = await DynamicAppIconPlus.changeIcon('test_icon');
      expect(result, true);
      expect(log, hasLength(1)); // Only changeIcon call
      expect(log.last.method, 'changeIcon');
      expect(log.last.arguments, {'iconIdentifier': 'test_icon'});
    });

    test('changeIcon throws StateError when not initialized', () async {
      expect(
        () => DynamicAppIconPlus.changeIcon('test_icon'),
        throwsA(isA<StateError>()),
      );
    });

    test('changeIcon defaults to default icon for invalid icon', () async {
      await DynamicAppIconPlus.initializeFromString('''
icons:
  valid_icon:
    path: "test/path.png"
''', validateFiles: false);

      final result = await DynamicAppIconPlus.changeIcon('invalid_icon');
      expect(result, true);
      expect(log, hasLength(1));
      expect(log.last.method, 'changeIcon');
      expect(log.last.arguments, {'iconIdentifier': 'default'});
    });

    test('getCurrentIcon returns current icon identifier', () async {
      final result = await DynamicAppIconPlus.getCurrentIcon();
      expect(result, 'test_icon');
      expect(log, hasLength(1));
      expect(log.first.method, 'getCurrentIcon');
    });

    test('resetToDefault calls platform method', () async {
      final result = await DynamicAppIconPlus.resetToDefault();
      expect(result, true);
      expect(log, hasLength(1));
      expect(log.first.method, 'resetToDefault');
    });

    test('availableIcons returns list of configured icons', () async {
      await DynamicAppIconPlus.initializeFromString('''
icons:
  icon1:
    path: "path1.png"
  icon2:
    path: "path2.png"
''', validateFiles: false);

      final icons = DynamicAppIconPlus.availableIcons;
      expect(icons, containsAll(['icon1', 'icon2']));
    });

    test('isValidIcon returns true for valid icons', () async {
      await DynamicAppIconPlus.initializeFromString('''
icons:
  valid_icon:
    path: "test/path.png"
''', validateFiles: false);

      expect(DynamicAppIconPlus.isValidIcon('valid_icon'), true);
      expect(DynamicAppIconPlus.isValidIcon('invalid_icon'), false);
    });

    test('isInitialized returns correct state', () async {
      expect(DynamicAppIconPlus.isInitialized, false);
      
      await DynamicAppIconPlus.initializeFromString('''
icons:
  test_icon:
    path: "test/path.png"
''', validateFiles: false);

      expect(DynamicAppIconPlus.isInitialized, true);
    });

    test('config returns configuration object', () async {
      await DynamicAppIconPlus.initializeFromString('''
icons:
  test_icon:
    path: "test/path.png"
    label: "Test Icon"
''', validateFiles: false);

      final config = DynamicAppIconPlus.config;
      expect(config, isNotNull);
      expect(config!.icons.containsKey('test_icon'), true);
      expect(config.icons['test_icon']!.label, 'Test Icon');
    });

    test('isSetup returns false when not set up', () async {
      final isSetup = await DynamicAppIconPlus.isSetup();
      expect(isSetup, false);
    });

    test('getConfiguredIcons returns empty list when not set up', () async {
      final icons = await DynamicAppIconPlus.getConfiguredIcons();
      expect(icons, isEmpty);
    });

    test('uninstall returns true when not initialized', () async {
      final result = await DynamicAppIconPlus.uninstall();
      expect(result, true);
    });

    test('uninstall works when initialized', () async {
      await DynamicAppIconPlus.initializeFromString('''
icons:
  test_icon:
    path: "test/path.png"
''', validateFiles: false);

      expect(DynamicAppIconPlus.isInitialized, true);
      
      final result = await DynamicAppIconPlus.uninstall();
      expect(result, true);
      expect(DynamicAppIconPlus.isInitialized, false);
    });
  });
}
