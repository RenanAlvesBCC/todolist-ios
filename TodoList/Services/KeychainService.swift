//
//  KeychainService.swift
//  TodoList
//
//  Created by Renan Alves on 23/06/26.
//

import Foundation
import Security

enum KeychainError: Error, Equatable {
    case saveFailed(OSStatus)
    case notFound
}

final class KeychainService: KeychainServiceProtocol {
    private let service = "com.renanalvesbcc.oficina.mecanico"
    private let tokenKey = "auth_token"

    private var lookupQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: tokenKey
        ]
    }

    func save(token: String) throws {
        deleteToken()

        let data = Data(token.utf8)
        var addQuery = lookupQuery
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    func loadToken() throws -> String {
        var query = lookupQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            throw KeychainError.notFound
        }
        return token
    }

    func deleteToken() {
        SecItemDelete(lookupQuery as CFDictionary)
    }
}
