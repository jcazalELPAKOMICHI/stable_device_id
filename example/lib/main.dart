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
  String _deviceId = 'Loading…';

  @override
  void initState() {
    super.initState();
    _loadDeviceId();
  }

  Future<void> _loadDeviceId() async {
    String deviceId;
    try {
      deviceId = await StableDeviceId.getId();
    } on PlatformException catch (e) {
      deviceId = 'Failed to get device id: ${e.code}';
    }

    if (!mounted) return;

    setState(() {
      _deviceId = deviceId;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('stable_device_id example')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SelectableText(
              'Device id: $_deviceId',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
