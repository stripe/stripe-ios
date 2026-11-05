//
//  STPPaymentMethodSwish.swift
//  StripePayments
//
//  Created by Eduardo Urias on 9/21/23.
//

import Foundation

/// A Swish Payment Method.
/// - seealso: https://stripe.com/docs/payments/swish
public class STPPaymentMethodSwish: NSObject, STPAPIResponseDecodable {
    public private(set) var allResponseFields: [AnyHashable: Any] = [:]

    /// :nodoc:
    public override var description: String {
        let props = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPPaymentMethodSwish.self), self)
        ]

        return "<\(props.joined(separator: "; "))>"
    }

    // MARK: - STPAPIResponseDecodable
    override required init() {
        super.init()
    }

    public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let response = response else {
            return nil
        }
        let swish = self.init()
        swish.allResponseFields = response
        return swish
    }
}
