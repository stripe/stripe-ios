//
//  PaymentSheetIntentConfiguration.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 2/16/23.
//

import Foundation
@_spi(STP) import StripeCore
import StripePayments

public extension PaymentSheet {
    /// Contains information needed to render PaymentSheet
    /// The values are used to calculate the payment methods displayed and influence the UI.
    /// - Note: The PaymentIntent or SetupIntent you create on your server must have the same values or the payment/setup will fail.
    /// - Seealso: https://stripe.com/docs/payments/finalize-payments-on-the-server
    struct IntentConfiguration {

        /// Pass this into `intentCreationCallback` to force PaymentSheet to show success, dismiss the sheet, and return a PaymentSheetResult of `completed`.
        /// - Note: ⚠️ If provided, the SDK performs no action to complete the payment or setup - it doesn't confirm a PaymentIntent or SetupIntent or handle next actions.
        ///   You should only use this if your integration can't create a PaymentIntent or SetupIntent. It is your responsibility to ensure that you only pass this value if the payment or set up is successful. 
        @_spi(PaymentSheetSkipConfirmation) public static let COMPLETE_WITHOUT_CONFIRMING_INTENT = "COMPLETE_WITHOUT_CONFIRMING_INTENT"

        /// Called when the customer confirms payment.
        /// Your implementation should follow the [guide](https://stripe.com/docs/payments/finalize-payments-on-the-server) to create (and optionally confirm) PaymentIntent or SetupIntent on your server and call the `intentCreationCallback` with its client secret or an error if one occurred.
        /// - Note: You must create the PaymentIntent or SetupIntent with the same values used as the `IntentConfiguration` e.g. the same amount, currency, etc.
        /// - Parameters:
        ///   - paymentMethod: The `STPPaymentMethod` representing the customer's payment details.
        ///   If your server needs the payment method, send `paymentMethod.stripeId` to your server and have it fetch the PaymentMethod object. Otherwise, you can ignore this. Don't send other properties besides the ID to your server.
        ///   - shouldSavePaymentMethod: This is `true` if the customer selected the "Save this payment method for future use" checkbox.
        ///     If you confirm the PaymentIntent on your server, set `setup_future_usage` on the PaymentIntent to `off_session` if this is `true`. Otherwise, ignore this parameter.
        /// - Returns: The `client_secret` of the PaymentIntent or SetupIntent created by your server.
        /// - Throws: The error that occurred. If you're using PaymentSheet, the error's localizedDescription will be displayed to the customer in the sheet. If you're using PaymentSheet.FlowController, the `confirm` method fails with the error.
        public typealias ConfirmHandler = (
            _ paymentMethod: STPPaymentMethod,
            _ shouldSavePaymentMethod: Bool
        ) async throws -> String

        /// Called when the customer confirms payment using confirmation tokens.
        /// Your implementation should follow the [guide](https://stripe.com/docs/payments/finalize-payments-on-the-server) to create (and optionally confirm) a PaymentIntent or SetupIntent on your server and return its client secret.
        /// - Note: You must create the PaymentIntent or SetupIntent with the same values used as the `IntentConfiguration` e.g. the same amount, currency, etc.
        /// - Note: When confirming the PaymentIntent or SetupIntent on your server, use the confirmation token ID (`confirmationToken.stripeId`) as the `confirmation_token` parameter.
        /// - Parameters:
        ///   - confirmationToken: The `STPConfirmationToken` representing the customer's payment details and any additional information collected during checkout (e.g., billing details, shipping address).
        /// - Returns: The `client_secret` of the PaymentIntent or SetupIntent created by your server.
        /// - Throws: An error if one occurred. If you're using PaymentSheet, the error's localizedDescription will be displayed to the customer in the sheet. If you're using PaymentSheet.FlowController, the `confirm` method fails with the error.
        /// - SeeAlso: [Confirmation Tokens documentation](https://stripe.com/docs/api/confirmation_tokens) for more information about how confirmation tokens work.
        public typealias ConfirmationTokenConfirmHandler = (
            _ confirmationToken: STPConfirmationToken
        ) async throws -> String

        /// Called when the payment is confirmed in a shared payment token session.
        /// Returns `paymentMethod` and `shippingAddress` info, which can be passed to the backend for confirmation.
        @_spi(SharedPaymentToken) public typealias PreparePaymentMethodHandler = (
            _ paymentMethod: STPPaymentMethod,
            _ shippingAddress: STPAddress?
        ) -> Void

