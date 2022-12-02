//
//  STPApplePayContextDelegate.swift
//  StripeiOS
//
//  Created by David Estes on 9/15/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import PassKit
@_spi(STP) import StripeApplePay
@_spi(STP) import StripeCore

/// Implement the required methods of this delegate to supply a PaymentIntent to STPApplePayContext and be notified of the completion of the Apple Pay payment.
/// You may also implement the optional delegate methods to handle shipping methods and shipping address changes e.g. to verify you can ship to the address, or update the payment amount.
@objc public protocol STPApplePayContextDelegate: _stpinternal_STPApplePayContextDelegateBase {
    /// Called after the customer has authorized Apple Pay.  Implement this method to call the completion block with the client secret of a PaymentIntent or SetupIntent.
    /// - Parameters:
    ///   - paymentMethod:                 The PaymentMethod that represents the customer's Apple Pay payment method.
    /// If you create the PaymentIntent with confirmation_method=manual, pass `paymentMethod.stripeId` as the payment_method and confirm=true. Otherwise, you can ignore this parameter.
    ///   - paymentInformation:      The underlying PKPayment created by Apple Pay.
    /// If you create the PaymentIntent with confirmation_method=manual, you can collect shipping information using its `shippingContact` and `shippingMethod` properties.
    ///   - completion:                        Call this with the PaymentIntent or SetupIntent client secret, or the error that occurred creating the PaymentIntent or SetupIntent.
    @objc(applePayContext:didCreatePaymentMethod:paymentInformation:completion:)
    func applePayContext(
        _ context: STPApplePayContext,
        didCreatePaymentMethod paymentMethod: STPPaymentMethod,
        paymentInformation: PKPayment,
        completion: @escaping STPIntentClientSecretCompletionBlock
    )

    /// Called after the Apple Pay sheet is dismissed with the result of the payment.
    /// Your implementation could stop a spinner and display a receipt view or error to the customer, for example.
    /// - Parameters:
    ///   - status: The status of the payment
    ///   - error: The error that occurred, if any.
    @objc(applePayContext:didCompleteWithStatus:error:)
    func applePayContext(
        _ context: STPApplePayContext,
        didCompleteWith status: STPPaymentStatus,
        error: Error?
    )
}

/// A helper class used to bridge StripeApplePay.framework with the legacy Stripe.framework objects.
@objc(STPApplePayContextLegacyHelper)
class STPApplePayContextLegacyHelper: NSObject {
    @objc class func performDidCreatePaymentMethod(
        _ storage: _stpinternal_ApplePayContextDidCreatePaymentMethodStorage
    ) {
        let delegate = storage.delegate as! STPApplePayContextDelegate
        // Convert the PaymentMethod to an STPPaymentMethod:
        guard
            let stpPaymentMethod = STPPaymentMethod.decodedObject(
                fromAPIResponse: storage.paymentMethod.allResponseFields
            )
        else {
            assertionFailure("Failed to convert PaymentMethod to STPPaymentMethod")
            return
        }
        delegate.applePayContext(
            storage.context,
            didCreatePaymentMethod: stpPaymentMethod,
            paymentInformation: storage.paymentInformation,
            completion: storage.completion
        )
    }

    @objc class func performDidComplete(_ storage: _stpinternal_ApplePayContextDidCompleteStorage) {
        let delegate = storage.delegate as! STPApplePayContextDelegate
        let stpStatus = STPPaymentStatus(applePayStatus: storage.status)

        // If this is a modern API error, convert it down to a legacy STPError.
        // This is to avoid changing the API experience for users.
        // We can re-evaluate this as we release more of the modern API.
        if let modernError = storage.error as? StripeError {
            storage.error = NSError.stp_error(from: modernError)
        }

        delegate.applePayContext(storage.context, didCompleteWith: stpStatus, error: storage.error)
    }

}

extension STPPaymentStatus {
    init(
        applePayStatus: STPApplePayContext.PaymentStatus
    ) {
        switch applePayStatus {
        case .success:
            self = .success
        case .error:
            self = .error
        case .userCancellation:
            self = .userCancellation
        }
    }
}
