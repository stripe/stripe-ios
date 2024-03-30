//
//  Error+PaymentSheet.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 8/30/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

extension Error {

    /// If the `localizedDescription` contains a generic error message this returns the raw error message within `userInfo`
    /// Otherwise returns the `localizedDescription`
    var nonGenericDescription: String {
        if let paymentSheetError = self as? PaymentSheetError {
            return paymentSheetError.debugDescription
        }
        if localizedDescription == "The operation couldn’t be completed. (STPPaymentHandlerErrorDomain error 2.)",
           let underlyingError = (self as NSError).userInfo["NSUnderlyingError"] as? NSError {
            let errorMessage = underlyingError.userInfo[STPError.errorMessageKey] as? String ?? NSError.stp_unexpectedErrorMessage()
            return errorMessage
        }
        // If the `localizedDescription` is not generic, return the `localizedDescription`
        if localizedDescription != NSError.stp_unexpectedErrorMessage() { return localizedDescription }

        // If error message is generic, return raw value for error message instead
        let errorMessage = (self as NSError).userInfo[STPError.errorMessageKey] as? String ?? NSError.stp_unexpectedErrorMessage()
        return errorMessage
    }
}
