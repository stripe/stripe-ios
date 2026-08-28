//
//  STPPaymentMethodACSSDebit.swift
//  StripePayments
//
//  Created by Nick Porter on 8/27/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation

/// An ACSS Debit Payment Method.
/// - seealso: https://stripe.com/docs/api/payment_methods/object#payment_method_object-acss_debit
public class STPPaymentMethodACSSDebit: NSObject, STPAPIResponseDecodable {
    /// :nodoc:
    private(set) public var allResponseFields: [AnyHashable: Any] = [:]

    /// The name of the bank associated with this bank account.
    @objc public private(set) var bankName: String?
    /// Uniquely identifies this bank account.
    @objc public private(set) var fingerprint: String
    /// The three-digit institution number for this bank account.
    @objc public private(set) var institutionNumber: String
    /// The last four digits of the bank account number.
    @objc public private(set) var last4: String
    /// The five-digit transit number for this bank account.
    @objc public private(set) var transitNumber: String

    // MARK: - Description

    /// :nodoc:
    @objc public override var description: String {
        let props = [
            String(format: "%@: %p", NSStringFromClass(STPPaymentMethodACSSDebit.self), self),
            "bankName = \(bankName ?? "")",
            "fingerprint = \(fingerprint)",
            "institutionNumber = \(institutionNumber)",
            "last4 = \(last4)",
            "transitNumber = \(transitNumber)",
        ]
        return "<\(props.joined(separator: "; "))>"
    }

    // MARK: - STPAPIResponseDecodable

    public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let response else {
            return nil
        }
        return self.init(dictionary: response.stp_dictionaryByRemovingNulls())
    }

    required init?(dictionary: [AnyHashable: Any]) {
        guard let fingerprint = dictionary.stp_string(forKey: "fingerprint"),
              let institutionNumber = dictionary.stp_string(forKey: "institution_number"),
              let last4 = dictionary.stp_string(forKey: "last4"),
              let transitNumber = dictionary.stp_string(forKey: "transit_number") else {
            return nil
        }

        self.bankName = dictionary.stp_string(forKey: "bank_name")
        self.fingerprint = fingerprint
        self.institutionNumber = institutionNumber
        self.last4 = last4
        self.transitNumber = transitNumber

        super.init()
        allResponseFields = dictionary
    }
}
