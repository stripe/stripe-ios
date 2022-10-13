//
//  STPPaymentIntentSourceActionAuthorizeWithURL.swift
//  Stripe
//
//  Created by Daniel Jackson on 11/7/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

import Foundation

/// The `STPPaymentIntentSourceAction` details when type is `STPPaymentIntentSourceActionTypeAuthorizeWithURL`.
/// These are created & owned by the containing `STPPaymentIntent`.
/// @deprecated Use `STPIntentActionRedirectToURL` instead.
@available(
    *, unavailable, message: "Use `STPIntentActionRedirectToURL` instead.",
    renamed: "STPIntentActionRedirectToURL"
)
@objc public final class STPPaymentIntentSourceActionAuthorizeWithURL: STPIntentActionRedirectToURL
{}
