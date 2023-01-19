//
//  PaymentSheetError.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 12/7/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
import StripePayments

/// Errors specific to PaymentSheet itself
///
/// Most errors do not originate from PaymentSheet itself; instead, they come from the Stripe API
/// or other SDK components like STPPaymentHandler, PassKit (Apple Pay), etc.
public enum PaymentSheetError: Error {
    /// An unknown error.
    case unknown(debugDescription: String)

    /// No payment method types available error.
    case noPaymentMethodTypesAvailable(intentPaymentMethods: [STPPaymentMethodType])

    /// Localized description of the error
    public var localizedDescription: String {
        return NSError.stp_unexpectedErrorMessage()
    }
}

extension PaymentSheetError: CustomDebugStringConvertible {
    /// Returns true if the error is un-fixable; e.g. no amount of retrying or customer action will result in something different
    static func isUnrecoverable(error: Error) -> Bool {
        // TODO: Expired ephemeral key
        return false
    }

    public var debugDescription: String {
        return "An error occured in PaymentSheet. " + {
            switch self {
            case .noPaymentMethodTypesAvailable(let intentPaymentMethods):
                return "None of the payment methods on the PaymentIntent/SetupIntent can be used in PaymentSheet: \(intentPaymentMethods). You may need to set `allowsDelayedPaymentMethods` or `allowsPaymentMethodsRequiringShippingAddress` in your PaymentSheet.Configuration object."
            case .unknown(let debugDescription):
                return debugDescription
            }
        }()
    }
}
