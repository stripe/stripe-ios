//
//  STPPaymentIntentSourceAction.swift
//  StripePayments
//
//  Created by Daniel Jackson on 11/7/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

import Foundation

/// Source Action details for an STPPaymentIntent. This is a container for
/// the various types that are available. Check the `type` to see which one
/// it is, and then use the related property for the details necessary to handle
/// it.
/// @deprecated Use `STPIntentAction` instead.
@available(*, unavailable, message: "Use `STPIntentAction` instead.", renamed: "STPIntentAction")
@objc public final class STPPaymentIntentSourceAction: STPIntentAction {}
