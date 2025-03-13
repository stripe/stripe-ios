//
//  STPPaymentMethodVipps.swift
//  StripePayments
//
//  Created by Vincent Pandac on 3/24/25.
//

import Foundation

/// The Vipps Payment Method.
/// - seealso: https://stripe.com/docs/api/payment_methods/object#payment_method_object-vipps
public class STPPaymentMethodVipps: NSObject, STPAPIResponseDecodable {
    /// :nodoc:
    @objc private(set) public var allResponseFields: [AnyHashable: Any] = [:]

    // MARK: - Description
    /// :nodoc:
    @objc public override var description: String {
        let props = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPPaymentMethodVipps.self), self)
        ]

        return "<\(props.joined(separator: "; "))>"
    }

    // MARK: - STPAPIResponseDecodeable
    @objc
    /// :nodoc:
    public static func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
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
