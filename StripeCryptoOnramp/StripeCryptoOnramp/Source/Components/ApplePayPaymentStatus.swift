//
//  ApplePayPaymentStatus.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 8/13/25.
//

/// Possible return statuses from `CryptoOnrampCoordinator.presentApplePay(using:from)`.
@_spi(CryptoOnrampSDKPreview)
public enum ApplePayPaymentStatus {

    /// Attempt to use Apple Pay resulted in success.
    case success

    /// The user canceled payment using Apple Pay.
    case canceled
}

public extension ApplePayPaymentStatus {

    /// Encapsulates a fallback error in the unlikely event that Apple Pay fails without a specified error.
    enum Error: Swift.Error {

        /// A fallback error case in the unlikely event that Apple Pay fails without a specified error.
        case applePayFallbackError
    }
}
