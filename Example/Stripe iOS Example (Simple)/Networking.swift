//
//  Networking.swift
//  Stripe
//
//  Created by Ben Guo on 7/7/15.
//

import Foundation

public enum Method: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"

    public var encodesParametersInURL : Bool {
        switch self {
        case .GET:
            return true
        default:
            return false
        }
    }
}

public enum ParameterEncoding {
    public static func queryString(_ parameters: [String: AnyObject]) -> String {
        var components: [(String, String)] = []
        for key in Array(parameters.keys).sorted() {
            let value: AnyObject! = parameters[key]
            components += self.queryComponents(key, value)
        }

        return (components.map { "\($0)=\($1)" } as [String]).joined(separator: "&")
    }

    public static func queryComponents(_ key: String, _ value: AnyObject) -> [(String, String)] {
        var components: [(String, String)] = []
        if let dictionary = value as? [String: AnyObject] {
            for (nestedKey, value) in dictionary {
                components += queryComponents("\(key)[\(nestedKey)]", value)
            }
        } else if let array = value as? [AnyObject] {
            for value in array {
                components += queryComponents("\(key)[]", value)
            }
        } else if let _ = value as? NSNull {
            components += queryComponents("\(key)", "" as AnyObject)
        } else {
            components.append(contentsOf: [(escape(key), escape("\(value)"))])
        }

        return components
    }

    /// Returns a percent escaped string following RFC 3986 for query string formatting.
    public static func escape(_ string: String) -> String {
        let generalDelimiters = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimiters = "!$&'()*+,;="

        let legalURLCharactersToBeEscaped: CFString = (generalDelimiters + subDelimiters) as CFString

        return CFURLCreateStringByAddingPercentEscapes(nil, string as CFString!, nil, legalURLCharactersToBeEscaped, CFStringBuiltInEncodings.UTF8.rawValue) as String
    }

}

public extension URLRequest {
    public static func request(_ url: URL,
                               method: Method,
                               params: [String: AnyObject]) -> URLRequest {
        let request = NSMutableURLRequest(url: url)
        request.httpMethod = method.rawValue
        request.addParameters(params, method: method)
        return request as URLRequest
    }
}

public extension NSMutableURLRequest {
    /// Adds the given parameters in the request for the given method
    public func addParameters(_ params: [String: AnyObject], method: Method) {
        if method.encodesParametersInURL {
            if var URLComponents = URLComponents(url: self.url!, resolvingAgainstBaseURL: false) {
                URLComponents.percentEncodedQuery = (URLComponents.percentEncodedQuery.map { $0 + "&" } ?? "") + ParameterEncoding.queryString(params)
                self.url = URLComponents.url
            }
        }
        else {
            self.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            self.httpBody = Data.URLEncodedData(params)
        }
    }
}

public extension Data {
    public static func URLEncodedData(_ dict: [String: AnyObject]) -> Data? {
        return ParameterEncoding.queryString(dict).data(using: String.Encoding.utf8,
                                                                     allowLossyConversion: false)
    }
}

public extension NSError {
    public static func networkingError(_ status: Int) -> NSError {
        return NSError(domain: "FailingStatusCode", code: status, userInfo: nil)
    }
}

