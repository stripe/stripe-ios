//
//  URL+extension.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 10/4/24.
//

import Foundation

extension URL {
    /// Removes query and hashtag params from the absolute URL.
    /// - Note: Used for logging sanitized URLs to analytics or to compare URLs without query args
    var absoluteStringRemovingParams: String {
        // Remove query params
        var components = URLComponents(url: self, resolvingAgainstBaseURL: true)
        components?.queryItems = nil

        let absoluteString = components?.url?.absoluteString ?? self.absoluteString

        // Remove hashtag params
        return absoluteString.split(separator: "#").first.map(String.init) ?? ""
    }
}
