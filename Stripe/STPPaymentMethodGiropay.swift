//
//  STPPaymentMethodGiropay.swift
//  Stripe
//
//  Created by Cameron Sabol on 4/21/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation

/// A giropay Payment Method.
/// - seealso: https://stripe.com/docs/api/payment_methods/object#payment_method_object-giropay
public class STPPaymentMethodGiropay: NSObject, STPAPIResponseDecodable {
  public var allResponseFields: [AnyHashable: Any] = [:]

  // MARK: - Description
  /// :nodoc:
  @objc public override var description: String {
    let props = [
      // Object
      String(format: "%@: %p", NSStringFromClass(STPPaymentMethodGiropay.self), self)
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
  }
}
