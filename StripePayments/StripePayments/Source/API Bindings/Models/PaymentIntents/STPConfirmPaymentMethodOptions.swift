//
//  STPConfirmPaymentMethodOptions.swift
//  StripePayments
//
//  Created by Cameron Sabol on 1/10/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation

/// Payment method-specific options for PaymentIntent or SetupIntent confirmation.
/// - seealso: https://stripe.com/docs/api/payment_intents/confirm#confirm_payment_intent-payment_method_options
/// - seealso: https://stripe.com/docs/api/setup_intents/confirm#confirm_setup_intent-payment_method_options
public class STPConfirmPaymentMethodOptions: NSObject {

    /// Options to update a Card PaymentMethod.
    /// - seealso: STPConfirmCardOptions
    public var cardOptions: STPConfirmCardOptions?

    /// Options for an Alipay Payment Method.
    public var alipayOptions: STPConfirmAlipayOptions?

    /// Options for a BLIK Payment Method.
    public var blikOptions: STPConfirmBLIKOptions?

    /// Options for a WeChat Pay Payment Method.
    public var weChatPayOptions: STPConfirmWeChatPayOptions?

    /// Options for a US Bank Account Payment Method.
    public var usBankAccountOptions: STPConfirmUSBankAccountOptions?

    /// Options for a Link Payment Method.
    @_spi(InternalOnlyAPI) public var linkOptions: STPConfirmLinkOptions?

    /// Options for a Konbini Payment Method.
    public var konbiniOptions: STPConfirmKonbiniOptions?

    /// Options for a Klarna Payment Method.
    @_spi(KlarnaSDKPrivatePreview) public var klarnaOptions: STPConfirmKlarnaOptions?

    /// Initializes payment method options with Klarna options.
    /// - Parameter klarnaOptions: Options for a Klarna Payment Method.
    @_spi(KlarnaSDKPrivatePreview) public convenience init(klarnaOptions: STPConfirmKlarnaOptions) {
        self.init()
        self.klarnaOptions = klarnaOptions
    }

    /// :nodoc:
    public var additionalAPIParameters: [AnyHashable: Any] = [:]

    /// :nodoc:
    public override var description: String {
        let props: [String] = [
            // Object
            String(format: "%@: %p", NSStringFromClass(type(of: self)), self),
            "alipay = \(String(describing: alipayOptions))",
            "card = \(String(describing: cardOptions))",
            "blik = \(String(describing: blikOptions))",
            "wechat_pay = \(String(describing: weChatPayOptions))",
            "us_bank_account = \(String(describing: usBankAccountOptions))",
            "konbini = \(String(describing: konbiniOptions))",
            "klarna = \(String(describing: klarnaOptions))",
            "link = \(String(describing: linkOptions))",
        ]
        return "<\(props.joined(separator: "; "))>"
    }
}

// MARK: - STPFormEncodable
extension STPConfirmPaymentMethodOptions: STPFormEncodable {
    public class func propertyNamesToFormFieldNamesMapping() -> [AnyKeyPath: String] {
        return [
            \STPConfirmPaymentMethodOptions.alipayOptions: "alipay",
            \STPConfirmPaymentMethodOptions.cardOptions: "card",
            \STPConfirmPaymentMethodOptions.blikOptions: "blik",
            \STPConfirmPaymentMethodOptions.weChatPayOptions: "wechat_pay",
            \STPConfirmPaymentMethodOptions.usBankAccountOptions: "us_bank_account",
            \STPConfirmPaymentMethodOptions.konbiniOptions: "konbini",
            \STPConfirmPaymentMethodOptions.klarnaOptions: "klarna",
            \STPConfirmPaymentMethodOptions.linkOptions: "link",
        ]
    }

    public class func rootObjectName() -> String? {
        return "payment_method_options"
    }
}
