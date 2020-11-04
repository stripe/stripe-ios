//
//  STPPaymentOption.swift
//  Stripe
//
//  Created by Ben Guo on 4/19/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import UIKit

/// This protocol represents a payment method that a user can select and use to
/// pay.
/// The classes that conform to it and are supported by the UI:
/// - `STPApplePay`, which represents that the user wants to pay with
/// Apple Pay
/// - `STPPaymentMethod`.  Only `STPPaymentMethod.type == STPPaymentMethodTypeCard` and
/// `STPPaymentMethod.type == STPPaymentMethodTypeFPX` are supported by `STPPaymentContext`
/// and `STPPaymentOptionsViewController`
/// - `STPPaymentMethodParams`. This should be used with non-reusable payment method, such
/// as FPX and iDEAL. Instead of reaching out to Stripe to create a PaymentMethod, you can
/// pass an STPPaymentMethodParams directly to Stripe when confirming a PaymentIntent.
/// @note card-based Sources, Cards, and FPX support this protocol for use
/// in a custom integration.
@objc public protocol STPPaymentOption: NSObjectProtocol {
  /// A small (32 x 20 points) logo image representing the payment method. For
  /// example, the Visa logo for a Visa card, or the Apple Pay logo.
  var image: UIImage { get }
  /// A small (32 x 20 points) logo image representing the payment method that can be
  /// used as template for tinted icons.
  var templateImage: UIImage { get }
  /// A string describing the payment method, such as "Apple Pay" or "Visa 4242".
  var label: String { get }
  /// Describes whether this payment option may be used multiple times. If it is not reusable,
  /// the payment method must be discarded after use.
  var isReusable: Bool { get }
}
