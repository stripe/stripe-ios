//
//  STPPaymentIntentEnums.swift
//  Stripe
//
//  Created by Daniel Jackson on 6/27/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

import Foundation

/// Status types for an STPPaymentIntent
@objc public enum STPPaymentIntentStatus: Int {
  /// Unknown status
  case unknown
  /// This PaymentIntent requires a PaymentMethod or Source
  case requiresPaymentMethod
  /// This PaymentIntent requires a Source
  /// Deprecated: Use STPPaymentIntentStatusRequiresPaymentMethod instead.
  @available(
    *, deprecated, message: "Use STPPaymentIntentStatus.requiresPaymentMethod instead",
    renamed: "STPPaymentIntentStatus.requiresPaymentMethod"
  )
  case requiresSource
  /// This PaymentIntent needs to be confirmed
  case requiresConfirmation
  /// The selected PaymentMethod or Source requires additional authentication steps.
  /// Additional actions found via `next_action`
  case requiresAction
  /// The selected Source requires additional authentication steps.
  /// Additional actions found via `next_source_action`
  /// Deprecated: Use STPPaymentIntentStatusRequiresAction instead.
  @available(
    *, deprecated, message: "Use STPPaymentIntentStatus.requiresAction instead",
    renamed: "STPPaymentIntentStatus.requiresAction"
  )
  case requiresSourceAction
  /// Stripe is processing this PaymentIntent
  case processing
  /// The payment has succeeded
  case succeeded
  /// Indicates the payment must be captured, for STPPaymentIntentCaptureMethodManual
  case requiresCapture
  /// This PaymentIntent was canceled and cannot be changed.
  case canceled
}

/// Indicates how you intend to use the payment method that your customer provides after the current payment completes.
/// If applicable, additional authentication may be performed to comply with regional legislation or network rules required to enable the usage of the same payment method for additional payments.
/// - seealso: https://stripe.com/docs/api/payment_intents/object#payment_intent_object-setup_future_usage
@objc public enum STPPaymentIntentSetupFutureUsage: Int {
  /// Unknown value.  Update your SDK, or use `allResponseFields` for custom handling.
  case unknown
  /// No value was provided.
  case none
  /// Indicates you intend to only reuse the payment method when the customer is in your checkout flow.
  case onSession
  /// Indicates you intend to reuse the payment method when the customer may or may not be in your checkout flow.
  case offSession

  /// Parse the string and return the correct `STPPaymentIntentSetupFutureUsage`,
  /// or `STPPaymentIntentSetupFutureUsageUnknown` if it's unrecognized by this version of the SDK.
  /// - Parameter string: the NSString with the setup future usage value
  internal init(string: String) {
    let map: [String: STPPaymentIntentSetupFutureUsage] = [
      "on_session": .onSession,
      "off_session": .offSession,
    ]

    let key = string.lowercased()
    self = map[key] ?? .unknown
  }

  var stringValue: String? {
    switch self {
    case .onSession:
      return "on_session"
    case .offSession:
      return "off_session"
    case .none, .unknown:
      return nil
    }
  }
}

// MARK: - Deprecated
/// Types of Actions from a `STPPaymentIntent`, when the payment intent
/// status is `STPPaymentIntentStatusRequiresAction`.
@objc public enum STPPaymentIntentActionType: Int {
  /// This is an unknown action, that's been added since the SDK
  /// was last updated.
  /// Update your SDK, or use the `nextAction.allResponseFields`
  /// for custom handling.
  @available(
    *, deprecated, message: "Use STPIntentActionType instead",
    renamed: "STPIntentActionType.unknown"
  )
  case unknown
  /// The payment intent needs to be authorized by the user. We provide
  /// `STPRedirectContext` to handle the url redirections necessary.
  @available(
    *, deprecated, message: "Use STPIntentActionType instead",
    renamed: "STPIntentActionType.redirectToURL"
  )
  case redirectToURL
}

/// Types of Source Actions from a `STPPaymentIntent`, when the payment intent
/// status is `STPPaymentIntentStatusRequiresSourceAction`.
/// @deprecated Use`STPPaymentIntentActionType` instead.
@available(
  *, deprecated, message: "Use STPIntentActionType instead", renamed: "STPIntentActionType"
)
@objc public enum STPPaymentIntentSourceActionType: Int {
  /// This is an unknown source action, that's been added since the SDK
  /// was last updated.
  /// Update your SDK, or use the `nextSourceAction.allResponseFields`
  /// for custom handling.
  case unknown
  /// The payment intent needs to be authorized by the user. We provide
  /// `STPRedirectContext` to handle the url redirections necessary.
  case authorizeWithURL
}
