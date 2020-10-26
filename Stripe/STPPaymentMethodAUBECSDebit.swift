//
//  STPPaymentMethodAUBECSDebit.swift
//  StripeiOS
//
//  Created by Cameron Sabol on 3/3/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation

/// An AU BECS Debit Payment Method.
/// - seealso: https://stripe.com/docs/api/payment_methods/object#payment_method_object-au_becs_debit
public class STPPaymentMethodAUBECSDebit: NSObject, STPAPIResponseDecodable {
  /// :nodoc:
  private(set) public var allResponseFields: [AnyHashable: Any] = [:]

  /// Six-digit number identifying bank and branch associated with this bank account.
  @objc public private(set) var bsbNumber: String?
  /// Uniquely identifies this particular bank account. You can use this attribute to check whether two bank accounts are the same.
  @objc public private(set) var fingerprint: String?
  /// Last four digits of the bank account number.
  @objc public private(set) var last4: String?

  // MARK: - Description
  /// :nodoc:
  @objc public override var description: String {
    let props = [
      // Object
      String(format: "%@: %p", NSStringFromClass(STPPaymentMethodAUBECSDebit.self), self),
      // AU BECS Debit details
      "bsbNumber = \(bsbNumber ?? "")",
      "fingerprint = \(fingerprint ?? "")",
      "last4 = \(last4 ?? "")",
    ]

    return "<\(props.joined(separator: "; "))>"
  }

  // MARK: - STPAPIResponseDecodable
  public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
    guard let response = response else {
      return nil
    }
    let dict = (response as NSDictionary).stp_dictionaryByRemovingNulls()

    return self.init(dictionary: dict)
  }

  required init?(dictionary dict: [AnyHashable: Any]) {
    super.init()

    let nsDict = dict as NSDictionary
    bsbNumber = nsDict.stp_string(forKey: "bsb_number")
    fingerprint = nsDict.stp_string(forKey: "fingerprint")
    last4 = nsDict.stp_string(forKey: "last4")

    if bsbNumber == nil || fingerprint == nil || last4 == nil {
      return nil
    }

    allResponseFields = dict
  }
}
