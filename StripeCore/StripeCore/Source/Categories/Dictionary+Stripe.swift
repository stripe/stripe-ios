//
//  Dictionary+Stripe.swift
//  StripeCore
//
//  Created by David Estes on 10/18/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

extension Dictionary {
    static func stp_deepMerge(old: Any, new: Any) throws -> Any {
        if let oldDictionary = old as? [String: Any],
            let newDictionary = new as? [String: Any]
        {
            return try oldDictionary.merging(newDictionary, uniquingKeysWith: stp_deepMerge)
        }
        return new
    }

    /// Return the dictionary, minus any fields that also exist in
    /// the passed dictionary.
    func subtracting(_ subtractDict: Dictionary) -> Dictionary {
        var newDict = self
        for (key, value) in self {
            if let equatableValue = value as? AnyHashable,
                let equatableSubtractValue = subtractDict[key] as? AnyHashable
            {
                if equatableValue == equatableSubtractValue {
                    newDict.removeValue(forKey: key)
                    continue
                }
            }
            if let dict1 = value as? Dictionary,
                let dict2 = subtractDict[key] as? Dictionary
            {
                let subtractedDict = dict1.subtracting(dict2)
                if subtractedDict.isEmpty {
                    newDict.removeValue(forKey: key)
                } else {
                    newDict[key] = subtractedDict as? Value
                }
            }
        }
        return newDict
    }

    @_spi(STP) public mutating func mergeAssertingOnOverwrites(_ other: [Key: Value]) {
        merge(other) { a, b in
            stpAssertionFailure("Dictionary merge is overwriting a key with values: \(a) and \(b)!")
            return a
        }
    }

    @_spi(STP) public func mergingAssertingOnOverwrites<S>(_ other: S) -> [Key: Value] where S: Sequence, S.Element == (Key, Value) {
        merging(other) { a, b in
            stpAssertionFailure("Dictionary merge is overwriting a key with values: \(a) and \(b)!")
            return a
        }
    }
}

extension Dictionary where Value == Any {
    func jsonEncodeNestedDicts(options: JSONSerialization.WritingOptions = []) -> [Key: Any] {
        return compactMapValues { value in
            guard let dict = value as? Dictionary else {
                return value
            }

            // Note: An NSInvalidArgumentException can occur when the dict can't be
            // serialized instead of throwing an error, resulting in an app crash.
            // Call `isValidJSONObject` to ensure it's able to serialize the dict.
            guard JSONSerialization.isValidJSONObject(dict),
                let data = try? JSONSerialization.data(withJSONObject: dict, options: options)
            else {
                assertionFailure("Dictionary could not be serialized")
                return nil
            }

            return String(data: data, encoding: .utf8)
        }
    }
}

// From https://talk.objc.io/episodes/S01E31-mutating-untyped-dictionaries
@_spi(STP) public extension Dictionary {
    /// Example usage: `dict[jsonDict: "countries"]?[jsonDict: "japan"]?["capital"] = "berlin"`
    subscript(jsonDict key: Key) -> [String: Any]? {
        get {
            return self[key] as? [String: Any]
        }
        set {
            self[key] = newValue as? Value
        }
    }
}
