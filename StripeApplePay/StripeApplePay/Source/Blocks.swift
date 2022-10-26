//
//  Blocks.swift
//  StripeApplePay
//
//  Created by David Estes on 1/6/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

/// An empty block, called with no arguments, returning nothing.
public typealias STPVoidBlock = () -> Void

/// A block to be run with the client secret of a PaymentIntent or SetupIntent.
/// - Parameters:
///   - clientSecret:    The client secret of the PaymentIntent or SetupIntent. See https://stripe.com/docs/api/payment_intents/object#payment_intent_object-client_secret
///   - error:                    The error that occurred when creating the Intent, or nil if none occurred.
public typealias STPIntentClientSecretCompletionBlock = (String?, Error?) -> Void
