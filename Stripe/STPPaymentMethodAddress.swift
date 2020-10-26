//
//  STPPaymentMethodAddress.swift
//  Stripe
//
//  Created by Yuki Tokuhiro on 3/5/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Contacts
import Foundation

/// The billing address, a property on `STPPaymentMethodBillingDetails`
public class STPPaymentMethodAddress: NSObject, STPAPIResponseDecodable, STPFormEncodable {
  @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]

  /// City/District/Suburb/Town/Village.
  @objc public var city: String?
  /// 2-letter country code.
  @objc public var country: String?
  /// Address line 1 (Street address/PO Box/Company name).
  @objc public var line1: String?
  /// Address line 2 (Apartment/Suite/Unit/Building).
  @objc public var line2: String?
  /// ZIP or postal code.
  @objc public var postalCode: String?
  /// State/County/Province/Region.
  @objc public var state: String?

  /// Convenience initializer for creating a STPPaymentMethodAddress from an STPAddress.
  @objc
  public init(address: STPAddress) {
    super.init()
    city = address.city
    country = address.country
    line1 = address.line1
    line2 = address.line2
    postalCode = address.postalCode
    state = address.state
  }

  /// :nodoc:
  @objc public required override init() {
    super.init()
  }

  /// :nodoc:
  private(set) public var allResponseFields: [AnyHashable: Any] = [:]

  /// :nodoc:
  @objc public override var description: String {
    let props = [
      // Object
      String(format: "%@: %p", NSStringFromClass(STPPaymentMethodAddress.self), self),
      // Properties
      "line1 = \(line1 ?? "")",
      "line2 = \(line2 ?? "")",
      "city = \(city ?? "")",
      "state = \(state ?? "")",
      "postalCode = \(postalCode ?? "")",
      "country = \(country ?? "")",
    ]

    return "<\(props.joined(separator: "; "))>"
  }

  // MARK: - STPFormEncodable

  @objc
  public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
    return [
      NSStringFromSelector(#selector(getter:line1)): "line1",
      NSStringFromSelector(#selector(getter:line2)): "line2",
      NSStringFromSelector(#selector(getter:city)): "city",
      NSStringFromSelector(#selector(getter:country)): "country",
      NSStringFromSelector(#selector(getter:state)): "state",
      NSStringFromSelector(#selector(getter:CNMutablePostalAddress.postalCode)): "postal_code",
    ]
  }

  @objc
  public class func rootObjectName() -> String? {
    return nil
  }

  // MARK: - STPAPIResponseDecodable
  @objc
  public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
    guard let response = response else {
      return nil
    }
    let dict = (response as NSDictionary).stp_dictionaryByRemovingNulls() as NSDictionary
    let address = self.init()
    address.allResponseFields = response
    address.city = dict.stp_string(forKey: "city")
    address.country = dict.stp_string(forKey: "country")
    address.line1 = dict.stp_string(forKey: "line1")
    address.line2 = dict.stp_string(forKey: "line2")
    address.postalCode = dict.stp_string(forKey: "postal_code")
    address.state = dict.stp_string(forKey: "state")
    return address
  }
}
