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
    public static func queryString(parameters: [String: AnyObject]) -> String {
        var components: [(String, String)] = []
        for key in Array(parameters.keys).sort() {
            let value: AnyObject! = parameters[key]
            components += self.queryComponents(key, value)
        }

        return (components.map { "\($0)=\($1)" } as [String]).joinWithSeparator("&")
    }

    public static func queryComponents(key: String, _ value: AnyObject) -> [(String, String)] {
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
            components += queryComponents("\(key)", "")
        } else {
            components.appendContentsOf([(escape(key), escape("\(value)"))])
        }

        return components
    }

    /// Returns a percent escaped string following RFC 3986 for query string formatting.
    public static func escape(string: String) -> String {
        let generalDelimiters = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimiters = "!$&'()*+,;="

        let legalURLCharactersToBeEscaped: CFStringRef = generalDelimiters + subDelimiters

        return CFURLCreateStringByAddingPercentEscapes(nil, string, nil, legalURLCharactersToBeEscaped, CFStringBuiltInEncodings.UTF8.rawValue) as String
    }

}

public extension NSURLRequest {
    public static func request(url: NSURL,
                               method: Method,
                               params: [String: AnyObject]) -> NSURLRequest {
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = method.rawValue
        request.addParameters(params, method: method)
        return request
    }
}

public extension NSMutableURLRequest {
    /// Adds the given parameters in the request for the given method
    public func addParameters(params: [String: AnyObject], method: Method) {
        if method.encodesParametersInURL {
            if let URLComponents = NSURLComponents(URL: self.URL!, resolvingAgainstBaseURL: false) {
                URLComponents.percentEncodedQuery = (URLComponents.percentEncodedQuery.map { $0 + "&" } ?? "") + ParameterEncoding.queryString(params)
                self.URL = URLComponents.URL
            }
        }
        else {
            self.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            self.HTTPBody = NSData.URLEncodedData(params)
        }
    }
}

public extension NSData {
    public static func URLEncodedData(dict: [String: AnyObject]) -> NSData? {
        return ParameterEncoding.queryString(dict).dataUsingEncoding(NSUTF8StringEncoding,
                                                                     allowLossyConversion: false)
    }
}

public extension NSError {
    public static func networkingError(status: Int) -> NSError {
        return NSError(domain: "FailingStatusCode", code: status, userInfo: nil)
    }
}

