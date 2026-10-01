import Foundation
import Security
import UIKit

/// Persists the device identifier in the Keychain so it survives app reinstalls.
///
/// Uses `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`: the item is readable
/// in background after the first unlock, is never synced to iCloud Keychain and
/// is not migrated to another device through a backup.
final class KeychainDeviceIdStore {
  enum StoreError: Error {
    case keychain(OSStatus)
  }

  private static let serviceSuffix = ".stable_device_id"
  private static let account = "device_id"
  private static let fallbackService = "stable_device_id"

  private let service: String

  init(bundleIdentifier: String? = Bundle.main.bundleIdentifier) {
    service = bundleIdentifier.map { $0 + KeychainDeviceIdStore.serviceSuffix }
      ?? KeychainDeviceIdStore.fallbackService
  }

  func getOrCreate(initialValue: String?) throws -> String {
    if let stored = try read() {
      return stored
    }

    let newId = Self.nonEmpty(initialValue)
      ?? UIDevice.current.identifierForVendor?.uuidString
      ?? UUID().uuidString
    try save(newId)
    return newId
  }

  private var baseQuery: [String: Any] {
    [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: KeychainDeviceIdStore.account,
    ]
  }

  private func read() throws -> String? {
    var query = baseQuery
    query[kSecReturnData as String] = true
    query[kSecMatchLimit as String] = kSecMatchLimitOne

    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)

    switch status {
    case errSecSuccess:
      guard let data = item as? Data else { return nil }
      return Self.nonEmpty(String(data: data, encoding: .utf8))
    case errSecItemNotFound:
      return nil
    default:
      throw StoreError.keychain(status)
    }
  }

  private func save(_ value: String) throws {
    var query = baseQuery
    query[kSecValueData as String] = Data(value.utf8)
    query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

    let status = SecItemAdd(query as CFDictionary, nil)
    guard status == errSecSuccess else {
      throw StoreError.keychain(status)
    }
  }

  private static func nonEmpty(_ value: String?) -> String? {
    guard let value = value, !value.isEmpty else { return nil }
    return value
  }
}
