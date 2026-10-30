//
//  STPPaymentMethodMobilePay.swift
//  StripePayments
//

import Foundation

/// The MobilePay Payment Method.
/// - seealso: https://stripe.com/docs/api/payment_methods/object#payment_method_object-mobilepay
public class STPPaymentMethodMobilePay: NSObject, STPAPIResponseDecodable {
    /// :nodoc:
    private(set) public var allResponseFields: [AnyHashable: Any] = [:]

    // MARK: - Description
    /// :nodoc:
    public override var description: String {
        let props = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPPaymentMethodMobilePay.self), self)
        ]

        return "<\(props.joined(separator: "; "))>"
    }

    // MARK: - STPAPIResponseDecodeable
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
