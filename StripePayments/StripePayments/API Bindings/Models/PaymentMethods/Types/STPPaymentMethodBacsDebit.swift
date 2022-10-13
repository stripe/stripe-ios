//
//  STPPaymentMethodBacsDebit.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 1/28/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation

/// A Bacs Debit Payment Method.
/// - seealso: https://stripe.com/docs/api/payment_methods/object#payment_method_object-bacs_debit
public class STPPaymentMethodBacsDebit: NSObject, STPAPIResponseDecodable {
    private(set) public var allResponseFields: [AnyHashable: Any] = [:]

    /// This payment method's fingerprint.
    @objc public private(set) var fingerprint: String?
    /// The last four digits of the bank account.
    @objc public private(set) var last4: String?
    /// The sort code of the bank account (eg 10-88-00)
    @objc public private(set) var sortCode: String?

    // MARK: - Description
    /// :nodoc:
    @objc public override var description: String {
        let props = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPPaymentMethodBacsDebit.self), self),
            "fingerprint = \(fingerprint ?? "")",
            "last4 = \(last4 ?? "")",
            "sortCode = \(sortCode ?? "")",
        ]

        return "<\(props.joined(separator: "; "))>"
    }

    // MARK: - STPAPIResponseDecodable
    public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let response = response else {
            return nil
        }
        return self.init(dictionary: response)
    }

    required init(dictionary dict: [AnyHashable: Any]) {
        super.init()
        fingerprint = dict["fingerprint"] as? String
        last4 = dict["last4"] as? String
        sortCode = dict["sort_code"] as? String
        allResponseFields = dict
    }
}
