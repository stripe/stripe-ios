//
//  STPPaymentMethodAmazonPay.swift
//  StripePayments
//
//  Created by Nick Porter on 2/21/24.
//

import Foundation

/// The Amazon Pay Payment Method.
/// - seealso: https://docs.stripe.com/payments/amazon-pay/accept-a-payment
public class STPPaymentMethodAmazonPay: NSObject {
    /// :nodoc:
    private(set) public var allResponseFields: [AnyHashable: Any] = [:]

    // MARK: - Description
    /// :nodoc:
    public override var description: String {
        let props = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPPaymentMethodAmazonPay.self), self)
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
