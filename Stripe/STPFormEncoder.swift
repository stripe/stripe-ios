//
//  STPFormEncoder.swift
//  Stripe
//
//  Created by Jack Flintermann on 1/8/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

import Foundation

class STPFormEncoder: NSObject {
    @objc class func dictionary(forObject object: (NSObject & STPFormEncodable)) -> [String: Any] {
        // returns [object root name : object.coded (eg [property name strings: property values)]
        let keyPairs = self.keyPairDictionary(forObject: object)
        let rootObjectName = type(of: object).rootObjectName()
        if let rootObjectName = rootObjectName {
            return [rootObjectName: keyPairs]
        } else {
            return keyPairs
        }
    }

    class func string(byURLEncoding string: String) -> String {
        return escape(string)
    }

    class func stringByReplacingSnakeCase(withCamelCase input: String) -> String {
        let parts: [String] = input.components(separatedBy: "_")
        var camelCaseParam = ""
        for (idx, part) in parts.enumerated() {
            camelCaseParam += idx == 0 ? part : part.capitalized
        }

        return camelCaseParam
    }

    @objc(queryStringFromParameters:)
    class func queryString(from parameters: [String: Any]) -> String {
        return query(parameters)
    }

    // MARK: - Internal

    /// Returns [Property name : Property's form encodable value]
    private class func keyPairDictionary(forObject object: (NSObject & STPFormEncodable))
        -> [String:
        Any]
    {
        var keyPairs: [String: Any] = [:]
        for (propertyName, formFieldName) in type(of: object).propertyNamesToFormFieldNamesMapping()
        {
            if let propertyValue = object.value(forKeyPath: propertyName) {
                guard let propertyValue = propertyValue as? NSObject else {
                    assertionFailure()
                    continue
                }
                keyPairs[formFieldName] = formEncodableValue(for: propertyValue)
            }
        }
        for (additionalFieldName, additionalFieldValue) in object.additionalAPIParameters {
            guard let additionalFieldName = additionalFieldName as? String,
                let additionalFieldValue = additionalFieldValue as? NSObject
            else {
                assertionFailure()
                continue
            }
            keyPairs[additionalFieldName] = formEncodableValue(for: additionalFieldValue)
        }
        return keyPairs
    }

    /// Expands object, and any subobjects, into key pair dictionaries if they are STPFormEncodable
    private class func formEncodableValue(for object: NSObject) -> NSObject {
        switch object {
        case let object as NSObject & STPFormEncodable:
            return self.keyPairDictionary(forObject: object) as NSObject
        case let dict as NSDictionary:
            let result = NSMutableDictionary(capacity: dict.count)
            dict.enumerateKeysAndObjects({ key, value, _ in
                if let key = key as? NSObject,  // Don't all keys need to be Strings?
                    let value = value as? NSObject
                {
                    result[formEncodableValue(for: key)] = formEncodableValue(for: value)
                } else {
                    assertionFailure()  // TODO remove
                }
            })
            return result
        case let array as NSArray:
            let result = NSMutableArray()
            for element in array {
                guard let element = element as? NSObject else {
                    assertionFailure()  // TODO remove
                    continue
                }
                result.add(formEncodableValue(for: element))
            }
            return result
        case let set as NSSet:
            let result = NSMutableSet()
            for element in set {
                guard let element = element as? NSObject else {
                    continue
                }
                result.add(self.formEncodableValue(for: element))
            }
            return result
        default:
            return object
        }
    }
}

// MARK: -
// The code below is adapted from https://github.com/Alamofire/Alamofire

struct Key {
    enum Part {
        case normal(String)
        case dontEscape(String)
    }
    let parts: [Part]
}

/// Creates a percent-escaped, URL encoded query string components from the given key-value pair recursively.
///
/// - Parameters:
///   - key:   Key of the query component.
///   - value: Value of the query component.
///
/// - Returns: The percent-escaped, URL encoded query string components.
private func queryComponents(fromKey key: String, value: Any) -> [(String, String)] {
    func unwrap<T>(_ any: T) -> Any {
        let mirror = Mirror(reflecting: any)
        guard mirror.displayStyle == .optional, let first = mirror.children.first else {
            return any
        }
        return first.value
    }

    var components: [(String, String)] = []
    switch value {
    case let dictionary as [String: Any]:
        for nestedKey in dictionary.keys.sorted() {
            let value = dictionary[nestedKey]!
            let escapedNestedKey = escape(nestedKey)
            components += queryComponents(fromKey: "\(key)[\(escapedNestedKey)]", value: value)
        }
    case let array as [Any]:
        for (index, value) in array.enumerated() {
            components += queryComponents(fromKey: "\(key)[\(index)]", value: value)
        }
    case let number as NSNumber:
        if number.isBool {
            components.append((key, escape(number.boolValue ? "true" : "false")))
        } else {
            components.append((key, escape("\(number)")))
        }
    case let bool as Bool:
        components.append((key, escape(bool ? "true" : "false")))
    case let set as Set<AnyHashable>:
        for value in Array(set) {
            components += queryComponents(fromKey: "\(key)", value: value)
        }
    default:
        let unwrappedValue = unwrap(value)
        components.append((key, escape("\(unwrappedValue)")))
    }
    return components
}

/// Creates a percent-escaped string following RFC 3986 for a query string key or value.
///
/// - Parameter string: `String` to be percent-escaped.
///
/// - Returns:          The percent-escaped `String`.
private func escape(_ string: String) -> String {
    string.addingPercentEncoding(withAllowedCharacters: URLQueryAllowed) ?? string
}

private func query(_ parameters: [String: Any]) -> String {
    var components: [(String, String)] = []

    for key in parameters.keys.sorted(by: <) {
        let value = parameters[key]!
        components += queryComponents(fromKey: escape(key), value: value)
    }
    return components.map { "\($0)=\($1)" }.joined(separator: "&")
}

/// Creates a CharacterSet from RFC 3986 allowed characters.
///
/// RFC 3986 states that the following characters are "reserved" characters.
///
/// - General Delimiters: ":", "#", "[", "]", "@", "?", "/"
/// - Sub-Delimiters: "!", "$", "&", "'", "(", ")", "*", "+", ",", ";", "="
///
/// In RFC 3986 - Section 3.4, it states that the "?" and "/" characters should not be escaped to allow
/// query strings to include a URL. Therefore, all "reserved" characters with the exception of "?" and "/"
/// should be percent-escaped in the query string.
private let URLQueryAllowed: CharacterSet = {
    let generalDelimitersToEncode = ":#[]@"  // does not include "?" or "/" due to RFC 3986 - Section 3.4
    let subDelimitersToEncode = "!$&'()*+,;="
    let encodableDelimiters = CharacterSet(
        charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")

    return CharacterSet.urlQueryAllowed.subtracting(encodableDelimiters)
}()

extension NSNumber {
    fileprivate var isBool: Bool {
        // Use Obj-C type encoding to check whether the underlying type is a `Bool`, as it's guaranteed as part of
        // swift-corelibs-foundation, per [this discussion on the Swift forums](https://forums.swift.org/t/alamofire-on-linux-possible-but-not-release-ready/34553/22).
        String(cString: objCType) == "c"
    }
}
