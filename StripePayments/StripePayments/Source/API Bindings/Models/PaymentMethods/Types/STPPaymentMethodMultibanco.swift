//
//  STPPaymentMethodMultibanco.swift
//  StripePayments
//
//  Created by Nick Porter on 4/22/24.
//

import Foundation

/// The Multibanco Payment Method.
/// - seealso: https://stripe.com/docs/api/payment_methods/object#payment_method_object-multibanco
public class STPPaymentMethodMultibanco: NSObject, STPAPIResponseDecodable {
    /// :nodoc:
    @objc private(set) public var allResponseFields: [AnyHashable: Any] = [:]

    // MARK: - Description
    /// :nodoc:
    @objc public override var description: String {
        let props = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPPaymentMethodMultibanco.self), self)
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
