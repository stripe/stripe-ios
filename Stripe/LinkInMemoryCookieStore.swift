//
//  LinkInMemoryCookieStore.swift
//  StripeiOS
//
//  Created by Ramon Torres on 12/21/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

/// In-memory cookie store.
final class LinkInMemoryCookieStore: LinkCookieStore {
    private var data: [String: String] = [:]

    func write(key: String, value: String, allowSync: Bool = false) {
        data[key] = value
    }

    func read(key: String) -> String? {
        return data[key]
    }

    func delete(key: String, value: String?) {
        let shouldDelete = value == nil || read(key: key) == value

        if shouldDelete {
            data.removeValue(forKey: key)
        }
    }
}
