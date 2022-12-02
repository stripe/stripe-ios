//
//  STPPaymentMethodKlarna.swift
//  StripePayments
//
//  Created by Nick Porter on 10/19/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

/// The Klarna Payment Method.
/// - seealso: https://stripe.com/docs/payments/klarna
public class STPPaymentMethodKlarna: NSObject, STPAPIResponseDecodable {
    /// :nodoc:
    @objc private(set) public var allResponseFields: [AnyHashable: Any] = [:]

    // MARK: - Description
    /// :nodoc:
    @objc public override var description: String {
        let props = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPPaymentMethodKlarna.self), self)
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

    required init?(
        dictionary dict: [AnyHashable: Any]
    ) {
        super.init()
        allResponseFields = dict
    }
}
