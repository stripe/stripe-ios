//
//  STPMandateDataParams.swift
//  Stripe
//
//  Created by Cameron Sabol on 10/17/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation

/// This object contains details about the Mandate to create. - seealso: https://stripe.com/docs/api/payment_intents/confirm#confirm_payment_intent-mandate_data
public class STPMandateDataParams: NSObject {

  /// Details about the customer acceptance of the Mandate.
  @objc public let customerAcceptance: STPMandateCustomerAcceptanceParams

  @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]

  /// Initializes an STPMandateDataParams from an STPMandateCustomerAcceptanceParams.
  @objc public init(customerAcceptance: STPMandateCustomerAcceptanceParams) {
    self.customerAcceptance = customerAcceptance
    super.init()
  }
}

extension STPMandateDataParams: STPFormEncodable {
  @objc
  public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
    return [
      NSStringFromSelector(#selector(getter:customerAcceptance)): "customer_acceptance"
    ]
  }

  @objc
  public class func rootObjectName() -> String? {
    return "mandate_data"
  }
}
