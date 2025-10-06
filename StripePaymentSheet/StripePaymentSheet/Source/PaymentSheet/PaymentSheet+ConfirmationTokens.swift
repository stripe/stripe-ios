//
//  PaymentSheet+ConfirmationTokens.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 9/22/25.
//

import Foundation
@_spi(STP)@_spi(ConfirmationTokensPublicPreview) import StripePayments

extension PaymentSheet {
    /// Handles deferred intent confirmation using the Confirmation Tokens API
    ///
    /// - Parameters:
    ///   - confirmType: The confirm type
    ///   - configuration: A PaymentElementConfiguration
    ///   - intentConfig: The current intent configuration
    ///   - authenticationContext: Context for 3D Secure authentication
    ///   - paymentHandler: The payment handler for finishing confirmations
    ///   - isFlowController: Whether this is called from PaymentSheet.FlowController
    ///   - allowsSetAsDefaultPM: Whether the payment method can be set as default
    ///   - elementsSession: The current elements session
    ///   - mandateData: Optional mandate data (auto-generated if not provided)
    ///   - radarOptions: Optional radar settings
    ///   - completion: Called when confirmation completes or fails
    static func handleDeferredIntentConfirmation_confirmationToken(
        confirmType: ConfirmPaymentMethodType,
        configuration: PaymentElementConfiguration,
        intentConfig: PaymentSheet.IntentConfiguration,
        authenticationContext: STPAuthenticationContext,
        paymentHandler: STPPaymentHandler,
        isFlowController: Bool,
        allowsSetAsDefaultPM: Bool = false,
        elementsSession: STPElementsSession,
        mandateData: STPMandateDataParams? = nil,
        radarOptions: STPRadarOptions? = nil,
        completion: @escaping (PaymentSheetResult, STPAnalyticsClient.DeferredIntentConfirmationType?) -> Void
    ) {
        Task { @MainActor in
            // 1. Create the confirmation token params
            let confirmationTokenParams = createConfirmationTokenParams(confirmType: confirmType,
                                                                        configuration: configuration,
                                                                        intentConfig: intentConfig,
                                                                        elementsSession: elementsSession,
                                                                        radarOptions: radarOptions)

            let ephemeralKeySecret: String? = {
                // Only needed when using existing saved payment methods, API will error if provided for new payment methods
                guard confirmationTokenParams.paymentMethod != nil else { return nil }
                // Link saved payment methods don't require ephemeral keys, API will error if provided
                guard !isSavedFromLink(from: confirmType) else { return nil }

                guard let customer = configuration.customer else {
                    stpAssertionFailure("Customer should exist when using saved payment method")
                    return nil
                }
                return customer.ephemeralKeySecret(basedOn: elementsSession)
            }()

            // 2. Create the ConfirmationToken
            let confirmationToken = try await configuration.apiClient.createConfirmationToken(with: confirmationTokenParams,
                                                                                              ephemeralKeySecret: ephemeralKeySecret,
                                                                                              additionalPaymentUserAgentValues: makeDeferredPaymentUserAgentValue(intentConfiguration: intentConfig))

            // 3. Vend the ConfirmationToken and fetch the client secret from the merchant
            _ = try await fetchIntentClientSecretFromMerchant(intentConfig: intentConfig,
                                                              confirmationToken: confirmationToken)

            // TODO(porter) Finish rest of CT confirmation
            stpAssertionFailure("Confirmation Tokens not yet implemented.")
        }
    }

