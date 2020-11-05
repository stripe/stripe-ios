//
//  STPPaymentMethodCardWallet.swift
//  Stripe
//
//  Created by Yuki Tokuhiro on 3/9/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation

/// The type of Card Wallet.
@objc
public enum STPPaymentMethodCardWalletType: Int {
  /// Amex Express Checkout
  case amexExpressCheckout
  /// Apple Pay
  case applePay
  /// Google Pay
  case googlePay
  /// Masterpass
  case masterpass
  /// Samsung Pay
  case samsungPay
  /// Visa Checkout
  case visaCheckout
  /// An unknown Card Wallet type.
  case unknown
}

/// A Card Wallet.
/// - seealso: https://stripe.com/docs/api/payment_methods/object#payment_method_object-card-wallet
public class STPPaymentMethodCardWallet: NSObject, STPAPIResponseDecodable {
  /// The type of the Card Wallet. A matching property is populated if the type is `STPPaymentMethodCardWalletTypeMasterpass` or `STPPaymentMethodCardWalletTypeVisaCheckout` containing additional information specific to the Card Wallet type.
  @objc public private(set) var type: STPPaymentMethodCardWalletType = .unknown
  /// Contains additional Masterpass information, if the type of the Card Wallet is `STPPaymentMethodCardWalletTypeMasterpass`
  @objc public private(set) var masterpass: STPPaymentMethodCardWalletMasterpass?
  /// Contains additional Visa Checkout information, if the type of the Card Wallet is `STPPaymentMethodCardWalletTypeVisaCheckout`
  @objc public private(set) var visaCheckout: STPPaymentMethodCardWalletVisaCheckout?
  @objc public private(set) var allResponseFields: [AnyHashable: Any] = [:]

  /// :nodoc:
  @objc public override var description: String {
    let props = [
      // Object
      String(format: "%@: %p", NSStringFromClass(STPPaymentMethodCardWallet.self), self),
      // Properties
      "masterpass: \(String(describing: masterpass))",
      "visaCheckout: \(String(describing: visaCheckout))",
    ]
    return "<\(props.joined(separator: "; "))>"
  }

  // MARK: - STPPaymentMethodCardWalletType
  class func stringToTypeMapping() -> [String: NSNumber] {
    return [
      "amex_express_checkout": NSNumber(
        value: STPPaymentMethodCardWalletType.amexExpressCheckout.rawValue),
      "apple_pay": NSNumber(value: STPPaymentMethodCardWalletType.applePay.rawValue),
      "google_pay": NSNumber(value: STPPaymentMethodCardWalletType.googlePay.rawValue),
      "masterpass": NSNumber(value: STPPaymentMethodCardWalletType.masterpass.rawValue),
      "samsung_pay": NSNumber(value: STPPaymentMethodCardWalletType.samsungPay.rawValue),
      "visa_checkout": NSNumber(value: STPPaymentMethodCardWalletType.visaCheckout.rawValue),
    ]
  }

  @objc(typeFromString:)
  class func type(from string: String) -> STPPaymentMethodCardWalletType {
    let key = string.lowercased()
    let typeNumber = self.stringToTypeMapping()[key]

    if let typeNumber = typeNumber {
      return (STPPaymentMethodCardWalletType(rawValue: typeNumber.intValue))!
    }

    return .unknown
  }

  // MARK: - STPAPIResponseDecodable
  override required init() {
    super.init()
  }

  public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
    guard let response = response else {
      return nil
    }
    let dict = (response as NSDictionary).stp_dictionaryByRemovingNulls() as NSDictionary
    let wallet = self.init()
    wallet.allResponseFields = response
    wallet.type = self.type(from: dict.stp_string(forKey: "type") ?? "")
    wallet.visaCheckout = STPPaymentMethodCardWalletVisaCheckout.decodedObject(
      fromAPIResponse: dict.stp_dictionary(forKey: "visa_checkout"))
    wallet.masterpass = STPPaymentMethodCardWalletMasterpass.decodedObject(
      fromAPIResponse: dict.stp_dictionary(forKey: "masterpass"))
    return wallet
  }
}

//
//  STPPaymentMethodCardWallet+Private.h
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 3/9/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

extension STPPaymentMethodCardWallet {
}
