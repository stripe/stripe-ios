//
//  STPPaymentMethodPayByBank.swift
//  StripePayments
//

import Foundation

/// The Pay by Bank Payment Method.
/// - seealso: https://docs.stripe.com/payments/pay-by-bank/accept-a-payment
public class STPPaymentMethodPayByBank: NSObject {
    /// :nodoc:
    @objc private(set) public var allResponseFields: [AnyHashable: Any] = [:]

    // MARK: - Description
    /// :nodoc:
    @objc public override var description: String {
        let props = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPPaymentMethodPayByBank.self), self)
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
