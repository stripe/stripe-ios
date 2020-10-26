//
//  STPPaymentMethodCardPresent.swift
//  Stripe
//
//  Created by Yuki Tokuhiro on 3/11/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation

/// Details about the Card Present payment method

public class STPPaymentMethodCardPresent: NSObject, STPAPIResponseDecodable {
  public private(set) var allResponseFields: [AnyHashable: Any] = [:]

  /// :nodoc:
  @objc public override var description: String {
    let props = [
      // Object
      String(format: "%@: %p", NSStringFromClass(STPPaymentMethodCardPresent.self), self)
    ]
    return "<\(props.joined(separator: "; "))>"
  }

  required override init() {
    super.init()
  }

  // MARK: - STPAPIResponseDecodable
  public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
    guard let dict = (response as NSDictionary?)?.stp_dictionaryByRemovingNulls() else {
      return nil
    }
    let cardPresent = self.init()
    cardPresent.allResponseFields = dict
    return cardPresent
  }
}
