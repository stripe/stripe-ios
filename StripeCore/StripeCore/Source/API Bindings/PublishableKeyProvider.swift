//
//  PublishableKeyProvider.swift
//  StripeCore
//
//  Created by Mel Ludowise on 6/22/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//
import Foundation

/// Provides a publishable key
@_spi(STP) public protocol PublishableKeyProvider {
    var publishableKey: String? { get }
    
    /// A publishable key that only contains publishable keys and not secret keys
    /// If a secret key is found, returns "[REDACTED_LIVE_KEY]"
    var sanitizedPublishableKey: String? { get }
}

@_spi(STP) public extension PublishableKeyProvider {
    var sanitizedPublishableKey: String? {
        guard let publishableKey = publishableKey else {
            return nil
        }

        return publishableKey.isSecretKey ? "[REDACTED_LIVE_KEY]" : publishableKey
    }
}
