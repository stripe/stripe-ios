//
//  STPPaymentMethodSofort.swift
//  StripePayments
//
//  Created by David Estes on 8/7/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation

/// A Sofort Payment Method.
/// - seealso: https://stripe.com/docs/api/payment_methods/object#payment_method_object-Sofort
public class STPPaymentMethodSofort: NSObject, STPAPIResponseDecodable {
    @objc private(set) public var allResponseFields: [AnyHashable: Any] = [:]

    /// Two-letter ISO code representing the country the bank account is located in.
    @objc public private(set) var country: String?

    // MARK: - Description
    /// :nodoc:
    @objc public override var description: String {
        let props = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPPaymentMethodSofort.self), self),
            "country = \(country ?? "")",
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
        let dict = dict.stp_dictionaryByRemovingNulls()
        country = dict.stp_string(forKey: "country")
    }
}
