//
//  STPPaymentMethodCashApp.swift
//  StripePayments
//
//  Created by Nick Porter on 12/12/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

/// The CashApp Payment Method.
/// - seealso: https://stripe.com/docs/payments/cash-app-pay
public class STPPaymentMethodCashApp: NSObject {
    /// :nodoc:
    @objc private(set) public var allResponseFields: [AnyHashable: Any] = [:]

    // MARK: - Description
    /// :nodoc:
    @objc public override var description: String {
        let props = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPPaymentMethodCashApp.self), self)
        ]

        return "<\(props.joined(separator: "; "))>"
    }

    // MARK: - STPAPIResponseDecodeable
    @objc
    /// :nodoc:
    public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let response = response else {
            return nil
        }

        return self.init(dictionary: response)
    }

    required init?(dictionary dict: [AnyHashable: Any]) {
        super.init()
        allResponseFields = dict
    }
}
