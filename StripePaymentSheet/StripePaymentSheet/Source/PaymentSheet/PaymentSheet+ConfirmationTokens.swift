//
//  PaymentSheet+ConfirmationTokens.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 9/22/25.
//

import Foundation
@_spi(STP)@_spi(ConfirmationTokensPublicPreview) import StripePayments

extension PaymentSheet {
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
        switch confirmType {
        case .saved(let paymentMethod, let paymentOptions, let clientAttributionMetadata):
            // Use existing saved payment method
            confirmationTokenParams.paymentMethod = paymentMethod.stripeId
            confirmationTokenParams.paymentMethodOptions = paymentOptions
            confirmationTokenParams.clientAttributionMetadata = clientAttributionMetadata
        case .new(let paymentMethodParams, let paymentOptions, _, _, let shouldSetAsDefaultPM):
            confirmationTokenParams.paymentMethodData = paymentMethodParams
            confirmationTokenParams.paymentMethodData?.radarOptions = radarOptions
            confirmationTokenParams.paymentMethodOptions = paymentOptions
            confirmationTokenParams.clientAttributionMetadata = paymentMethodParams.clientAttributionMetadata

            // Set as default payment method if requested and allowed
            if allowsSetAsDefaultPM && shouldSetAsDefaultPM == true {
                confirmationTokenParams.setAsDefaultPM = NSNumber(value: true)
            }
        }

        // 3. Set setup future usage based on intent configuration and user choice
        switch intentConfig.mode {
        case .setup(_, let setupFutureUsage):
            // Setup intents: Always use the configured setup future usage value
            confirmationTokenParams.setupFutureUsage = setupFutureUsage.paymentIntentParamsValue
        case .payment(_, _, let intentSetupFutureUsage, _, let paymentMethodOptions):
            let paymentMethodType = paymentMethodType(from: confirmType)
            // Priority order: user checkbox > PMO SFU > top-level SFU
            if confirmType.shouldSave {
                // 1. User chose to save payment method via checkbox takes highest priority
                confirmationTokenParams.setupFutureUsage = .offSession
            } else if let pmoSFU = paymentMethodOptions?.setupFutureUsageValues?[paymentMethodType] {
                // 2. PMO SFU takes second priority
                confirmationTokenParams.setupFutureUsage = pmoSFU.paymentIntentParamsValue
            } else if let intentSetupFutureUsage = intentSetupFutureUsage {
                // 3. Use top-level intent configuration as fallback
                confirmationTokenParams.setupFutureUsage = intentSetupFutureUsage.paymentIntentParamsValue
            }
        }

        // 4. Set mandate data (explicit or auto-generated)
        if let explicitMandateData = mandateData {
            // Use explicitly provided mandate data
            confirmationTokenParams.mandateData = explicitMandateData
        } else {
            // Auto-generate mandate data based on payment method and intent requirements
            let paymentMethodType = Self.paymentMethodType(from: confirmType)

            switch intentConfig.mode {
            case .payment:
                // Payment methods that require mandate data when setup_future_usage is "off_session"
                if STPPaymentMethodType.requiresMandateDataForPaymentIntent.contains(paymentMethodType) {
                    if confirmationTokenParams.setupFutureUsage == .offSession {
                        confirmationTokenParams.mandateData = .makeWithInferredValues()
                    }
                }

                // If no mandate data, fallback to STPPaymentIntentParams auto add functionality
                if confirmationTokenParams.mandateData == nil {
                    confirmationTokenParams.mandateData = STPPaymentIntentParams.mandateDataIfRequired(for: paymentMethodType)
                }
            case .setup:
                // Setup intents always require mandate data for certain payment methods
                if STPPaymentMethodType.requiresMandateDataForSetupIntent.contains(paymentMethodType) {
                    confirmationTokenParams.mandateData = .makeWithInferredValues()
                }

                // If no mandate data, fallback to STPSetupIntentConfirmParams auto add functionality
                if confirmationTokenParams.mandateData == nil {
                    confirmationTokenParams.mandateData = STPSetupIntentConfirmParams.mandateDataIfRequired(for: paymentMethodType)
                }
            }
        }

        return confirmationTokenParams
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
