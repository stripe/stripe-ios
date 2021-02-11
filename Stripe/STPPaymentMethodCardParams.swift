//
//  STPPaymentMethodCardParams.swift
//  Stripe
//
//  Created by Yuki Tokuhiro on 3/6/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation

/// The user's card details.
public class STPPaymentMethodCardParams: NSObject, STPFormEncodable {
  @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]

  /// A convenience initializer for creating a payment method from a card source.
  /// This should be used to help with migrations to Payment Methods from Sources.
  @objc public convenience init(cardSourceParams: STPCardParams) {
    self.init()
    number = cardSourceParams.number
    expMonth = NSNumber(value: cardSourceParams.expMonth)
    expYear = NSNumber(value: cardSourceParams.expYear)
    cvc = cardSourceParams.cvc
  }

  /// Initializes an empty STPPaymentMethodCardParams.
  public required override init() {
    super.init()
  }

  /// The card number, as a string without any separators. Ex. @"4242424242424242"
  @objc public var number: String?
  /// Number representing the card's expiration month. Ex. @1
  @objc public var expMonth: NSNumber?
  /// Two- or four-digit number representing the card's expiration year.
  @objc public var expYear: NSNumber?
  /// For backwards compatibility, you can alternatively set this as a Stripe token (e.g., for apple pay)
  @objc public var token: String?
  /// Card security code. It is highly recommended to always include this value.
  @objc public var cvc: String?
  /// The last 4 digits of the card.

  @objc public var last4: String? {
    if number != nil && (number?.count ?? 0) >= 4 {
      return (number as NSString?)?.substring(from: (number?.count ?? 0) - 4) ?? ""
    } else {
      return ""
    }
  }

  // MARK: - Description
  /// :nodoc:
  @objc public override var description: String {
    let props = [
      // Object
      String(format: "%@: %p", NSStringFromClass(STPPaymentMethodCardParams.self), self),
      // Basic card details
      "last4 = \(last4 ?? "")",
      "expMonth = \(expMonth ?? 0)",
      "expYear = \(expYear ?? 0)",
      "cvc = \(((cvc) != nil ? "<redacted>" : nil) ?? "")",
      // Token
      "token = \(token ?? "")",
    ]

    return "<\(props.joined(separator: "; "))>"
  }

  // MARK: - STPFormEncodable

  @objc
  public class func rootObjectName() -> String? {
    return "card"
  }

  @objc
  public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
    return [
      NSStringFromSelector(#selector(getter:number)): "number",
      NSStringFromSelector(#selector(getter:expMonth)): "exp_month",
      NSStringFromSelector(#selector(getter:expYear)): "exp_year",
      NSStringFromSelector(#selector(getter:cvc)): "cvc",
      NSStringFromSelector(#selector(getter:token)): "token",
    ]
  }

  // MARK: - NSCopying
  @objc(copyWithZone:) func copy(with zone: NSZone? = nil) -> Any {
    let copyCardParams = type(of: self).init()

    copyCardParams.number = number
    copyCardParams.expMonth = expMonth
    copyCardParams.expYear = expYear
    copyCardParams.cvc = cvc
    return copyCardParams
  }
  
  // MARK: - Equality
  /// :nodoc:
  @objc
  public override func isEqual(_ other: Any?) -> Bool {
    return isEqual(to: other as? STPPaymentMethodCardParams)
  }

  func isEqual(to other: STPPaymentMethodCardParams?) -> Bool {
    if self === other {
      return true
    }

    if other == nil || !(other != nil) {
      return false
    }
    
    if let other = other,
       !((additionalAPIParameters as NSDictionary).isEqual(to: other.additionalAPIParameters)) {
      return false
    }

    return number == other?.number &&
      expMonth == other?.expMonth &&
      expYear == other?.expYear &&
      cvc == other?.cvc &&
      token == other?.token
  }
}
