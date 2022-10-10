//
//  STPPaymentMethodNetBanking.swift
//  StripeiOS
//
//  Created by Anirudh Bhargava on 11/19/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation

/// A NetBanking Payment Method.
/// - seealso: https://stripe.com/docs/api/payment_methods/object#payment_method_object-netbanking
public class STPPaymentMethodNetBanking: NSObject, STPAPIResponseDecodable {
    @objc private(set) public var allResponseFields: [AnyHashable: Any] = [:]

    /// Customer’s Bank Name
    @objc public private(set) var bank: String

    // MARK: - Description
    /// :nodoc:
    @objc public override var description: String {
        let props = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPPaymentMethodNetBanking.self), self),
            "bank = \(bank)",
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

    required init?(dictionary dict: [AnyHashable: Any]) {
        let nsDict = dict as NSDictionary
        guard let bank = nsDict.stp_string(forKey: "bank") else {
            return nil
        }

        self.bank = bank

        super.init()
        allResponseFields = dict
    }
}
