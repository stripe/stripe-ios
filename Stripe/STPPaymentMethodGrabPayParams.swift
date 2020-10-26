//
//  STPPaymentMethodGrabPayParams.swift
//  Stripe
//
//  Created by Yuki Tokuhiro on 7/21/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation

/// An object representing parameters used to create a GrabPay Payment Method
public class STPPaymentMethodGrabPayParams: NSObject, STPFormEncodable {
  var additionalAPIParameters: [AnyHashable: Any] = [:]

  // MARK: - STPFormEncodable
  class func rootObjectName() -> String? {
    return "grabpay"
  }

  class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
    return [:]
  }
}