    /// Creates confirmation token parameters for Stripe's Confirmation Tokens API
    ///
    /// Builds a complete `STPConfirmationTokenParams` object with payment method details,
    /// setup future usage settings, and mandate data. Handles both saved and new payment methods
    /// with proper precedence for payment method options and user preferences.
    ///
    /// - Parameters:
    ///   - confirmType: The payment method to confirm (saved or newly entered)
    ///   - configuration: PaymentSheet configuration with URLs and shipping details
    ///   - intentConfig: Intent configuration with payment/setup mode and options
    ///   - allowsSetAsDefaultPM: Whether the payment method can be set as default
    ///   - elementsSession: Elements session for confirmation token creation
    ///   - mandateData: Optional mandate data (auto-generated for required payment methods)
    ///   - radarOptions: Optional fraud detection settings
    /// - Returns: Configured confirmation token parameters ready for Stripe's API
    static func createConfirmationTokenParams(
        confirmType: ConfirmPaymentMethodType,
        configuration: PaymentElementConfiguration,
        intentConfig: PaymentSheet.IntentConfiguration,
        allowsSetAsDefaultPM: Bool = false,
        elementsSession: STPElementsSession,
        mandateData: STPMandateDataParams? = nil,
        radarOptions: STPRadarOptions? = nil
    ) -> STPConfirmationTokenParams {

        // 1. Initialize confirmation token with basic configuration
        let confirmationTokenParams = STPConfirmationTokenParams()
        confirmationTokenParams.returnURL = configuration.returnURL
        confirmationTokenParams.shipping = configuration.shippingDetails()?.paymentIntentShippingDetailsParams
        confirmationTokenParams.clientContext = intentConfig.createClientContext(customerId: configuration.customer?.id)

        // 2. Configure payment method details based on confirm type
        configurePaymentMethodDetails(
            confirmationTokenParams,
            confirmType: confirmType,
            allowsSetAsDefaultPM: allowsSetAsDefaultPM,
            radarOptions: radarOptions
        )

        // 3. Set setup future usage based on intent configuration and user choice
        configureSetupFutureUsage(
            confirmationTokenParams,
            confirmType: confirmType,
            intentConfig: intentConfig
        )

        // 4. Set mandate data (explicit or auto-generated)
        configureMandateData(
            confirmationTokenParams,
            confirmType: confirmType,
            intentConfig: intentConfig,
            explicitMandateData: mandateData
        )

        return confirmationTokenParams
    }

    /// Configures payment method details for the confirmation token
    ///
    /// Sets up either a saved payment method ID or new payment method data,
    /// along with payment options and attribution metadata.
    ///
    /// - Parameters:
    ///   - params: The confirmation token parameters to configure
    ///   - confirmType: The payment method type (saved or new)
    ///   - allowsSetAsDefaultPM: Whether setting as default is allowed
    ///   - radarOptions: Fraud detection options for new payment methods
    private static func configurePaymentMethodDetails(
        _ params: STPConfirmationTokenParams,
        confirmType: ConfirmPaymentMethodType,
        allowsSetAsDefaultPM: Bool,
        radarOptions: STPRadarOptions?
    ) {
        switch confirmType {
        case .saved(let paymentMethod, let paymentOptions, let clientAttributionMetadata):
            // Use existing saved payment method
            params.paymentMethod = paymentMethod.stripeId
            params.paymentMethodOptions = paymentOptions
            params.clientAttributionMetadata = clientAttributionMetadata
        case .new(let paymentMethodParams, let paymentOptions, _, _, let shouldSetAsDefaultPM):
            params.paymentMethodData = paymentMethodParams
            params.paymentMethodData?.radarOptions = radarOptions
            params.paymentMethodOptions = paymentOptions
            params.clientAttributionMetadata = paymentMethodParams.clientAttributionMetadata

            // Set as default payment method if requested and allowed
            if allowsSetAsDefaultPM && shouldSetAsDefaultPM == true {
                params.setAsDefaultPM = NSNumber(value: true)
            }
        }
    }

    /// Configures setup future usage for saving payment methods
    ///
    /// Determines when to save payment methods based on intent mode and user choice.
    /// For setup intents, always uses the configured value. For payment intents,
    /// prioritizes user selection over intent configuration.
    ///
    /// - Parameters:
    ///   - params: The confirmation token parameters to configure
    ///   - confirmType: The payment method type with user save preference
    ///   - intentConfig: Intent configuration with setup future usage settings
    private static func configureSetupFutureUsage(
        _ params: STPConfirmationTokenParams,
        confirmType: ConfirmPaymentMethodType,
        intentConfig: PaymentSheet.IntentConfiguration
    ) {
        switch intentConfig.mode {
        case .setup(_, let setupFutureUsage):
            // Setup intents: Always use the configured setup future usage value
            params.setupFutureUsage = setupFutureUsage.paymentIntentParamsValue
        case .payment(_, _, let intentSetupFutureUsage, _, let paymentMethodOptions):
            let paymentMethodType = paymentMethodType(from: confirmType)
            // Priority order: user checkbox > PMO SFU > top-level SFU
            if confirmType.shouldSave {
                // 1. User chose to save payment method via checkbox takes highest priority
                params.setupFutureUsage = .offSession
            } else if let pmoSFU = paymentMethodOptions?.setupFutureUsageValues?[paymentMethodType] {
                // 2. PMO SFU takes second priority
                params.setupFutureUsage = pmoSFU.paymentIntentParamsValue
            } else if let intentSetupFutureUsage = intentSetupFutureUsage {
                // 3. Use top-level intent configuration as fallback
                params.setupFutureUsage = intentSetupFutureUsage.paymentIntentParamsValue
            }
        }
    }

