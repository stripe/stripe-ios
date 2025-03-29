//
//  URL+Extensions.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 2025-03-19.
//

import Foundation

extension URL {
    func matchesSchemeHostAndPath(of otherURL: URL) -> Bool {
        return (
            self.scheme == otherURL.scheme &&
            self.host == otherURL.host &&
            self.path == otherURL.path
        )
    }
}
