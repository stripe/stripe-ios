//
//  LinkSecureCookieStore.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 12/21/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
import Security
@_spi(STP) import StripeCore

/// A secure cookie store backed by Keychain.
final class LinkSecureCookieStore: LinkCookieStore {

    static let shared: LinkSecureCookieStore = .init()

    private init() {}

    func write(key: LinkCookieKey, value: String, allowSync: Bool) {
        guard let data = value.data(using: .utf8) else {
            return
        }

        let query = queryForKey(key, additionalParams: [
            kSecValueData as String: data,
            kSecAttrSynchronizable as String: allowSync ? kCFBooleanTrue as Any : kCFBooleanFalse as Any,
        ])

        delete(key: key)
        let status = SecItemAdd(query as CFDictionary, nil)
        stpAssert(
            status == noErr || status == errSecDuplicateItem,
            "Unexpected status code \(status)"
        )

        if status == errSecDuplicateItem {
            let updateQuery = queryForKey(key)
            let updatedValue: [String: Any] = [kSecValueData as String: data]
            let status = SecItemUpdate(updateQuery as CFDictionary, updatedValue as CFDictionary)
            stpAssert(status == noErr, "Unexpected status code \(status)")
        }
    }

    func read(key: LinkCookieKey) -> String? {
        let query = queryForKey(key, additionalParams: [
            kSecReturnData as String: kCFBooleanTrue as Any,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny,
        ])

        var result: AnyObject?

        let status = SecItemCopyMatching(query as CFDictionary, &result)
        // Disable this check for UI tests

        stpAssert(
            status == noErr || status == errSecItemNotFound,
            "Unexpected status code \(status)"
        )

        guard
            status == noErr,
            let data = result as? Data
        else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    func delete(key: LinkCookieKey) {
        let query = queryForKey(key, additionalParams: [
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny
        ])

        let status = SecItemDelete(query as CFDictionary)
        stpAssert(
            status == noErr || status == errSecItemNotFound,
            "Unexpected status code \(status)"
        )
    }

    private func queryForKey(
        _ key: LinkCookieKey,
        additionalParams: [String: Any]? = nil
    ) -> [String: Any] {
        // This must be unique across apps OR the apps must share
        // a keychain access group. To be safe, we'll partition it
        // by bundle ID.
        let accountId = "STP-\(Bundle.main.bundleIdentifier ?? "")-\(key.rawValue)"
        var query = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: accountId,
        ] as [String: Any]

        additionalParams?.forEach({ (key, value) in
            query[key] = value
        })

        return query
    }

}
