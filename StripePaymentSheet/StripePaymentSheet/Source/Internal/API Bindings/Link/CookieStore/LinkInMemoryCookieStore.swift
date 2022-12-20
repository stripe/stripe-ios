//
//  LinkInMemoryCookieStore.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 12/21/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

/// In-memory cookie store.
final class LinkInMemoryCookieStore: LinkCookieStore {
    private var data: [LinkCookieKey: String] = [:]

    func write(key: LinkCookieKey, value: String, allowSync: Bool) {
        data[key] = value
    }

    func read(key: LinkCookieKey) -> String? {
        return data[key]
    }

    func delete(key: LinkCookieKey) {
        data.removeValue(forKey: key)
    }
}
