//
//  STPPaymentMethodPayco.swift
//  StripePayments
//
//  Created by Nick Porter on 8/27/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation

/// A PAYCO Payment Method.
/// - seealso: https://docs.stripe.com/payments/payco/accept-a-payment
public class STPPaymentMethodPayco: NSObject, STPAPIResponseDecodable {
    /// :nodoc:
    @objc private(set) public var allResponseFields: [AnyHashable: Any] = [:]

    /// :nodoc:
    @objc public override var description: String {
        let props = [
            String(format: "%@: %p", NSStringFromClass(STPPaymentMethodPayco.self), self)
        ]
        return "<\(props.joined(separator: "; "))>"
    }

    /// :nodoc:
    @objc public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let response else {
            return nil
        }
        return self.init(dictionary: response)
    }

    required init(dictionary: [AnyHashable: Any]) {
        super.init()
        allResponseFields = dictionary
    }
}