    /// Configures mandate data for the confirmation token
    ///
    /// Uses explicit mandate data if provided, otherwise auto-generates based on
    /// payment method requirements and setup future usage settings.
    ///
    /// - Parameters:
    ///   - params: The confirmation token parameters to configure
    ///   - confirmType: The payment method type being confirmed
    ///   - intentConfig: Intent configuration with setup future usage settings
    ///   - explicitMandateData: Optional explicit mandate data to use
    private static func configureMandateData(
        _ params: STPConfirmationTokenParams,
        confirmType: ConfirmPaymentMethodType,
        intentConfig: PaymentSheet.IntentConfiguration,
        explicitMandateData: STPMandateDataParams?
    ) {
        if let explicitMandateData = explicitMandateData {
            // Use explicitly provided mandate data
            params.mandateData = explicitMandateData
        } else {
            // Auto-generate mandate data based on payment method and intent requirements
            params.mandateData = generateMandateData(
                confirmType: confirmType,
                intentConfig: intentConfig,
                setupFutureUsage: params.setupFutureUsage
            )
        }
    }

    /// Auto-generates mandate data when required
    ///
    /// Creates mandate data for payment methods that require explicit user consent,
    /// such as bank debits and wallet payments with future usage. Follows Stripe's
    /// requirements based on payment method type and setup future usage settings.
    ///
    /// - Parameters:
    ///   - confirmType: The payment method type being confirmed
    ///   - intentConfig: Intent configuration with setup future usage and payment method options
    ///   - setupFutureUsage: The already-computed setup future usage value from params
    /// - Returns: Mandate data if required by the payment method, nil otherwise
    private static func generateMandateData(
        confirmType: ConfirmPaymentMethodType,
        intentConfig: PaymentSheet.IntentConfiguration,
        setupFutureUsage: STPPaymentIntentSetupFutureUsage?
    ) -> STPMandateDataParams? {
        let paymentMethodType = Self.paymentMethodType(from: confirmType)

        switch intentConfig.mode {
        case .payment:
            // Payment methods that require mandate data when setup_future_usage is "off_session"
            if STPPaymentMethodType.requiresMandateDataForPaymentIntent.contains(paymentMethodType) {
                if setupFutureUsage == .offSession {
                    return .makeWithInferredValues()
                }
            }

            // If no mandate data, fallback to STPPaymentIntentParams auto add functionality
            return STPPaymentIntentParams.mandateDataIfRequired(for: paymentMethodType)
        case .setup:
            // Setup intents always require mandate data for certain payment methods
            if STPPaymentMethodType.requiresMandateDataForSetupIntent.contains(paymentMethodType) {
                return .makeWithInferredValues()
            }

            // If no mandate data, fallback to STPSetupIntentConfirmParams auto add functionality
            return STPSetupIntentConfirmParams.mandateDataIfRequired(for: paymentMethodType)
        }
    }

    /// Extracts the  payment method type from confirmation details
    ///
    /// - Parameter confirmType: The confirmation type (saved or new payment method)
    /// - Returns: The  payment method type for API operations
    private static func paymentMethodType(from confirmType: ConfirmPaymentMethodType) -> STPPaymentMethodType {
        switch confirmType {
        case .saved(let paymentMethod, _, _):
            return paymentMethod.type
        case .new(let params, _, _, _, _):
            return params.type
        }
    }

    /// Determines if a payment method was saved through Stripe Link
    ///
    /// - Parameter confirmType: The payment method confirmation type
    /// - Returns: True if the payment method originated from Link
    private static func isSavedFromLink(from confirmType: ConfirmPaymentMethodType) -> Bool {
        switch confirmType {
        case .saved(let paymentMethod, _, _):
            return paymentMethod.card?.wallet?.type == .link || paymentMethod.isLinkPaymentMethod || paymentMethod.isLinkPassthroughMode || paymentMethod.usBankAccount?.linkedAccount != nil
        case .new:
            return false
        }
    }

    /// Calls merchant app confirm handler to get the intent client secret
    ///
    /// - Parameters:
    ///   - intentConfig: The Intent configuration
    ///   - confirmationToken: The newly created confirmation token
    /// - Returns: Client secret for the PaymentIntent or SetupIntent
    /// - Throws: Any error from the merchant's confirmation handler
    private static func fetchIntentClientSecretFromMerchant(
        intentConfig: IntentConfiguration,
        confirmationToken: STPConfirmationToken
    ) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                intentConfig.confirmationTokenConfirmHandler?(confirmationToken) { result in
                    continuation.resume(with: result)
                }
            }
        }
    }
}
