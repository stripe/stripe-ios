//
//  VerifyKYCResult.swift
//  StripePaymentSheet
//
//  Created by Michael Liberatore on 10/28/25.
//

import Foundation

/// The result after a user performs KYC verification.
@_spi(STP)
public enum VerifyKYCResult {

    /// The user confirmed that displayed KYC information is accurate and up-to-date.
    case confirmed

    /// The user is choosing to update their address.
    case updateAddress

    /// The user canceled the KYC verification flow.
    case canceled
}
