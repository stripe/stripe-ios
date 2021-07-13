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
}
