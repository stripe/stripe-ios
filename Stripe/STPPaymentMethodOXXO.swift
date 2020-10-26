//
//  STPPaymentMethodOXXO.swift
//  Stripe
//
//  Created by Polo Li on 6/15/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation

/// An OXXO Payment Method.
/// - seealso: https://stripe.com/docs/payments/oxxo
public class STPPaymentMethodOXXO: NSObject, STPAPIResponseDecodable {
  @objc public private(set) var allResponseFields: [AnyHashable: Any] = [:]

  /// :nodoc:
  @objc public override var description: String {
    let props = [
      // Object
      String(format: "%@: %p", NSStringFromClass(STPPaymentMethodOXXO.self), self),
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
    let oxxo = self.init()
    oxxo.allResponseFields = response
    return oxxo
  }
}
