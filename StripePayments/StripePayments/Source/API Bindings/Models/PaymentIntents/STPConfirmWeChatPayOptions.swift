//
//  STPConfirmWeChatPayOptions.swift
//  StripePayments
//
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

/// WeChat Pay options to pass to `STPConfirmPaymentMethodOptions``
/// - seealso: https://site-admin.stripe.com/docs/api/payment_intents/confirm#confirm_payment_intent-payment_method_options-wechat_pay
public class STPConfirmWeChatPayOptions: NSObject {

    /// WeChat client. On iOS, this is always "ios".
    let client = "ios"

    /// Your WeChat-provided application ID. WeChat Pay uses
    /// this as the redirect URL scheme.
    public var appId: String?

    public var additionalAPIParameters: [AnyHashable: Any] = [:]

    /// :nodoc:
    public override var description: String {
        let props = [
            // Object
            String(format: "%@: %p", NSStringFromClass(type(of: self)), self),
            "client = \(client)",
            "appId = \(String(describing: appId))",
        ]

        return "<\(props.joined(separator: "; "))>"
    }

    /// Initializes STPConfirmWeChatPayOptions
    /// - parameter appId: Your WeChat-provided application ID. WeChat Pay
    /// uses this as the redirect URL scheme.
    public required init(
        appId: String
    ) {
        self.appId = appId
        super.init()
    }
}

// MARK: - STPFormEncodable
extension STPConfirmWeChatPayOptions: STPFormEncodable {
    public class func propertyNamesToFormFieldNamesMapping() -> [AnyKeyPath: String] {
        return [
            \STPConfirmWeChatPayOptions.client: "client",
            \STPConfirmWeChatPayOptions.appId: "app_id",
        ]
    }

    public class func rootObjectName() -> String? {
        return "wechat_pay"
    }
}
