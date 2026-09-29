//
//  FulfillAdditionalKYCRequirementResult.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 9/28/26.
//

import Foundation

/// The outcome of collecting an additional KYC requirement.
@_spi(CryptoOnrampAlpha)
public enum FulfillAdditionalKYCRequirementResult: Equatable, Sendable {

    /// Stripe accepted a new document submission for asynchronous verification.
    case submitted

    /// An existing submission is awaiting Stripe or partner review.
    case pendingVerification

    /// The customer dismissed collection before submitting.
    case canceled

    /// A fresh requirements check found nothing to collect.
    case notRequired
}
