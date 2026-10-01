import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stable_device_id/stable_device_id.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _defaultId = 'Loading…';
  String _widevineId = 'Loading…';

  @override
  void initState() {
    super.initState();
    _loadIds();
  }

  Future<String> _read(AndroidIdSource source) async {
    try {
      return await StableDeviceId.getId(androidSource: source);
    } on PlatformException catch (e) {
      return 'Unavailable (${e.code})';
    }
  }

  Future<void> _loadIds() async {
    final defaultId = await _read(AndroidIdSource.androidId);
    final widevineId = await _read(AndroidIdSource.widevine);

    if (!mounted) return;

    setState(() {
      _defaultId = defaultId;
      _widevineId = widevineId;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('stable_device_id example')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Default (ANDROID_ID / Keychain)'),
              SelectableText('Device id: $_defaultId'),
              const SizedBox(height: 24),
              const Text('Android: Widevine'),
              SelectableText('Widevine id: $_widevineId'),
            ],
          ),
        ),
      ),
    );
  }
}
