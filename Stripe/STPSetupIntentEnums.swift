//
//  STPSetupIntentEnums.swift
//  Stripe
//
//  Created by Yuki Tokuhiro on 6/27/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation

/// Status types for an STPSetupIntent
@objc public enum STPSetupIntentStatus: Int {
  /// Unknown status
  case unknown
  /// This SetupIntent requires a PaymentMethod
  case requiresPaymentMethod
  /// This SetupIntent needs to be confirmed
  case requiresConfirmation
  /// The selected PaymentMethod requires additional authentication steps.
  /// Additional actions found via the `nextAction` property of `STPSetupIntent`
  case requiresAction
  /// Stripe is processing this SetupIntent
  case processing
  /// The SetupIntent has succeeded
  case succeeded
  /// This SetupIntent was canceled and cannot be changed.
  case canceled
}

/// Indicates how the payment method is intended to be used in the future.
/// - seealso: https://stripe.com/docs/api/setup_intents/create#create_setup_intent-usage
@objc public enum STPSetupIntentUsage: Int {
  /// Unknown value.  Update your SDK, or use `allResponseFields` for custom handling.
  case unknown
  /// No value was provided.
  case none
  /// Indicates you intend to only reuse the payment method when the customer is in your checkout flow.
  case onSession
  /// Indicates you intend to reuse the payment method when the customer may or may not be in your checkout flow.
  case offSession
}