        /// Seller details for facilitated payment sessions
        @_spi(SharedPaymentToken) public struct SellerDetails {
            public let networkId: String
            public let externalId: String
            public let businessName: String

            public init(networkId: String, externalId: String, businessName: String) {
                self.networkId = networkId
                self.externalId = externalId
                self.businessName = businessName
            }
        }

        /// Creates a `PaymentSheet.IntentConfiguration` with the given values
        /// - Parameters:
        ///   - mode: The mode of this intent, either payment or setup
        ///   - paymentMethodTypes: The payment method types for the intent
        ///   - onBehalfOf: The account (if any) for which the funds of the intent are intended
        ///   - paymentMethodConfigurationId: Configuration ID (if any) for the selected payment method configuration
        ///   - confirmHandler: A handler called with payment details when the user taps the primary button (e.g. the "Pay" or "Continue" button).
        ///   - requireCVCRecollection: If true, PaymentSheet recollects CVC for saved cards before confirmation (PaymentIntent only)
        public init(mode: Mode,
                    paymentMethodTypes: [String]? = nil,
                    onBehalfOf: String? = nil,
                    paymentMethodConfigurationId: String? = nil,
                    confirmHandler: @escaping ConfirmHandler,
                    requireCVCRecollection: Bool = false) {
            self.mode = mode
            self.paymentMethodTypes = paymentMethodTypes
            self.onBehalfOf = onBehalfOf
            self.paymentMethodConfigurationId = paymentMethodConfigurationId
            self.confirmHandler = confirmHandler
            self.requireCVCRecollection = requireCVCRecollection
            self.sellerDetails = nil
            validate()
        }

        /// Creates a `PaymentSheet.IntentConfiguration` for a shared payment token session
        /// - Parameters:
        ///   - mode: The mode of this intent, either payment or setup
        ///   - sellerDetails: Seller details for the shared payment token session
        ///   - paymentMethodTypes: The payment method types for the intent
        ///   - onBehalfOf: The account (if any) for which the funds of the intent are intended
        ///   - paymentMethodConfigurationId: Configuration ID (if any) for the selected payment method configuration
        ///   - preparePaymentMethodHandler: A handler called with payment and shipping when the user taps the primary button (e.g. the "Pay" or "Continue" button).
        ///   - requireCVCRecollection: If true, PaymentSheet recollects CVC for saved cards before confirmation (PaymentIntent only)
        @_spi(SharedPaymentToken) public init(sharedPaymentTokenSessionWithMode mode: Mode,
                                              sellerDetails: SellerDetails?,
                                              paymentMethodTypes: [String]? = nil,
                                              onBehalfOf: String? = nil,
                                              paymentMethodConfigurationId: String? = nil,
                                              preparePaymentMethodHandler: @escaping PreparePaymentMethodHandler,
                                              requireCVCRecollection: Bool = false) {
            self.mode = mode
            self.paymentMethodTypes = paymentMethodTypes
            self.onBehalfOf = onBehalfOf
            self.paymentMethodConfigurationId = paymentMethodConfigurationId
            self.preparePaymentMethodHandler = preparePaymentMethodHandler
            self.requireCVCRecollection = requireCVCRecollection
            self.sellerDetails = sellerDetails
            self.confirmHandler = { _, _ in
                // fail immediately, this should never be called
                stpAssertionFailure("sharedPaymentTokenSessionWithMode call the preparePaymentMethodHandler, not the confirmHandler")
                throw PaymentSheetError.intentConfigurationValidationFailed(message: "Internal Shared Payment Token session error. Please file an issue at https://github.com/stripe/stripe-ios.")
            }
            validate()
        }

