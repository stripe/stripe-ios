//
//  STPPaymentMethodUpi.swift
//  StripeiOS
//
//  Created by Anirudh Bhargava on 11/6/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation

/// A Upi Payment Method.
/// - seealso: https://stripe.com/docs/api/payment_methods/object#payment_method_object-upi
public class STPPaymentMethodUpi: NSObject, STPAPIResponseDecodable {
  @objc private(set) public var allResponseFields: [AnyHashable: Any] = [:]

  /// Customer’s Virtual Payment Address (VPA).
  @objc public private(set) var vpa: String?

  // MARK: - Description
  /// :nodoc:
  @objc public override var description: String {
    let props = [
      // Object
      String(format: "%@: %p", NSStringFromClass(STPPaymentMethodUpi.self), self),
      "vpa = \(vpa ?? "")",
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
    vpa = dict.stp_string(forKey: "vpa")
  }
}
