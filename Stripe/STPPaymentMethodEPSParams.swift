//
//  STPPaymentMethodEPSParams.swift
//  StripeiOS
//
//  Created by Shengwei Wu on 5/14/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation

/// An object representing parameters used to create a EPS Payment Method
public class STPPaymentMethodEPSParams: NSObject, STPFormEncodable {
  var additionalAPIParameters: [AnyHashable: Any] = [:]

  class func rootObjectName() -> String? {
    return "eps"
  }

  class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
    return [:]
  }
}
