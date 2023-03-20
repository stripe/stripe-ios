//
//  STPConfirmWeChatPayOptions.swift
//  StripeiOS
//
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

/// WeChat Pay options to pass to `STPConfirmPaymentMethodOptions``
/// - seealso: https://site-admin.stripe.com/docs/api/payment_intents/confirm#confirm_payment_intent-payment_method_options-wechat_pay
public class STPConfirmWeChatPayOptions: NSObject {

    /// WeChat client. On iOS, this is always "ios".
    @objc let client = "ios"
    
    /// Your WeChat-provided application ID. WeChat Pay uses
    /// this as the redirect URL scheme.
    @objc public var appId: String?
    
    @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]

    /// :nodoc:
    @objc public override var description: String {
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
    @objc public required init(appId: String) {
        self.appId = appId
        super.init()
    }
}

// MARK: - STPFormEncodable
extension STPConfirmWeChatPayOptions: STPFormEncodable {
    @objc
    public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [
            NSStringFromSelector(#selector(getter:client)): "client",
            NSStringFromSelector(#selector(getter:appId)): "app_id"
        ]
    }

    @objc
    public class func rootObjectName() -> String? {
        return "wechat_pay"
    }
}
