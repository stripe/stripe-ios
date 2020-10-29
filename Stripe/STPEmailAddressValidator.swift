//
//  STPEmailAddressValidator.swift
//  Stripe
//
//  Created by Jack Flintermann on 3/23/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import Foundation

class STPEmailAddressValidator: NSObject {
  class func stringIsValidPartialEmailAddress(_ string: String?) -> Bool {
    guard let string = string else {
      return true // an empty string isn't *invalid*
    }
    return (string.components(separatedBy: "@").count - 1) <= 1
  }

  class func stringIsValidEmailAddress(_ string: String?) -> Bool {
    if string == nil {
      return false
    }
    // regex from http://www.regular-expressions.info/email.html
    let pattern =
      "[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?"
    let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
    return predicate.evaluate(with: string?.lowercased())
  }
}
