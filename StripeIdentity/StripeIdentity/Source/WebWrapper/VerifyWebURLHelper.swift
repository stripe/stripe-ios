//
//  VerifyWebURLHelper.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 3/3/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

/// Helper methods and vars to construct and verify Identity Verification web URLs
struct VerifyWebURLHelper {
    static let baseURLString = "https://verify.stripe.com"

    static let successPath = "success"
    static let startPath = "start"

    static let baseURL = URL(string: baseURLString)!
    static let successURL = baseURL.appendingPathComponent(successPath)

    static func startURL(fromToken token: String) -> URL {
        return baseURL.appendingPathComponent(startPath).appendingPathComponent(token)
    }

}
