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
    private(set) public var allResponseFields: [AnyHashable: Any] = [:]

    /// :nodoc:
    public override var description: String {
        let props = [
            String(format: "%@: %p", NSStringFromClass(STPPaymentMethodPayco.self), self)
        ]
        return "<\(props.joined(separator: "; "))>"
    }

    /// :nodoc:
    public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
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