        /// Creates a `PaymentSheet.IntentConfiguration` with a confirmation token handler
        /// - Parameters:
        ///   - mode: The mode of this intent, either payment or setup
        ///   - paymentMethodTypes: The payment method types for the intent
        ///   - onBehalfOf: The account (if any) for which the funds of the intent are intended
        ///   - paymentMethodConfigurationId: Configuration ID (if any) for the selected payment method configuration
        ///   - confirmationTokenConfirmHandler: A handler called with a confirmation token when the user taps the primary button. Use this for a more secure and streamlined payment flow.
        ///   - requireCVCRecollection: If true, PaymentSheet recollects CVC for saved cards before confirmation (PaymentIntent only)
        public init(mode: Mode,
                    paymentMethodTypes: [String]? = nil,
                    onBehalfOf: String? = nil,
                    paymentMethodConfigurationId: String? = nil,
                    confirmationTokenConfirmHandler: @escaping ConfirmationTokenConfirmHandler,
                    requireCVCRecollection: Bool = false) {
            self.mode = mode
            self.paymentMethodTypes = paymentMethodTypes
            self.onBehalfOf = onBehalfOf
            self.paymentMethodConfigurationId = paymentMethodConfigurationId
            self.confirmationTokenConfirmHandler = confirmationTokenConfirmHandler
            self.requireCVCRecollection = requireCVCRecollection
            self.sellerDetails = nil
            self.confirmHandler = { _, _ in
                // fail immediately, this should never be called
                stpAssertionFailure("Confirmation token configuration should use confirmationTokenConfirmHandler, not confirmHandler")
                throw PaymentSheetError.intentConfigurationValidationFailed(message: "Internal Confirmation Token error. Please file an issue at https://github.com/stripe/stripe-ios.")
            }
            validate()
        }

        /// Information about the payment (PaymentIntent) or setup (SetupIntent).
        public var mode: Mode {
            didSet { validate() }
        }

        /// A list of payment method types to display to the customer. If nil, we dynamically determine the payment methods using your Stripe Dashboard settings.
        public var paymentMethodTypes: [String]?

        /// Called when the customer confirms payment.
        /// See the documentation for `ConfirmHandler` for more details.
        public var confirmHandler: ConfirmHandler?

        /// Called when the customer confirms payment using confirmation tokens.
        /// See the documentation for `ConfirmationTokenConfirmHandler` for more details.
        /// - Note: Use this instead of `confirmHandler` when you want to use confirmation tokens for a more secure and streamlined payment flow.
        public var confirmationTokenConfirmHandler: ConfirmationTokenConfirmHandler?

        /// Replacement for confirmHandler in sharedPaymentTokenSession flows. Not publicly available.
        var preparePaymentMethodHandler: PreparePaymentMethodHandler?

        /// The account (if any) for which the funds of the intent are intended.
        /// - Seealso: https://stripe.com/docs/api/payment_intents/object#payment_intent_object-on_behalf_of
        public var onBehalfOf: String?

        /// Optional configuration ID for the selected payment method configuration.
        /// See https://stripe.com/docs/payments/multiple-payment-method-configs for more information.
        public var paymentMethodConfigurationId: String?

        /// If true, PaymentSheet recollects CVC for saved cards before confirmation (PaymentIntents only)
        ///  - Seealso: https://docs.stripe.com/payments/accept-a-payment-deferred?platform=ios&type=payment#ios-cvc-recollection
        ///  - Note: Server-side confirmation is not supported.
        public var requireCVCRecollection: Bool

        /// Seller details for facilitated payment sessions
        @_spi(SharedPaymentToken) public var sellerDetails: SellerDetails?

        /// Controls when the funds will be captured. 
        /// - Seealso: https://stripe.com/docs/api/payment_intents/create#create_payment_intent-capture_method
        public enum CaptureMethod: String {
            /// (Default) Stripe automatically captures funds when the customer authorizes the payment.
            case automatic = "automatic"

            /// Place a hold on the funds when the customer authorizes the payment, but don’t capture the funds until later. (Not all payment methods support this.)
            case manual = "manual"

            /// Asynchronously capture funds when the customer authorizes the payment.
            /// - Note: Recommended over `CaptureMethod.automatic` due to improved latency, but may require additional integration changes.
            /// - Seealso: https://stripe.com/docs/payments/payment-intents/asynchronous-capture-automatic-async
            case automaticAsync = "automatic_async"
        }

        /// Indicates that you intend to make future payments with this PaymentIntent’s payment method.
        /// - Seealso: https://stripe.com/docs/api/payment_intents/create#create_payment_intent-setup_future_usage
        public enum SetupFutureUsage: String {
            /// Use off_session if your customer may or may not be present in your checkout flow.
            case offSession = "off_session"

            /// Use this if you intend to only reuse the payment method when your customer is present in your checkout flow.
            case onSession = "on_session"

