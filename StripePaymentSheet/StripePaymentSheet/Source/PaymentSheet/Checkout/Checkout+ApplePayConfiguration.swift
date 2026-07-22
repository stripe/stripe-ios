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
    /// Configuration for Apple Pay in ``ExpressCheckoutElement``.
    public struct ApplePayConfiguration {
        /// The Apple Pay merchant identifier.
        public let merchantId: String

        /// The two-letter ISO 3166 country code of your business.
        public let merchantCountryCode: String

        /// The type of Apple Pay button to display. Defaults to `.plain`.
        public var buttonType: PKPaymentButtonType

        /// Optional handlers for customizing the Apple Pay flow.
        public var customHandlers: Handlers?

        /// Creates an Apple Pay configuration.
        /// - Parameters:
        ///   - merchantId: The Apple Pay merchant identifier.
        ///   - merchantCountryCode: The two-letter ISO 3166 country code of your business.
        ///   - buttonType: The type of Apple Pay button to display.
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

        /// Handlers for customizing the Apple Pay authorization flow.
        public struct Handlers {
            /// An optional closure for customizing the ``PKPaymentRequest`` before it is used to authorize payment.
            public var paymentRequestHandler: ((PKPaymentRequest) -> PKPaymentRequest)?

            /// An optional closure for customizing the ``PKPaymentAuthorizationResult`` returned when authorizing payment.
            public var authorizationResultHandler: AuthorizationResultHandler?

            /// The type of the authorization result handler closure.
            public typealias AuthorizationResultHandler = (
                _ result: PKPaymentAuthorizationResult
            ) async -> PKPaymentAuthorizationResult

            /// Creates handlers with optional payment request and authorization result customization.
            public init(
                paymentRequestHandler: ((PKPaymentRequest) -> PKPaymentRequest)? = nil,
                authorizationResultHandler: AuthorizationResultHandler? = nil
            ) {
                self.paymentRequestHandler = paymentRequestHandler
                self.authorizationResultHandler = authorizationResultHandler
            }
        }
    }
}
