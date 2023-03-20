//
//  STPPaymentMethodAfterpayClearpay.swift
//  StripeiOS
//
//  Created by Ali Riaz on 1/12/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

/// An AfterpayClearpay Payment Method.
/// - seealso: https://stripe.com/docs/api/payment_methods/object#payment_method_object-afterpay_clearpay
public class STPPaymentMethodAfterpayClearpay: NSObject, STPAPIResponseDecodable {
    @objc private(set) public var allResponseFields: [AnyHashable: Any] = [:]

    // MARK: - Description
    /// :nodoc:
    @objc public override var description: String {
        let props = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPPaymentMethodAfterpayClearpay.self), self)
        ]

        return "<\(props.joined(separator: "; "))>"
    }

    // MARK: - STPAPIResponseDecodeable
    @objc
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
