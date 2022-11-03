//
//  STPAPIClient+ApplePay.swift
//  StripeApplePay
//
//  Created by Jack Flintermann on 12/19/14.
//  Copyright © 2014 Stripe, Inc. All rights reserved.
//

import Foundation
import PassKit
@_spi(STP) import StripeCore

/// STPAPIClient extensions to create Stripe Tokens, Sources, or PaymentMethods from Apple Pay PKPayment objects.
extension STPAPIClient {
    /// Converts Stripe errors into the appropriate Apple Pay error, for use in `PKPaymentAuthorizationResult`.
    /// If the error can be fixed by the customer within the Apple Pay sheet, we return an NSError that can be displayed in the Apple Pay sheet.
    /// Otherwise, the original error is returned, resulting in the Apple Pay sheet being dismissed. You should display the error message to the customer afterwards.
    /// Currently, we convert billing address related errors into a PKPaymentError that helpfully points to the billing address field in the Apple Pay sheet.
    /// Note that Apple Pay should prevent most card errors (e.g. invalid CVC, expired cards) when you add a card to the wallet.
    /// - Parameter stripeError:   An error from the Stripe SDK.
    @objc(pkPaymentErrorForStripeError:)
    public class func pkPaymentError(forStripeError stripeError: Error?) -> Error? {
        guard let stripeError = stripeError else {
            return nil
        }

        if (stripeError as NSError).domain == STPError.stripeDomain
            && ((stripeError as NSError).userInfo[STPError.cardErrorCodeKey] as? String
                == STPCardErrorCode.incorrectZip.rawValue)
        {
            var userInfo = (stripeError as NSError).userInfo
            var errorCode: PKPaymentError.Code = .unknownError
            errorCode = .billingContactInvalidError
            userInfo[PKPaymentErrorKey.postalAddressUserInfoKey.rawValue] =
                CNPostalAddressPostalCodeKey
            return NSError(
                domain: STPError.stripeDomain,
                code: errorCode.rawValue,
                userInfo: userInfo
            )
        }
        return stripeError
    }
}
