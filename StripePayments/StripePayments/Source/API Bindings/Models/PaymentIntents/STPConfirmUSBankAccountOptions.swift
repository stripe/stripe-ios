//
//  STPConfirmUSBankAccountOptions.swift
//  StripePayments
//
//  Created by Cameron Sabol on 3/16/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

// MARK: - STPConfirmUSBankAccountOptions

/// Options for US Bank Account Payment Methods during PaymentIntent or SetupIntent confirmation
/// - seealso https://stripe.com/docs/api/payment_intents/confirm#confirm_payment_intent-payment_method_options-us_bank_account
public class STPConfirmUSBankAccountOptions: NSObject {
    /// Initializer for `STPConfirmUSBankAccountOptions`
    /// - Parameter setupFutureUsage: Indicates that you intend to make future payments with this payment method.
    @objc public init(
        setupFutureUsage: STPPaymentIntentSetupFutureUsage
    ) {
        self.setupFutureUsage = setupFutureUsage
    }

    /// Indicates that you intend to make future payments with this payment method.
    /// Providing this parameter will attach the payment method to the PaymentIntent’s Customer, if present, after the Intent is confirmed and any required actions from the user are complete. If no Customer was provided, the payment method can still be attached to a Customer after the transaction completes.
    ///
    /// If setup_future_usage is already set, you may only update the value from on_session to off_session.
    @objc public var setupFutureUsage: STPPaymentIntentSetupFutureUsage

    @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]
}

// MARK: - STPFormEncodable
extension STPConfirmUSBankAccountOptions: STPFormEncodable {

    @objc internal var setupFutureUsageRawString: String? {
        return setupFutureUsage.stringValue
    }

    public static func rootObjectName() -> String? {
        return "us_bank_account"
    }

    public static func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        [NSStringFromSelector(#selector(getter: setupFutureUsageRawString)): "setup_future_usage"]
    }
}
