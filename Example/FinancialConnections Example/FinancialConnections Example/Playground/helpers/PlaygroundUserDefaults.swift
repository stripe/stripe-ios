//
//  PlaygroundUserDefaults.swift
//  FinancialConnections Example
//
//  Created by Krisjanis Gaidis on 11/5/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

final class PlaygroundUserDefaults {

    @UserDefault(
        key: "FINANCIAL_CONNECTIONS_EXAMPLE_APP_ENABLE_NATIVE",
        defaultValue: nil
    )
    static var enableNative: Bool?

    @UserDefault(
        key: "FINANCIAL_CONNECTIONS_EXAMPLE_APP_SHOW_LIVE_EVENTS",
        defaultValue: false
    )
    static var showLiveEvents: Bool
}

@propertyWrapper
struct UserDefault<Value> {
    let key: String
    let defaultValue: Value
    var userDefaults: UserDefaults = .standard

    var wrappedValue: Value {
        get {
            return userDefaults.object(forKey: key) as? Value ?? defaultValue
        }
        set {
            if let optionalWrappedValue = newValue as? OptionalValue,
                optionalWrappedValue.isNil
            {
                userDefaults.removeObject(forKey: key)
            } else {
                userDefaults.set(newValue, forKey: key)
            }
        }
    }
}

private protocol OptionalValue {
    var isNil: Bool { get }
}

extension Optional: OptionalValue {
    var isNil: Bool {
        return self == nil
    }
}
