//
//  CollectPaymentMethodResult.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 3/19/26.
//

import Foundation

/// Represents the result of `CryptoOnrampCoordinator.collectPaymentMethod(type:from:)`.
@_spi(CryptoOnrampAlpha)
public enum CollectPaymentMethodResult {

    /// Payment method collection completed with a display snapshot and optional KYC information.
    case completed(displayData: PaymentMethodDisplayData, kycInfo: KycInfo?)

    /// Payment method collection was canceled by the user.
    case canceled
}

public extension CollectPaymentMethodResult {

    /// A snapshot of the collected card, if available. Nil for canceled collection or non-card instruments.
    var cardDetails: OnrampCardDetails? {
        displayData?.cardDetails
    }

    /// A snapshot of the collected bank account, if available. Nil for canceled collection or non-bank instruments.
    var bankAccountDetails: OnrampBankAccountDetails? {
        displayData?.bankAccountDetails
    }

    /// The display data returned from `CryptoOnrampCoordinator.collectPaymentMethod(type:from:)`, if payment method collection completed.
    var displayData: PaymentMethodDisplayData? {
        switch self {
        case .completed(let displayData, _):
            return displayData
        case .canceled:
            return nil
        }
    }
}
