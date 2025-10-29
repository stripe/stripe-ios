//
//  PaymentIntent.swift
//  StripeApplePay
//
//  Created by David Estes on 6/29/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

extension StripeAPI {
    @_spi(STP) public struct PaymentIntent: UnknownFieldsDecodable {
        // TODO: (MOBILESDK-468) Add modern bindings for more PaymentIntent fields
        /// The Stripe ID of the PaymentIntent.
        @_spi(STP) public let id: String

        /// The client secret used to fetch this PaymentIntent
        @_spi(STP) public let clientSecret: String

        /// Amount intended to be collected by this PaymentIntent.
        @_spi(STP) public let amount: Int

        /// If status is `.canceled`, when the PaymentIntent was canceled.
        @_spi(STP) public let canceledAt: Date?

        /// Capture method of this PaymentIntent
        @_spi(STP) public let captureMethod: CaptureMethod

        /// Confirmation method of this PaymentIntent
        @_spi(STP) public let confirmationMethod: ConfirmationMethod

        /// When the PaymentIntent was created.
        @_spi(STP) public let created: Date

        /// The currency associated with the PaymentIntent.
        @_spi(STP) public let currency: String

        /// The `description` field of the PaymentIntent.
        /// An arbitrary string attached to the object. Often useful for displaying to users.
        @_spi(STP) public let stripeDescription: String?

        /// Whether or not this PaymentIntent was created in livemode.
        @_spi(STP) public let livemode: Bool

        /// Email address that the receipt for the resulting payment will be sent to.
        @_spi(STP) public let receiptEmail: String?

        /// The Stripe ID of the Source used in this PaymentIntent.
        @_spi(STP) public let sourceId: String?

        /// The Stripe ID of the PaymentMethod used in this PaymentIntent.
        @_spi(STP) public let paymentMethodId: String?

        /// Status of the PaymentIntent
        @_spi(STP) public let status: Status

        /// Shipping information for this PaymentIntent.
        @_spi(STP) public let shipping: ShippingDetails?

        /// Status types for a PaymentIntent
        @frozen @_spi(STP) public enum Status: String, SafeEnumCodable {
            /// Unknown status
            case unknown
            /// This PaymentIntent requires a PaymentMethod or Source
            case requiresPaymentMethod = "requires_payment_method"
            /// This PaymentIntent needs to be confirmed
            case requiresConfirmation = "requires_confirmation"
            /// The selected PaymentMethod or Source requires additional authentication steps.
            /// Additional actions found via `next_action`
            case requiresAction = "requires_action"
            /// Stripe is processing this PaymentIntent
            case processing
            /// The payment has succeeded
            case succeeded
            /// Indicates the payment must be captured, for STPPaymentIntentCaptureMethodManual
            case requiresCapture = "requires_capture"
            /// This PaymentIntent was canceled and cannot be changed.
            case canceled

            case unparsable
            // TODO: This is @frozen because of a bug in the Xcode 12.2 Swift compiler.
            // Remove @frozen after Xcode 12.2 support has been dropped.
        }

        @frozen @_spi(STP) public enum ConfirmationMethod: String, SafeEnumCodable {
            /// Unknown confirmation method
            case unknown
            /// Confirmed via publishable key
            case manual
            /// Confirmed via secret key
            case automatic

            case unparsable
            // TODO: This is @frozen because of a bug in the Xcode 12.2 Swift compiler.
            // Remove @frozen after Xcode 12.2 support has been dropped.
        }

        @frozen @_spi(STP) public enum CaptureMethod: String, SafeEnumCodable {
            /// Unknown capture method
            case unknown
            /// The PaymentIntent will be automatically captured
            case automatic
            /// The PaymentIntent must be manually captured once it has the status
            /// `.requiresCapture`
            case manual

            case unparsable
            // TODO: This is @frozen because of a bug in the Xcode 12.2 Swift compiler.
            // Remove @frozen after Xcode 12.2 support has been dropped.
        }

        @_spi(STP) public var _allResponseFieldsStorage: NonEncodableParameters?
    }
}

extension StripeAPI.PaymentIntent {
    /// Helper function for extracting PaymentIntent id from the Client Secret.
    /// This avoids having to pass around both the id and the secret.
    /// - Parameter clientSecret: The `client_secret` from the PaymentIntent
    internal static func id(fromClientSecret clientSecret: String) -> String? {
        // see parseClientSecret from stripe-js-v3
        // Handle both regular secrets (pi_xxx_secret_yyy) and scoped secrets (pi_xxx_scoped_secret_yyy)
        let secretComponents = clientSecret.components(separatedBy: "_secret_")
        if secretComponents.count >= 2 && secretComponents[0].hasPrefix("pi_") && !secretComponents[1].isEmpty {
            // Check if it's a scoped secret
            if secretComponents[0].hasSuffix("_scoped") {
                // Remove the "_scoped" suffix to get the actual PaymentIntent ID
                let idWithScoped = secretComponents[0]
                let idComponents = idWithScoped.components(separatedBy: "_scoped")
                if idComponents.count >= 1 {
                    return idComponents[0]
                }
            } else {
                // Regular secret format
                return secretComponents[0]
            }
        }
        return nil
    }
}
