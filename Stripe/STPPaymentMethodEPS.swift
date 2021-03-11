//
//  STPPaymentMethodEPS.swift
//  StripeiOS
//
//  Created by Shengwei Wu on 5/14/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation

/// An EPS Payment Method.
/// - seealso: https://stripe.com/docs/api/payment_methods/object#payment_method_object-eps
public class STPPaymentMethodEPS: NSObject, STPAPIResponseDecodable {
    private(set) public var allResponseFields: [AnyHashable: Any] = [:]

    // MARK: - Description
    /// :nodoc:
    @objc public override var description: String {
        let props = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPPaymentMethodEPS.self), self)
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

    required init(dictionary dict: [AnyHashable: Any]) {
        super.init()
        allResponseFields = dict
    }
}
