//
//  STPPaymentMethodBLIK.swift
//  StripePayments
//
//  Created by Yuki Tokuhiro on 3/10/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

/// Contains details for a BLIK Payment Method.
/// - seealso: https://stripe.com/docs/api/payment_methods/object#payment_method_object-blik
public class STPPaymentMethodBLIK: NSObject, STPAPIResponseDecodable {
    /// :nodoc:
    private(set) public var allResponseFields: [AnyHashable: Any] = [:]

    // MARK: - Description
    /// :nodoc:
    @objc public override var description: String {
        let props = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPPaymentMethodBLIK.self), self)
        ]

        return "<\(props.joined(separator: "; "))>"
    }

    // MARK: - STPAPIResponseDecodable
    /// :nodoc:
    public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let dict = response?.stp_dictionaryByRemovingNulls() else {
            return nil
        }
        return self.init(dictionary: dict)

    }

    required init(
        dictionary dict: [AnyHashable: Any]
    ) {
        super.init()
        allResponseFields = dict
    }
}
