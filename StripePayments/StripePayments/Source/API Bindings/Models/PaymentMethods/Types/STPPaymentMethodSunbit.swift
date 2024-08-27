//
//  STPPaymentMethodSunbit.swift
//  StripePayments
//
//  Created by Eric Geniesse on 6/27/24.
//

import Foundation

/// The Sunbit Payment Method.
/// - seealso: https://docs.stripe.com/payments/sunbit/accept-a-payment
public class STPPaymentMethodSunbit: NSObject {
    /// :nodoc:
    @objc private(set) public var allResponseFields: [AnyHashable: Any] = [:]

    // MARK: - Description
    /// :nodoc:
    @objc public override var description: String {
        let props = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPPaymentMethodSunbit.self), self)
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