            /// Use this if you do not intend to reuse this payment method and want to override the top-level `setup_future_usage` value for this payment method.
            /// - Note: This value is only valid when used to set `PaymentMethodOptions.setupFutureUsageValues`.
            @_spi(PaymentMethodOptionsSetupFutureUsagePreview) case none = "none"
        }

        /// Additional information about the payment or setup
        public enum Mode {
            /// Payment method options
            public struct PaymentMethodOptions {
                var setupFutureUsageValues: [STPPaymentMethodType: SetupFutureUsage]?

                @_spi(PaymentMethodOptionsSetupFutureUsagePreview) public init(setupFutureUsageValues: [STPPaymentMethodType: SetupFutureUsage]? = nil) {
                    self.setupFutureUsageValues = setupFutureUsageValues
                }
            }

            /// Use this if your integration creates a PaymentIntent
            case payment(
                /// Amount intended to be collected in the smallest currency unit (e.g. 100 cents to charge $1.00). Shown in Apple Pay, Buy now pay later UIs, the Pay button, and influences available payment methods.
                /// - Seealso: https://stripe.com/docs/api/payment_intents/create#create_payment_intent-amount
                amount: Int,
                /// Three-letter ISO currency code. Filters out payment methods based on supported currency.
                /// - Seealso: https://stripe.com/docs/api/payment_intents/create#create_payment_intent-currency
                currency: String,
                /// Indicates that you intend to make future payments.
                /// - Seealso: https://stripe.com/docs/api/payment_intents/create#create_payment_intent-setup_future_usage
                setupFutureUsage: SetupFutureUsage? = nil,
                /// - Seealso: https://stripe.com/docs/api/payment_intents/create#create_payment_intent-capture_method
                captureMethod: CaptureMethod = .automatic,
                /// Additional payment method options params
                /// - Seealso: https://docs.stripe.com/api/payment_intents/create#create_payment_intent-payment_method_options
                paymentMethodOptions: PaymentMethodOptions? = nil

            )
            /// Use this if your integration creates a SetupIntent
            case setup(
                /// Three-letter ISO currency code. Optional - setting this ensures only valid payment methods are displayed.
                currency: String? = nil,
                /// Indicates how the payment method is intended to be used in the future.
                /// - Seealso: https://stripe.com/docs/api/setup_intents/create#create_setup_intent-usage
                setupFutureUsage: SetupFutureUsage = .offSession
            )
        }

        // MARK: - Internal

        @discardableResult
        func validate() -> Error? {
            let errorMessage: String
            if case .payment(let amount, _, _, _, _) = mode, amount <= 0 {
                errorMessage = "The amount in `PaymentSheet.IntentConfiguration` must be non-zero! See https://docs.stripe.com/api/payment_intents/create#create_payment_intent-amount"
                return PaymentSheetError.intentConfigurationValidationFailed(message: errorMessage)
            }
            return nil
        }

        // MARK: - Deprecated

        @available(*, deprecated, message: "The confirmHandler closure has been replaced by an async version. To update, delete the `intentCreationCallback` argument in the closure and return the intent client secret or throw an error. See https://github.com/stripe/stripe-ios/blob/master/MIGRATING.md#migrating-from-versions--2500 for help.")
        public init(
            mode: Mode,
            paymentMethodTypes: [String]? = nil,
            onBehalfOf: String? = nil,
            paymentMethodConfigurationId: String? = nil,
            confirmHandler: @escaping (
                _ paymentMethod: STPPaymentMethod,
                _ shouldSavePaymentMethod: Bool,
                _ intentCreationCallback: @escaping ((Result<String, Error>) -> Void)
            ) -> Void,
            requireCVCRecollection: Bool = false
        ) {
            self.init(
                mode: mode,
                paymentMethodTypes: paymentMethodTypes,
                onBehalfOf: onBehalfOf,
                paymentMethodConfigurationId: paymentMethodConfigurationId,
                confirmHandler: { paymentMethod, shouldSavePaymentMethod in
                    return try await withCheckedThrowingContinuation { continuation in
                        Task { @MainActor in
                            confirmHandler(paymentMethod, shouldSavePaymentMethod) { result in
                                continuation.resume(with: result)
                            }
                        }
                    }
                },
                requireCVCRecollection: requireCVCRecollection
            )
        }
    }
}
