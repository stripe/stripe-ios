//
//  STPPaymentMethodBancontactParams.swift
//  StripeiOS
//
//  Created by Vineet Shah on 4/29/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation

/// An object representing parameters used to create a Bancontact Payment Method
public class STPPaymentMethodBancontactParams: NSObject, STPFormEncodable {
  var additionalAPIParameters: [AnyHashable: Any] = [:]

  class func rootObjectName() -> String? {
    return "bancontact"
  }

  class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
    return [:]
  }
}
