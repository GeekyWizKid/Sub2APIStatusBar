import Foundation
import Security

public enum KeychainTokenStoreError: Error, LocalizedError, Equatable, Sendable {
    case unexpectedStatus(OSStatus)

    public var errorDescription: String? {
        switch self {
        case let .unexpectedStatus(status):
            "Keychain operation failed with status \(status)."
        }
    }
}

public final class KeychainTokenStore: TokenStore, Sendable {
    private let service: String

    public init(service: String = "com.geekywizkid.sub2api-statusbar") {
        self.service = service
    }

    public func loadTokens() -> StoredAuthTokens {
        StoredAuthTokens(
            authToken: read(account: "authToken") ?? "",
            refreshToken: read(account: "refreshToken") ?? ""
        )
    }

    public func saveTokens(_ tokens: StoredAuthTokens) throws {
        try save(tokens.authToken, account: "authToken")
        try save(tokens.refreshToken, account: "refreshToken")
    }

    private func read(account: String) -> String? {
        var query = baseQuery(account: account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        return value
    }

    private func save(_ value: String, account: String) throws {
        if value.isEmpty {
            let status = SecItemDelete(baseQuery(account: account) as CFDictionary)
            guard status == errSecSuccess || status == errSecItemNotFound else {
                throw KeychainTokenStoreError.unexpectedStatus(status)
            }
            return
        }

        let data = Data(value.utf8)
        let updateStatus = SecItemUpdate(
            baseQuery(account: account) as CFDictionary,
            [kSecValueData as String: data] as CFDictionary
        )

        if updateStatus == errSecSuccess {
            return
        }

        guard updateStatus == errSecItemNotFound else {
            throw KeychainTokenStoreError.unexpectedStatus(updateStatus)
        }

        var addQuery = baseQuery(account: account)
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw KeychainTokenStoreError.unexpectedStatus(addStatus)
        }
    }

    private func baseQuery(account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }
}
