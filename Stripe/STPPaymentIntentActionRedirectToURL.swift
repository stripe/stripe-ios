//
//  STPPaymentIntentActionRedirectToURL.swift
//  Stripe
//
//  Created by Yuki Tokuhiro on 3/8/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation

/// Contains instructions for authenticating a payment by redirecting your customer to another page or application.
/// @deprecated Use `STPIntentActionRedirectToURL` instead.
@available(
  *, unavailable, message: "Use `STPIntentActionRedirectToURL` instead.",
  renamed: "STPIntentActionRedirectToURL"
)
@objc public final class STPPaymentIntentActionRedirectToURL: STPIntentActionRedirectToURL {}
