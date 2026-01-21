//
//  STPPaymentMethodTwint.swift
//  StripePayments
//
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation

/// A TWINT Payment Method.
/// - seealso: https://stripe.com/docs/payments/twint
public class STPPaymentMethodTwint: NSObject, STPAPIResponseDecodable {
    private(set) public var allResponseFields: [AnyHashable: Any] = [:]

    // MARK: - Description
    /// :nodoc:
    @objc public override var description: String {
        let props = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPPaymentMethodTwint.self), self)
        ]

        return "<\(props.joined(separator: "; "))>"
    }

    // MARK: - STPAPIResponseDecodable
    public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let response = response else {
            return nil
        }
        return self.init(dictionary: response)
    }

    required init(
        dictionary dict: [AnyHashable: Any]
    ) {
        super.init()
        allResponseFields = dict
    }
}
