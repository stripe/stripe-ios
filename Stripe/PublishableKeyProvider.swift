//
//  PublishableKeyProvider.swift
//  StripeiOS
//
//  Created by Mel Ludowise on 7/1/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore

protocol PublishableKeyProvider: PublishableKeyProviderSPI {
    var publishableKey: String? { get }
}

extension PublishableKeyProvider {
    /// :nodoc:
    public var publishableKeySPI: String? {
        return publishableKey
    }
}
