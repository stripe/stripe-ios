//
//  URLEncoder.swift
//  StripeCore
//
//  Created by Mel Ludowise on 5/26/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

@_spi(STP) public final class URLEncoder {
    public class func string(byURLEncoding string: String) -> String {
        return escape(string)
    }

    public class func convertToCamelCase(snakeCase input: String) -> String {
        let parts: [String] = input.components(separatedBy: "_")
        var camelCaseParam = ""
        for (idx, part) in parts.enumerated() {
            camelCaseParam += idx == 0 ? part : part.capitalized
        }

        return camelCaseParam
    }

    public class func convertToSnakeCase(camelCase input: String) -> String {
        var newString = input

        while let range = newString.rangeOfCharacter(from: .uppercaseLetters) {
            let character = newString[range]
            newString = newString.replacingCharacters(in: range, with: character.lowercased())
            newString.insert("_", at: range.lowerBound)
        }

        return newString
    }

    @objc(queryStringFromParameters:)
    public class func queryString(from parameters: [String: Any]) -> String {
        return query(parameters, encoder: escape)
    }

    // For apps linked on or after iOS 17 and aligned OS versions, `URL` automatically percent- and IDNA-encodes invalid
    // characters to help create a valid URL. See https://developer.apple.com/documentation/foundation/url/3126806-init
    @objc(queryStringForURLFromParameters:)
    public class func queryStringForURL(from params: [String: Any]) -> String {
        var encoder = escape
        #if compiler(>=5.9)
            if #available(iOS 17.0, *) {
                // don't escape here because URL init escapes in iOS 17
                encoder = escapeSpacesOnly
            }
        #endif
        return query(params, encoder: encoder)
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
private func queryComponents(fromKey key: String, value: Any, encoder: (String) -> String) -> [(String, String)] {
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
            let escapedNestedKey = encoder(nestedKey)
            components += queryComponents(fromKey: "\(key)[\(escapedNestedKey)]", value: value, encoder: encoder)
        }
    case let array as [Any]:
        for (index, value) in array.enumerated() {
            components += queryComponents(fromKey: "\(key)[\(index)]", value: value, encoder: encoder)
        }
    case let number as NSNumber:
        if number.isBool {
            components.append((key, encoder(number.boolValue ? "true" : "false")))
        } else {
            components.append((key, encoder("\(number)")))
        }
    case let bool as Bool:
        components.append((key, encoder(bool ? "true" : "false")))
    case let set as Set<AnyHashable>:
        for value in Array(set) {
            components += queryComponents(fromKey: "\(key)", value: value, encoder: encoder)
        }
    default:
        let unwrappedValue = unwrap(value)
        components.append((key, encoder("\(unwrappedValue)")))
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

private func escapeSpacesOnly(_ string: String) -> String {
    return if #available(iOS 16.0, *) {
        string.replacing(" ", with: "+")
    } else {
        string
    }
}

private func query(_ parameters: [String: Any], encoder: (String) -> String) -> String {
    var components: [(String, String)] = []

    for key in parameters.keys.sorted(by: <) {
        let value = parameters[key]!
        components += queryComponents(fromKey: encoder(key), value: value, encoder: encoder)
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
    // does not include "?" or "/" due to RFC 3986 - Section 3.4.
    let generalDelimitersToEncode = ":#[]@"
    let subDelimitersToEncode = "!$&'()*+,;="
    let encodableDelimiters = CharacterSet(
        charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)"
    )

    return CharacterSet.urlQueryAllowed.subtracting(encodableDelimiters)
}()

extension NSNumber {
    fileprivate var isBool: Bool {
        // Use Obj-C type encoding to check whether the underlying type is a `Bool`, as it's guaranteed as part of
        // swift-corelibs-foundation, per [this discussion on the Swift forums](https://forums.swift.org/t/alamofire-on-linux-possible-but-not-release-ready/34553/22).
        String(cString: objCType) == "c"
    }
}
