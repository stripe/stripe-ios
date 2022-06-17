//
//  Dictionary+Stripe.swift
//  StripeCore
//
//  Created by David Estes on 10/18/21.
//

import Foundation

extension Dictionary {
    static func stp_deepMerge(old: Any, new: Any) throws -> Any {
        if let oldDictionary = old as? Dictionary<String, Any>,
           let newDictionary = new as? Dictionary<String, Any> {
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
               let equatableSubtractValue = subtractDict[key] as? AnyHashable {
                if equatableValue == equatableSubtractValue {
                    newDict.removeValue(forKey: key)
                    continue
                }
            }
            if let dict1 = value as? Dictionary,
               let dict2 = subtractDict[key] as? Dictionary {
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
}

extension Dictionary where Value == Any {
    func jsonEncodeNestedDicts(options: JSONSerialization.WritingOptions = []) -> [Key: Any] {
        return compactMapValues { value in
            guard let dict = value as? Dictionary else {
                return value
            }

            guard let data = try? JSONSerialization.data(withJSONObject: dict, options: options) else {
                return nil
            }

            return String(data: data, encoding: .utf8)
        }
    }
}
