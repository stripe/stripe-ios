//
//  STPPaymentMethodCardChecks.swift
//  Stripe
//
//  Created by Yuki Tokuhiro on 3/5/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation

/// The result of a check on a Card address or CVC.
@objc
public enum STPPaymentMethodCardCheckResult: Int {
  /// The check passed.
  case pass
  /// The check failed.
  case failed
  /// The check is unavailable.
  case unavailable
  /// The value was not checked.
  case unchecked
  /// Represents an unknown or null value.
  case unknown
}

/// Checks on Card address and CVC.
/// - seealso: https://stripe.com/docs/api/payment_methods/object#payment_method_object-card-checks
public class STPPaymentMethodCardChecks: NSObject, STPAPIResponseDecodable {
  override required init() {
    super.init()
  }

  // MARK: - Deprecated
  // TODO(swift): Figure out deprecation strategy
  /// If a address line1 was provided, results of the check.
  @available(*, deprecated, message: "Card check values are no longer returned to clients using publishable keys. Retrieve them on your server using your secret key instead.")
  @objc public private(set) var addressLine1Check: STPPaymentMethodCardCheckResult = .unknown
  /// If a address postal code was provided, results of the check.
  /// deprecated Card check values are no longer returned to clients using publishable keys. Retrieve them on your server using yoursecret key instead.
  @available(*, deprecated, message: "Card check values are no longer returned to clients using publishable keys. Retrieve them on your server using your secret key instead.")
  @objc public private(set) var addressPostalCodeCheck: STPPaymentMethodCardCheckResult = .unknown
  /// If a CVC was provided, results of the check.
  /// deprecated Card check values are no longer returned to clients using publishable keys. Retrieve them on your server using yoursecret key instead.
  @available(*, deprecated, message: "Card check values are no longer returned to clients using publishable keys. Retrieve them on your server using your secret key instead.")
  @objc public private(set) var cvcCheck: STPPaymentMethodCardCheckResult = .unknown
  @objc private(set) public var allResponseFields: [AnyHashable: Any] = [:]

  /// :nodoc:
  @objc public override var description: String {
    let props = [
      // Object
      String(format: "%@: %p", NSStringFromClass(STPPaymentMethodCardChecks.self), self),
      // Properties
      "addressLine1Check: \(allResponseFields["address_line1_check"] ?? "")",
      "addressPostalCodeCheck: \(allResponseFields["address_postal_code_check"] ?? "")",
      "cvcCheck: \(allResponseFields["cvc_check"] ?? "")",
    ]

    return "<\(props.joined(separator: "; "))>"
  }

  @objc(checkResultFromString:)
  class func checkResult(from string: String?) -> STPPaymentMethodCardCheckResult {
    let check = string?.lowercased()
    if check == "pass" {
      return .pass
    } else if check == "failed" {
      return .failed
    } else if check == "unavailable" {
      return .unavailable
    } else if check == "unchecked" {
      return .unchecked
    } else {
      return .unknown
    }
  }

  // MARK: - STPAPIResponseDecodable
  public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
    guard let response = response else {
      return nil
    }
    let cardChecks = self.init()
    cardChecks.allResponseFields = response
    return cardChecks
  }
}
