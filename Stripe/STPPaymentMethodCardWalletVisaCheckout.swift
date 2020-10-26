//
//  STPPaymentMethodCardWalletVisaCheckout.swift
//  Stripe
//
//  Created by Yuki Tokuhiro on 3/9/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation

/// A Visa Checkout Card Wallet
/// - seealso: https://stripe.com/docs/visa-checkout
public class STPPaymentMethodCardWalletVisaCheckout: NSObject, STPAPIResponseDecodable {
  /// Owner’s verified email. Values are verified or provided by the payment method directly (and if supported) at the time of authorization or settlement.
  @objc public private(set) var email: String?
  /// Owner’s verified email. Values are verified or provided by the payment method directly (and if supported) at the time of authorization or settlement.
  @objc public private(set) var name: String?
  /// Owner’s verified billing address. Values are verified or provided by the payment method directly (and if supported) at the time of authorization or settlement.
  @objc public private(set) var billingAddress: STPPaymentMethodAddress?
  /// Owner’s verified shipping address. Values are verified or provided by the payment method directly (and if supported) at the time of authorization or settlement.
  @objc public private(set) var shippingAddress: STPPaymentMethodAddress?
  private(set) public var allResponseFields: [AnyHashable: Any] = [:]

  override required init() {
    super.init()
  }

  // MARK: - STPAPIResponseDecodable
  public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
    guard let response = response else {
      return nil
    }
    let dict = (response as NSDictionary).stp_dictionaryByRemovingNulls() as NSDictionary

    let visaCheckout = self.init()
    visaCheckout.allResponseFields = response
    visaCheckout.billingAddress = STPPaymentMethodAddress.decodedObject(
      fromAPIResponse: dict.stp_dictionary(forKey: "billing_address"))
    visaCheckout.shippingAddress = STPPaymentMethodAddress.decodedObject(
      fromAPIResponse: dict.stp_dictionary(forKey: "shipping_address"))
    visaCheckout.email = dict.stp_string(forKey: "email")
    visaCheckout.name = dict.stp_string(forKey: "name")
    return visaCheckout
  }
}
