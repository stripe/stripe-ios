//
//  STPSourceEnums.swift
//  StripePayments
//
//  Created by Brian Dorfman on 8/4/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

import Foundation

/// Usage types for a Source
@objc public enum STPSourceUsage: Int {
    /// The source can be reused.
    case reusable
    /// The source can only be used once.
    case singleUse
    /// The source's usage is unknown.
    case unknown
}

/// Status types for a Source
@objc public enum STPSourceStatus: Int {
    /// The source has been created and is awaiting customer action.
    case pending
    /// The source is ready to use. The customer action has been completed or the
    /// payment method requires no customer action.
    case chargeable
    /// The source has been used. This status only applies to single-use sources.
    case consumed
    /// The source, which was chargeable, has expired because it was not used to
    /// make a charge request within a specified amount of time.
    case canceled
    /// Your customer has not taken the required action or revoked your access
    /// (e.g., did not authorize the payment with their bank or canceled their
    /// mandate acceptance for SEPA direct debits).
    case failed
    /// The source status is unknown.
    case unknown
}

/// Types for a Source
/// - seealso: https://stripe.com/docs/sources
@objc public enum STPSourceType: Int {
    /// A card source. - seealso: https://stripe.com/docs/sources/cards
    case card
    /// An unknown type of source.
    case unknown
}
