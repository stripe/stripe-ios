//
//  Checkout+ApplePayConfiguration.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 7/22/26.
//

import PassKit

@_spi(STP)
@_spi(ReactNativeSDK)
extension Checkout {
    /// Configuration for Apple Pay within a ``Checkout`` session.
    public struct ApplePayConfiguration {
        /// The Apple Merchant Identifier to use during Apple Pay transactions.
        /// To obtain one, see https://stripe.com/docs/apple-pay#native
        public let merchantId: String

        /// The two-letter ISO 3166 code of the country of your business, e.g. "US"
        /// See your account's country value here https://dashboard.stripe.com/settings/account
        public let merchantCountryCode: String

        /// The label displayed in the Apple Pay button.
        /// See https://developer.apple.com/design/human-interface-guidelines/technologies/apple-pay/buttons-and-marks/
        /// for all available options.
        public let buttonType: PKPaymentButtonType

        /// Optional handler blocks for Apple Pay.
        public let customHandlers: Handlers?

        /// Custom handler blocks for Apple Pay.
        public struct Handlers {
            /// Optionally configure additional information on your PKPaymentRequest.
            /// Called after the PKPaymentRequest is created, before the Apple Pay sheet is presented.
            public let paymentRequestHandler: ((PKPaymentRequest) -> PKPaymentRequest)?

            /// Optionally configure additional information on your PKPaymentAuthorizationResult.
            /// Called after the payment is confirmed, before the Apple Pay sheet closes.
            public let authorizationResultHandler: AuthorizationResultHandler?
            public typealias AuthorizationResultHandler = (_ result: PKPaymentAuthorizationResult) async -> PKPaymentAuthorizationResult

            public init(
                paymentRequestHandler: ((PKPaymentRequest) -> PKPaymentRequest)? = nil,
                authorizationResultHandler: AuthorizationResultHandler? = nil
            ) {
                self.paymentRequestHandler = paymentRequestHandler
                self.authorizationResultHandler = authorizationResultHandler
            }
        }

        /// Creates an Apple Pay configuration.
        /// - Parameters:
        ///   - merchantId: Your Apple Merchant Identifier.
        ///   - merchantCountryCode: The two-letter ISO 3166 code of your business country.
        ///   - buttonType: The label displayed in the Apple Pay button. Defaults to `.plain`.
        ///   - customHandlers: Optional handlers for customizing the Apple Pay flow.
        public init(
            merchantId: String,
            merchantCountryCode: String,
            buttonType: PKPaymentButtonType = .plain,
            customHandlers: Handlers? = nil
        ) {
            self.merchantId = merchantId
            self.merchantCountryCode = merchantCountryCode
            self.buttonType = buttonType
            self.customHandlers = customHandlers
        }
    }
}
