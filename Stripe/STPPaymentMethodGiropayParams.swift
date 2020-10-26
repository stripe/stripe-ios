//
//  STPPaymentMethodGiropayParams.swift
//  Stripe
//
//  Created by Cameron Sabol on 4/21/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation

/// An object representing parameters used to create a giropay Payment Method
public class STPPaymentMethodGiropayParams: NSObject, STPFormEncodable {
  @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]

  class func rootObjectName() -> String? {
    return "giropay"
  }

  class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
    return [:]
  }
}
