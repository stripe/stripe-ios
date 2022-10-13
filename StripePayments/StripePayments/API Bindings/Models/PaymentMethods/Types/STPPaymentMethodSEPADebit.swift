//
//  STPPaymentMethodSEPADebit.swift
//  StripeiOS
//
//  Created by Cameron Sabol on 10/7/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation

/// A SEPA Debit Payment Method.
/// - seealso: https://stripe.com/docs/api/payment_methods/object#payment_method_object-sepa_debit
public class STPPaymentMethodSEPADebit: NSObject, STPAPIResponseDecodable {
    @objc private(set) public var allResponseFields: [AnyHashable: Any] = [:]
    /// The last 4 digits of the account number.
    @objc public private(set) var last4: String?
    /// The account's bank code.
    @objc public private(set) var bankCode: String?
    /// The account's branch code
    @objc public private(set) var branchCode: String?
    /// Two-letter ISO code representing the country of the bank account.
    @objc public private(set) var country: String?
    /// The account's fingerprint.
    @objc public private(set) var fingerprint: String?
    /// The reference of the mandate accepted by your customer. - seealso: https://stripe.com/docs/api/sources/create#create_source-mandate
    @objc public private(set) var mandate: String?

    // MARK: - Description
    /// :nodoc:
    @objc public override var description: String {
        let props = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPPaymentMethodSEPADebit.self), self),
            // Basic SEPA debit details
            "last4 = \(last4 ?? "")",
            // Additional SEPA debit details (alphabetical)
            "bankCode = \(bankCode ?? "")",
            "branchCode = \(branchCode ?? "")",
            "country = \(country ?? "")",
            "fingerprint = \(fingerprint ?? "")",
            "mandate = \(mandate ?? "")",
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

    required init(dictionary dict: [AnyHashable: Any]) {
        super.init()
        allResponseFields = dict
        let dict = (dict as NSDictionary).stp_dictionaryByRemovingNulls() as NSDictionary
        last4 = dict.stp_string(forKey: "last4")
        bankCode = dict.stp_string(forKey: "bank_code")
        branchCode = dict.stp_string(forKey: "branch_code")
        country = dict.stp_string(forKey: "country")
        fingerprint = dict.stp_string(forKey: "fingerprint")
        mandate = dict.stp_string(forKey: "mandate")
    }
}
