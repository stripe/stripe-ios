//
//  STPPaymentMethodAlipay.swift
//  StripePayments
//
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation

/// Contains details for an Alipay Payment Method.
/// - seealso: https://stripe.com/docs/api/payment_methods/object#payment_method_object-alipay
public class STPPaymentMethodAlipay: NSObject, STPAPIResponseDecodable {
    /// :nodoc:
    private(set) public var allResponseFields: [AnyHashable: Any] = [:]

    // MARK: - Description
    /// :nodoc:
    @objc public override var description: String {
        let props = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPPaymentMethodAlipay.self), self)
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
