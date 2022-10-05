//
//  AuthFlowHelpers.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 10/5/22.
//

import Foundation

final class AuthFlowHelpers {
    
    static func formatUrlString(_ urlString: String?) -> String? {
        guard var urlString = urlString else {
            return nil
        }
        if urlString.hasPrefix("https://") {
            urlString.removeFirst("https://".count)
        }
        if urlString.hasPrefix("http://") {
            urlString.removeFirst("http://".count)
        }
        if urlString.hasPrefix("www.") {
            urlString.removeFirst("www.".count)
        }
        if urlString.hasSuffix("/") {
            urlString.removeLast()
        }
        return urlString
    }
}
