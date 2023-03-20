//
//  LinkSecureCookieStore.swift
//  StripeiOS
//
//  Created by Ramon Torres on 12/21/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Security
import Foundation

/// A secure cookie store backed by Keychain.
final class LinkSecureCookieStore: LinkCookieStore {

    static let shared: LinkSecureCookieStore = .init()

    private init() {}

    func write(key: String, value: String, allowSync: Bool) {
        guard let data = value.data(using: .utf8) else {
            return
        }

        let query = queryForKey(key, additionalParams: [
            kSecValueData as String: data,
            kSecAttrSynchronizable as String: allowSync ? kCFBooleanTrue as Any : kCFBooleanFalse as Any
        ])

        delete(key: key)
        let status = SecItemAdd(query as CFDictionary, nil)
        assert(
            status == noErr || status == errSecDuplicateItem,
            "Unexpected status code \(status)"
        )

        if status == errSecDuplicateItem {
            let updateQuery = queryForKey(key)
            let updatedValue: [String: Any] = [kSecValueData as String: data]
            let status = SecItemUpdate(updateQuery as CFDictionary, updatedValue as CFDictionary)
            assert(status == noErr, "Unexpected status code \(status)")
        }
    }

    func read(key: String) -> String? {
        let query = queryForKey(key, additionalParams: [
            kSecReturnData as String: kCFBooleanTrue as Any,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny
        ])

        var result: AnyObject?

        let status = SecItemCopyMatching(query as CFDictionary, &result)
        // Disable this check for UI tests
        
        assert(
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

    func delete(key: String) {
        let query = queryForKey(key, additionalParams: [
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny
        ])

        let status = SecItemDelete(query as CFDictionary)
        assert(
            status == noErr || status == errSecItemNotFound,
            "Unexpected status code \(status)"
        )
    }

    private func queryForKey(
        _ key: String,
        additionalParams: [String: Any]? = nil
    ) -> [String: Any] {
        var query = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ] as [String : Any]

        additionalParams?.forEach({ (key, value) in
            query[key] = value
        })

        return query
    }

}
