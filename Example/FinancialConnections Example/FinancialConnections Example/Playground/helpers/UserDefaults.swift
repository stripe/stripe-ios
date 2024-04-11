//
//  UserDefaults.swift
//  FinancialConnections Example
//
//  Created by Krisjanis Gaidis on 4/9/24.
//

import Foundation

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
