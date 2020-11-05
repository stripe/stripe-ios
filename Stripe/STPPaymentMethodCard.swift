//
//  STPPaymentMethodCard.swift
//  Stripe
//
//  Created by Yuki Tokuhiro on 3/5/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation

/// Contains details about a user's credit card.
/// - seealso: https://stripe.com/docs/api/payment_methods/object#payment_method_object-card
public class STPPaymentMethodCard: NSObject, STPAPIResponseDecodable {
  /// You cannot directly instantiate an `STPPaymentMethodCard`. You should only use one that is part of an existing `STPPaymentMethod` object.
  required internal override init() {
    super.init()
  }

  /// The issuer of the card.
  @objc public private(set) var brand: STPCardBrand = .unknown
  /// Checks on Card address and CVC if provided.
  @objc public private(set) var checks: STPPaymentMethodCardChecks?
  /// Two-letter ISO code representing the country of the card.
  @objc public private(set) var country: String?
  /// Two-digit number representing the card’s expiration month.
  @objc public private(set) var expMonth = 0
  /// Four-digit number representing the card’s expiration year.
  @objc public private(set) var expYear = 0
  /// Card funding type. Can be credit, debit, prepaid, or unknown.
  @objc public private(set) var funding: String?
  /// The last four digits of the card.
  @objc public private(set) var last4: String?
  /// Uniquely identifies this particular card number. You can use this attribute to check whether two customers who’ve signed up with you are using the same card number, for example.
  @objc public private(set) var fingerprint: String?
  /// Contains information about card networks that can be used to process the payment.
  @objc public private(set) var networks: STPPaymentMethodCardNetworks?
  /// Contains details on how this Card maybe be used for 3D Secure authentication.
  @objc public private(set) var threeDSecureUsage: STPPaymentMethodThreeDSecureUsage?
  /// If this Card is part of a Card Wallet, this contains the details of the Card Wallet.
  @objc public private(set) var wallet: STPPaymentMethodCardWallet?

  /// Returns a string representation for the provided card brand;
  /// i.e. `STPPaymentMethodCard.string(from brand:.visa) == "Visa"`.
  /// - Parameter brand: the brand you want to convert to a string
  /// - Returns: A string representing the brand, suitable for displaying to a user.
  @objc(stringFromBrand:) public class func string(from brand: STPCardBrand) -> String {
    return STPCardBrandUtilities.stringFrom(brand) ?? ""
  }
  public private(set) var allResponseFields: [AnyHashable: Any] = [:]

  /// :nodoc:
  @objc public override var description: String {
    let props = [
      // Object
      String(format: "%@: %p", NSStringFromClass(STPPaymentMethodCard.self), self),
      "brand = \(STPCardBrandUtilities.stringFrom(brand) ?? "")",
      "checks = \(checks?.description ?? "")",
      "country = \(country ?? "")",
      String(format: "expMonth = %lu", UInt(expMonth)),
      String(format: "expYear = %lu", UInt(expYear)),
      "funding = \(funding ?? "")",
      "last4 = \(last4 ?? "")",
      "fingerprint = \(fingerprint ?? "")",
      "networks = \(networks?.description ?? "")",
      "threeDSecureUsage = \(threeDSecureUsage?.description ?? "")",
      "wallet = \(wallet?.description ?? "")",
    ]

    return "<\(props.joined(separator: "; "))>"
  }

  // MARK: - STPAPIResponseDecodable
  public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
    guard let response = response else {
      return nil
    }
    let dict = (response as NSDictionary).stp_dictionaryByRemovingNulls()

    let card = self.init()
    card.allResponseFields = response
    guard let nsDict = dict as NSDictionary? else {
      return nil
    }
    card.brand = self.brand(from: nsDict.stp_string(forKey: "brand") ?? "")
    card.checks = STPPaymentMethodCardChecks.decodedObject(
      fromAPIResponse: nsDict.stp_dictionary(forKey: "checks"))
    card.country = nsDict.stp_string(forKey: "country")
    card.expMonth = nsDict.stp_int(forKey: "exp_month", or: 0)
    card.expYear = nsDict.stp_int(forKey: "exp_year", or: 0)
    card.funding = nsDict.stp_string(forKey: "funding")
    card.last4 = nsDict.stp_string(forKey: "last4")
    card.fingerprint = nsDict.stp_string(forKey: "fingerprint")
    card.networks = STPPaymentMethodCardNetworks.decodedObject(
      fromAPIResponse: dict["networks"] as? [AnyHashable: Any])
    card.threeDSecureUsage = STPPaymentMethodThreeDSecureUsage.decodedObject(
      fromAPIResponse: nsDict.stp_dictionary(forKey: "three_d_secure_usage"))
    card.wallet = STPPaymentMethodCardWallet.decodedObject(
      fromAPIResponse: nsDict.stp_dictionary(forKey: "wallet"))
    return card
  }

  // MARK: - STPCardBrand

  @objc(brandFromString:) class func brand(from string: String) -> STPCardBrand {
    // Documentation: https://stripe.com/docs/api/payment_methods/object#payment_method_object-card-brand
    let brand = string.lowercased()
    if brand == "visa" {
      return .visa
    } else if brand == "amex" {
      return .amex
    } else if brand == "mastercard" {
      return .mastercard
    } else if brand == "discover" {
      return .discover
    } else if brand == "jcb" {
      return .JCB
    } else if brand == "diners" {
      return .dinersClub
    } else if brand == "unionpay" {
      return .unionPay
    } else {
      return .unknown
    }
  }
}
