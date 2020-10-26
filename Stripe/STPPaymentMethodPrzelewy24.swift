//
//  STPPaymentMethodPrzelewy24.swift
//  StripeiOS
//
//  Created by Vineet Shah on 4/23/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation

/// A Przelewy24 Payment Method.
/// - seealso: https://stripe.com/docs/payments/p24
public class STPPaymentMethodPrzelewy24: NSObject, STPAPIResponseDecodable {
  @objc public var allResponseFields: [AnyHashable: Any] = [:]

  // MARK: - Description
  /// :nodoc:
  @objc public override var description: String {
    let props = [
      // Object
      String(format: "%@: %p", NSStringFromClass(STPPaymentMethodPrzelewy24.self), self)
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
  }
}
