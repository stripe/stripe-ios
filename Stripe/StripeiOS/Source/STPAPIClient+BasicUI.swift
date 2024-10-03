//
//  STPAPIClient+BasicUI.swift
//  StripeiOS
//
//  Created by David Estes on 6/30/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

extension STPAPIClient {
    // MARK: Helpers

    /// A helper method that returns the Authorization header to use for API requests. If ephemeralKey is nil, uses self.publishableKey instead.
    func authorizationHeader(using ephemeralKey: STPEphemeralKey? = nil) -> [String: String] {
        return authorizationHeader(using: ephemeralKey?.secret)
    }
}
