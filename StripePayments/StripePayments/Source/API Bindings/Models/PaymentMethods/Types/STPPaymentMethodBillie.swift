//
//  STPPaymentMethodBillie.swift
//  StripePayments
//
//  Created by Eric Geniesse on 6/28/24.
//

import Foundation

/// The Billie Payment Method.
/// - seealso: https://docs.stripe.com/payments/billie/accept-a-payment
public class STPPaymentMethodBillie: NSObject {
    /// :nodoc:
    private(set) public var allResponseFields: [AnyHashable: Any] = [:]

    // MARK: - Description
    /// :nodoc:
    public override var description: String {
        let props = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPPaymentMethodBillie.self), self)
        ]

        return "<\(props.joined(separator: "; "))>"
    }

    // MARK: - STPAPIResponseDecodeable
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
