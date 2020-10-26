//
//  STPPaymentMethodiDEAL.swift
//  Stripe
//
//  Created by Yuki Tokuhiro on 3/9/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation

/// An iDEAL Payment Method.
/// - seealso: https://stripe.com/docs/api/payment_methods/object#payment_method_object-ideal
public class STPPaymentMethodiDEAL: NSObject, STPAPIResponseDecodable {
  /// The customer’s bank.
  @objc public private(set) var bankName: String?
  /// The Bank Identifier Code of the customer’s bank.
  @objc public private(set) var bankIdentifierCode: String?
  @objc public private(set) var allResponseFields: [AnyHashable: Any] = [:]

  /// :nodoc:
  @objc public override var description: String {
    let props = [
      // Object
      String(format: "%@: %p", NSStringFromClass(STPPaymentMethodiDEAL.self), self),
      // Properties
      "bank: \(bankName ?? "")",
      "bic: \(bankIdentifierCode ?? "")",
    ]

    return "<\(props.joined(separator: "; "))>"
  }

  // MARK: - STPAPIResponseDecodable
  override required init() {
    super.init()
  }

  @objc
  public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
    guard let response = response else {
      return nil
    }
    let dict = (response as NSDictionary).stp_dictionaryByRemovingNulls() as NSDictionary

    let ideal = self.init()
    ideal.allResponseFields = response
    ideal.bankName = dict.stp_string(forKey: "bank")
    ideal.bankIdentifierCode = dict.stp_string(forKey: "bic")
    return ideal
  }
}
