//
//  STPPaymentMethodEnums.swift
//  Stripe
//
//  Created by Yuki Tokuhiro on 3/12/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation

/// The type of the PaymentMethod.
@objc public enum STPPaymentMethodType: Int {
  /// A card payment method.
  case card
  /// An Alipay payment method.
  case alipay
  /// A GrabPay payment method.
  case grabPay
  /// An iDEAL payment method.
  @objc(STPPaymentMethodTypeiDEAL) case iDEAL
  /// An FPX payment method.
  case FPX
  /// A card present payment method.
  case cardPresent
  /// A SEPA Debit payment method.
  @objc(STPPaymentMethodTypeSEPADebit) case SEPADebit
  /// An AU BECS Debit payment method.
  @objc(STPPaymentMethodTypeAUBECSDebit) case AUBECSDebit
  /// A Bacs Debit payment method.
  case bacsDebit
  /// A giropay payment method.
  case giropay
  /// A Przelewy24 Debit payment method.
  case przelewy24
  /// An EPS payment method.
  @objc(STPPaymentMethodTypeEPS) case EPS
  /// A Bancontact payment method.
  case bancontact
  /// An OXXO payment method.
  @objc(STPPaymentMethodTypeOXXO) case oxxo
  /// A Sofort payment method.
  case sofort
  /// A PayPal payment method. :nodoc:
  case payPal
  /// An unknown type.
  case unknown
}
