# stable_device_id_example

Demonstrates how to use the [stable_device_id](https://pub.dev/packages/stable_device_id) plugin.

The app reads the identifier with `StableDeviceId.getId()` and shows it on screen. To check that it is stable, uninstall the app, run it again, and compare the values.

## Run

```bash
flutter run
```

## Integration tests

With an emulator, simulator or device running:

```bash
flutter test integration_test/plugin_integration_test.dart
```
