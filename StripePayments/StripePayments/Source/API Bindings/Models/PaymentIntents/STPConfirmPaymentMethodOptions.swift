//
//  STPConfirmPaymentMethodOptions.swift
//  StripePayments
//
//  Created by Cameron Sabol on 1/10/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation

/// Options to update the associated PaymentMethod during PaymentIntent confirmation.
/// - seealso: https://stripe.com/docs/api/payment_intents/confirm#confirm_payment_intent-payment_method_options
public class STPConfirmPaymentMethodOptions: NSObject {

    /// Options to update a Card PaymentMethod.
    /// - seealso: STPConfirmCardOptions
    @objc public var cardOptions: STPConfirmCardOptions?

    /// Options for an Alipay Payment Method.
    @objc public var alipayOptions: STPConfirmAlipayOptions?

    /// Options for a BLIK Payment Method.
    @objc public var blikOptions: STPConfirmBLIKOptions?

    /// Options for a WeChat Pay Payment Method.
    @objc public var weChatPayOptions: STPConfirmWeChatPayOptions?

    /// Options for a US Bank Account Payment Method.
    @objc public var usBankAccountOptions: STPConfirmUSBankAccountOptions?

    /// Options for a Konbini Payment Method.
    @objc public var konbiniOptions: STPConfirmKonbiniOptions?

    /// :nodoc:
    @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]

    /// :nodoc:
    @objc public override var description: String {
        let props: [String] = [
            // Object
            String(format: "%@: %p", NSStringFromClass(type(of: self)), self),
            "alipay = \(String(describing: alipayOptions))",
            "card = \(String(describing: cardOptions))",
            "blik = \(String(describing: blikOptions))",
            "wechat_pay = \(String(describing: weChatPayOptions))",
            "us_bank_account = \(String(describing: usBankAccountOptions))",
            "konbini = \(String(describing: konbiniOptions))",
        ]
        return "<\(props.joined(separator: "; "))>"
    }
}

// MARK: - STPFormEncodable
extension STPConfirmPaymentMethodOptions: STPFormEncodable {
    @objc
    public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [
            NSStringFromSelector(#selector(getter: alipayOptions)): "alipay",
            NSStringFromSelector(#selector(getter: cardOptions)): "card",
            NSStringFromSelector(#selector(getter: blikOptions)): "blik",
            NSStringFromSelector(#selector(getter: weChatPayOptions)): "wechat_pay",
            NSStringFromSelector(#selector(getter: usBankAccountOptions)): "us_bank_account",
            NSStringFromSelector(#selector(getter: konbiniOptions)): "konbini",
        ]
    }

    @objc
    public class func rootObjectName() -> String? {
        return "payment_method_options"
    }
}
