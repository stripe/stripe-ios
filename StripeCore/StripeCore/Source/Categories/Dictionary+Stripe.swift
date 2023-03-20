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

            /*
             Note: An NSInvalidArgumentException can occur when the dict can't be
             serialized instead of throwing an error, resulting in an app crash.
             Call `isValidJSONObject` to ensure it's able to serialize the dict.
             */
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

extension Dictionary where Key == AnyHashable, Value == Any {
    @_spi(STP) public func stp_forLUXEJSONPath(_ path: String) -> Any? {
        let pathComponents = Dictionary.stp_parseLUXEJSONPath(path)
        var currDict = self
        for currKey in pathComponents {
            if let dict = currDict[currKey] as? [AnyHashable: Value] {
                currDict = dict
                if currKey == pathComponents.last {
                    return currDict
                }
            } else if let val = currDict[currKey] {
                return val
            } else {
                return nil
            }
        }
        return nil
    }

    // Splits a string to an array of strings
    // "key" returns ["key"]
    // "key[key1]" returns ["key", "key1"]
    // "key[key1][key2]" returns ["key", "key1", "key2"]
    static func stp_parseLUXEJSONPath(_ path: String) -> [String] {
        var currWord = ""
        let charArray = Array(path)
        var arrayWords: [String] = []
        for char in charArray {
            if char == "[" {
                if !currWord.isEmpty {
                    arrayWords.append(currWord)
                }
                currWord = ""
            } else if char == "]" {
                if !currWord.isEmpty {
                    arrayWords.append(currWord)
                }
                currWord = ""
            } else {
                currWord.append(char)
            }
        }
        if !currWord.isEmpty {
            arrayWords.append(currWord)
        }
        return arrayWords
    }

}
