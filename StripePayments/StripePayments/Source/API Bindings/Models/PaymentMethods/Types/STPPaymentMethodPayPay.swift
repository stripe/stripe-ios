//
//  STPPaymentMethodPayPay.swift
//  StripePayments
//
//  Created by Joyce Qin on 12/1/25.
//

import Foundation

/// A PayPal Payment Method. :nodoc:
/// - seealso: https://stripe.com/docs/payments/paypay
@_spi(STP) public class STPPaymentMethodPayPay: NSObject, STPAPIResponseDecodable {
    @objc private(set) public var allResponseFields: [AnyHashable: Any] = [:]

    // MARK: - Description
    /// :nodoc:
    @objc public override var description: String {
        let props = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPPaymentMethodPayPay.self), self)
        ]

        return "<\(props.joined(separator: "; "))>"
    }

    // MARK: - STPAPIResponseDecodable
    @objc
    public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let response = response else {
            return nil
        }
        return self.init(dictionary: response)
    }

    required init(
        dictionary dict: [AnyHashable: Any]
    ) {
        super.init()
        allResponseFields = dict
    }
}
