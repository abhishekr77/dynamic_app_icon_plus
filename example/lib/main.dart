import 'package:flutter/material.dart';
import 'package:dynamic_app_icon_plus/dynamic_app_icon_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Automatic setup and initialization (without auto-setting default icon)
  try {
    await DynamicAppIconPlus.setup('example_config.yaml', setDefaultIcon: false);
    print('Plugin setup and initialized successfully');
  } catch (e) {
    print('Failed to setup plugin: $e');
  }
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dynamic App Icons Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Dynamic App Icons Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? currentIcon;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentIcon();
    _setDefaultIconAfterLoad();
  }

  Future<void> _loadCurrentIcon() async {
    try {
      final icon = await DynamicAppIconPlus.getCurrentIcon();
      setState(() {
        currentIcon = icon;
      });
    } catch (e) {
      print('Failed to load current icon: $e');
    }
  }

  Future<void> _setDefaultIconAfterLoad() async {
    // Set the default icon after the app is fully loaded
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await DynamicAppIconPlus.setDefaultIcon();
        print('Default icon set successfully after app load');
      } catch (e) {
        print('Failed to set default icon: $e');
      }
    });
  }

  Future<void> _changeIcon(String iconIdentifier) async {
    setState(() {
      isLoading = true;
    });

    try {
      final success = await DynamicAppIconPlus.changeIcon(iconIdentifier);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Icon changed to $iconIdentifier successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadCurrentIcon();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to change icon'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _resetToDefault() async {
    setState(() {
      isLoading = true;
    });

    try {
      final success = await DynamicAppIconPlus.resetToDefault();
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Icon reset to default successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadCurrentIcon();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reset icon'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Icon:',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SizedBox(height: 8),
                    Text(
                      currentIcon ?? 'Default',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Available Icons:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: [
                  ...DynamicAppIconPlus.availableIcons.map((iconId) {
                    final isCurrent = currentIcon == iconId;
                    return Card(
                      margin: EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(iconId),
                        subtitle: Text(isCurrent ? 'Currently Active' : 'Tap to activate'),
                        trailing: isCurrent ? Icon(Icons.check, color: Colors.green) : null,
                        onTap: isLoading ? null : () => _changeIcon(iconId),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: isLoading ? null : _resetToDefault,
              child: Text('Reset to Default'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            if (isLoading)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
