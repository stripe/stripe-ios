//
//  PublishableKeyProviderSPI.swift
//  StripeCore
//
//  Created by Mel Ludowise on 6/22/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//
import Foundation

/**
 Provides a publishable key.

 - Note:
 NOTE(mludowise): To avoid Jazzy from displaying SPI-public protocol conformance,
 this protocol shouldn't be implemented directly by public classes. Instead,
 each module should implement its own internal protocol that extends this one.
 See `PublishableKeyProvider.swift` inside the `Stripe` module for an example.

 If Jazzy ever provides the ability to ignore SPI-public protocol conformance,
 this should be updated.
 */
@_spi(STP) public protocol PublishableKeyProviderSPI {
    var publishableKeySPI: String? { get }
}
