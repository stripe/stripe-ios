//
//  STPConfirmBLIKOptions.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 3/10/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

/// BLIK options to pass to `STPConfirmPaymentMethodOptions``
/// - seealso: https://site-admin.stripe.com/docs/api/payment_intents/confirm#confirm_payment_intent-payment_method_options-blik
public class STPConfirmBLIKOptions: NSObject {

    /// The 6-digit BLIK code that a customer has generated using their banking application.
    @objc public var code: String

    @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]

    /// :nodoc:
    @objc public override var description: String {
        let props = [
            // Object
            String(format: "%@: %p", NSStringFromClass(type(of: self)), self),
            "code = \(code)",
        ]

        return "<\(props.joined(separator: "; "))>"
    }

    /// Initializes STPConfirmBLIKOptions
    /// - parameter code: The 6-digit BLIK code that a customer has generated using their banking application.
    @objc public required init(code: String) {
        self.code = code
        super.init()
    }
}

// MARK: - STPFormEncodable
extension STPConfirmBLIKOptions: STPFormEncodable {
    @objc
    public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [
            NSStringFromSelector(#selector(getter:code)): "code",
        ]
    }

    @objc
    public class func rootObjectName() -> String? {
        return "blik"
    }
}
