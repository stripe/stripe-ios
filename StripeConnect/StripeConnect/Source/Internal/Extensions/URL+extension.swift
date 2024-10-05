//
//  URL+extension.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 10/4/24.
//

extension URL {
    var sanitizedForLogging: String {
        // Remove query params
        var components = URLComponents(url: self, resolvingAgainstBaseURL: true)
        components?.queryItems = nil

        let absoluteString = components?.url?.absoluteString ?? self.absoluteString

        // Remove hashtag params
        return absoluteString.split(separator: "#").first.map(String.init) ?? ""
    }
}
