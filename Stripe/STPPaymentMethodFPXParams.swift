//
//  STPPaymentMethodFPXParams.swift
//  Stripe
//
//  Created by David Estes on 7/30/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation

/// An object representing parameters used to create an FPX Payment Method
public class STPPaymentMethodFPXParams: NSObject, STPFormEncodable {
  @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]

  /// The customer's bank. Required.

  @objc public var bank: STPFPXBankBrand {
    get {
      return STPFPXBank.brandFrom(rawBankString)
    }
    set(_bank) {
      // If setting unknown and we're already unknown, don't want to override raw value
      if _bank != self.bank {
        rawBankString = STPFPXBank.identifierFrom(_bank)
      }
    }
  }
  /// The raw underlying bank string sent to the server.
  /// Generally you should use `bank` instead unless you have a reason not to.
  /// You can use this if you want to create a param of a bank not yet supported
  /// by the current version of the SDK's `STPFPXBankBrand` enum.
  /// Setting this to a value not known by the SDK causes `bank` to
  /// return `STPFPXBankBrandUnknown`
  @objc public var rawBankString: String?

  // MARK: - STPFormEncodable

  class func rootObjectName() -> String? {
    return "fpx"
  }

  class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
    return [
      NSStringFromSelector(#selector(getter:rawBankString)): "bank"
    ]
  }
}
