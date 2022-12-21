//
//  SetupIntent.swift
//  StripeApplePay
//
//  Created by David Estes on 6/29/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

extension StripeAPI {
    @_spi(STP) public struct SetupIntent: UnknownFieldsDecodable {
        @_spi(STP) public let id: String
        // TODO: (MOBILESDK-467) Add modern bindings for more SetupIntent fields
        @_spi(STP) public let status: SetupIntentStatus?

        /// Status types for an STPSetupIntent
        @frozen @_spi(STP) public enum SetupIntentStatus: String, SafeEnumCodable {
            /// Unknown status
            case unknown
            /// This SetupIntent requires a PaymentMethod
            case requiresPaymentMethod = "requires_payment_method"
            /// This SetupIntent needs to be confirmed
            case requiresConfirmation = "requires_confirmation"
            /// The selected PaymentMethod requires additional authentication steps.
            /// Additional actions found via the `nextAction` property of `STPSetupIntent`
            case requiresAction = "requires_action"
            /// Stripe is processing this SetupIntent
            case processing
            /// The SetupIntent has succeeded
            case succeeded
            /// This SetupIntent was canceled and cannot be changed.
            case canceled

            case unparsable
            // TODO: This is @frozen because of a bug in the Xcode 12.2 Swift compiler.
            // Remove @frozen after Xcode 12.2 support has been dropped.
        }

        @_spi(STP) public var _allResponseFieldsStorage: NonEncodableParameters?
    }
}

extension StripeAPI.SetupIntent {
    /// Helper function for extracting SetupIntent id from the Client Secret.
    /// This avoids having to pass around both the id and the secret.
    /// - Parameter clientSecret: The `client_secret` from the SetupIntent
    internal static func id(fromClientSecret clientSecret: String) -> String? {
        // see parseClientSecret from stripe-js-v3
        let components = clientSecret.components(separatedBy: "_secret_")
        if components.count >= 2 && components[0].hasPrefix("seti_") {
            return components[0]
        } else {
            return nil
        }
    }
}
