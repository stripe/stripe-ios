//
//  STPSourceSEPADebitDetails.swift
//  Stripe
//
//  Created by Brian Dorfman on 2/24/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

import Foundation

/// This class provides typed access to the contents of an STPSource `details`
/// dictionary for SEPA Debit sources.
public class STPSourceSEPADebitDetails: NSObject, STPAPIResponseDecodable {
  /// You cannot directly instantiate an `STPSourceSEPADebitDetails`.
  /// You should only use one that is part of an existing `STPSource` object.
  override init() {
  }

  /// The last 4 digits of the account number.
  @objc public private(set) var last4: String?
  /// The account's bank code.
  @objc public private(set) var bankCode: String?
  /// Two-letter ISO code representing the country of the bank account.
  @objc public private(set) var country: String?
  /// The account's fingerprint.
  @objc public private(set) var fingerprint: String?
  /// The reference of the mandate accepted by your customer.
  @objc public private(set) var mandateReference: String?
  /// The details of the mandate accepted by your customer.
  @objc public private(set) var mandateURL: URL?
  @objc public private(set) var allResponseFields: [AnyHashable: Any] = [:]

  // MARK: - Description
  /// :nodoc:
  @objc public override var description: String {
    let props = [
      // Object
      String(format: "%@: %p", NSStringFromClass(STPSourceSEPADebitDetails.self), self),
      // Basic SEPA debit details
      "last4 = \(last4 ?? "")",
      // Additional SEPA debit details (alphabetical)
      "bankCode = \(bankCode ?? "")",
      "country = \(country ?? "")",
      "fingerprint = \(fingerprint ?? "")",
      "mandateReference = \(mandateReference ?? "")",
      "mandateURL = \(String(describing: mandateURL))",
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
    allResponseFields = dict
    let dict = (dict as NSDictionary).stp_dictionaryByRemovingNulls() as NSDictionary
    last4 = dict.stp_string(forKey: "last4")
    bankCode = dict.stp_string(forKey: "bank_code")
    country = dict.stp_string(forKey: "country")
    fingerprint = dict.stp_string(forKey: "fingerprint")
    mandateReference = dict.stp_string(forKey: "mandate_reference")
    mandateURL = dict.stp_url(forKey: "mandate_url")

  }
}
