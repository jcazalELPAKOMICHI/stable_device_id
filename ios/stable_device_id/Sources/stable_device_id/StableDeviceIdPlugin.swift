import Flutter
import UIKit

public class StableDeviceIdPlugin: NSObject, FlutterPlugin {
  private static let channelName = "stable_device_id"
  private static let getIdMethod = "getId"
  private static let initialValueArgument = "initialValue"
  private static let keychainErrorCode = "KEYCHAIN_ERROR"

  private let store = KeychainDeviceIdStore()

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger())
    let instance = StableDeviceIdPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case StableDeviceIdPlugin.getIdMethod:
      let arguments = call.arguments as? [String: Any]
      let initialValue = arguments?[StableDeviceIdPlugin.initialValueArgument] as? String
      getId(initialValue: initialValue, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func getId(initialValue: String?, result: @escaping FlutterResult) {
    do {
      result(try store.getOrCreate(initialValue: initialValue))
    } catch KeychainDeviceIdStore.StoreError.keychain(let status) {
      result(
        FlutterError(
          code: StableDeviceIdPlugin.keychainErrorCode,
          message: "Keychain operation failed with status \(status).",
          details: Int(status)))
    } catch {
      result(
        FlutterError(
          code: StableDeviceIdPlugin.keychainErrorCode,
          message: error.localizedDescription,
          details: nil))
    }
  }
}
