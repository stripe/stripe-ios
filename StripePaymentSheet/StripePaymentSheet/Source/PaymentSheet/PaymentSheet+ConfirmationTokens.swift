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
        elementsSession: STPElementsSession?,
        mandateData: STPMandateDataParams? = nil,
        radarOptions: STPRadarOptions? = nil,
        completion: @escaping (PaymentSheetResult, STPAnalyticsClient.DeferredIntentConfirmationType?) -> Void
    ) {
        Task { @MainActor in
            do {
                // ElementsSession is required for confirmation token flow
                guard let elementsSession = elementsSession else {
                    assertionFailure("ElementsSession is required for confirmation token flow")
                    completion(.failed(error: PaymentSheetError.unknown(debugDescription: "ElementsSession is required for confirmation token flow")), nil)
                    return
                }
                
                // 1. Create the confirmation token params
                let confirmationTokenParams = createConfirmationTokenParams(confirmType: confirmType,
                                                                            configuration: configuration,
                                                                            intentConfig: intentConfig,
                                                                            elementsSession: elementsSession)
                
                // Compute ephemeral key secret for customer session support
                let ephemeralKeySecret = configuration.customer?.ephemeralKeySecretBasedOn(elementsSession: elementsSession)
                let confirmationToken = try await configuration.apiClient.createConfirmationToken(with: confirmationTokenParams,
                                                                                                  ephemeralKeySecret: confirmationTokenParams.paymentMethod == nil ? nil : ephemeralKeySecret)
                let clientSecret = try await fetchIntentClientSecretFromMerchant(intentConfig: intentConfig,
                                                                                 confirmationToken: confirmationToken)
                guard clientSecret != IntentConfiguration.COMPLETE_WITHOUT_CONFIRMING_INTENT else {
                    // Force close PaymentSheet and early exit
                    completion(.completed, STPAnalyticsClient.DeferredIntentConfirmationType.completeWithoutConfirmingIntent)
                    return
                }

                // Overwrite `completion` to ensure we set the default if necessary before completing.
                let completion = { (status: STPPaymentHandlerActionStatus, paymentOrSetupIntent: PaymentOrSetupIntent?, error: NSError?, deferredIntentConfirmationType: STPAnalyticsClient.DeferredIntentConfirmationType) in
                    if let paymentOrSetupIntent {
                        setDefaultPaymentMethodIfNecessary(actionStatus: status, intent: paymentOrSetupIntent, configuration: configuration, paymentMethodSetAsDefault: allowsSetAsDefaultPM)
                    }
                    completion(makePaymentSheetResult(for: status, error: error), deferredIntentConfirmationType)
                }

                // 3. Retrieve the PaymentIntent or SetupIntent
                switch intentConfig.mode {
                case .payment:
                    let paymentIntent = try await configuration.apiClient.retrievePaymentIntent(clientSecret: clientSecret, expand: ["payment_method"])

                    // Check if it needs confirmation
                    if [STPPaymentIntentStatus.requiresPaymentMethod, STPPaymentIntentStatus.requiresConfirmation].contains(paymentIntent.status) {
                        // 4a. Client-side confirmation with confirmation token
                        // TODO(porter) Add confirmation token flow validation
                        let paymentIntentParams = STPPaymentIntentParams(clientSecret: paymentIntent.clientSecret, confirmationToken: confirmationToken)

                        paymentHandler.confirmPayment(
                            paymentIntentParams,
                            with: authenticationContext
                        ) { status, paymentIntent, error in
                            completion(status, paymentIntent.flatMap { PaymentOrSetupIntent.paymentIntent($0) }, error, .client)
                        }
                    } else {
                        // 4b. Server-side confirmation
                        // TODO(porter) Add confirmation token flow validation
                        paymentHandler.handleNextAction(
                            for: paymentIntent,
                            with: authenticationContext,
                            returnURL: configuration.returnURL
                        ) { status, paymentIntent, error in
                            completion(status, paymentIntent.flatMap { PaymentOrSetupIntent.paymentIntent($0) }, error, .server)
                        }
                    }
                case .setup:
                    let setupIntent = try await configuration.apiClient.retrieveSetupIntent(clientSecret: clientSecret, expand: ["payment_method"])

                    if [STPSetupIntentStatus.requiresPaymentMethod, STPSetupIntentStatus.requiresConfirmation].contains(setupIntent.status) {
                        // 4a. Client-side confirmation with confirmation token
                        // TODO(porter) Add confirmation token flow validation
                        let setupIntentParams = STPSetupIntentConfirmParams(clientSecret: setupIntent.clientSecret, confirmationToken: confirmationToken)

                        paymentHandler.confirmSetupIntent(
                            setupIntentParams,
                            with: authenticationContext
                        ) { status, setupIntent, error in
                            completion(status, setupIntent.flatMap { PaymentOrSetupIntent.setupIntent($0) }, error, .client)
                        }
                    } else {
                        // 4b. Server-side confirmation
                        // TODO(porter) Add confirmation token flow validation
                        paymentHandler.handleNextAction(
                            for: setupIntent,
                            with: authenticationContext,
                            returnURL: configuration.returnURL
                        ) { status, setupIntent, error in
                            completion(status, setupIntent.flatMap { PaymentOrSetupIntent.setupIntent($0) }, error, .server)
                        }
                    }
                }
            } catch {
                completion(.failed(error: error), nil)
            }
        }
    }
    
    private static func createConfirmationTokenParams(
        confirmType: ConfirmPaymentMethodType,
        configuration: PaymentElementConfiguration,
        intentConfig: PaymentSheet.IntentConfiguration,
        allowsSetAsDefaultPM: Bool = false,
        elementsSession: STPElementsSession?,
        mandateData: STPMandateDataParams? = nil,
        radarOptions: STPRadarOptions? = nil
    ) -> STPConfirmationTokenParams {
        // 1. Create the ConfirmationTokenParams
        let confirmationTokenParams = STPConfirmationTokenParams()
        confirmationTokenParams.returnURL = configuration.returnURL
        confirmationTokenParams.shipping = configuration.shippingDetails()?.paymentIntentShippingDetailsParams

        switch confirmType {
        case .saved(let sTPPaymentMethod, let paymentOptions, let clientAttributionMetadata):
            confirmationTokenParams.paymentMethod = sTPPaymentMethod.stripeId
            confirmationTokenParams.paymentMethodOptions = paymentOptions // TODO(porter) Verify CVC recollection
            confirmationTokenParams.clientAttributionMetadata = clientAttributionMetadata
        case .new(let params, let paymentOptions, let newPaymentMethod, _, let shouldSetAsDefaultPM):
            if let newPaymentMethod {
                let errorAnalytic = ErrorAnalytic(event: .unexpectedPaymentSheetConfirmationError,
                                                  error: PaymentSheetError.unexpectedNewPaymentMethod,
                                                  additionalNonPIIParams: ["payment_method_type": newPaymentMethod.type])
                STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic)
            }
            stpAssert(newPaymentMethod == nil)
            confirmationTokenParams.paymentMethodData = params
            confirmationTokenParams.paymentMethodData?.radarOptions = radarOptions
            confirmationTokenParams.paymentMethodOptions = paymentOptions
            // Not setting clientAttributionMetadata on the CT params as it's already contained on the params

            if allowsSetAsDefaultPM && shouldSetAsDefaultPM == true {
                confirmationTokenParams.setAsDefaultPM = NSNumber(value: true)
            }
        }

        // Calculate unified shouldSavePaymentMethod value (matches logic from handleDeferredIntentConfirmation)
        let paymentMethodType = Self.paymentMethodType(from: confirmType)
        let shouldSavePaymentMethod: Bool = {
            // If `confirmType.shouldSave` is true, that means the customer has decided to save by checking the checkbox.
            if confirmType.shouldSave {
                return true
            }
            // Otherwise, set shouldSavePaymentMethod according to the IntentConfiguration SFU/PMO SFU values
            return getShouldSavePaymentMethodValue(for: paymentMethodType, intentConfiguration: intentConfig)
        }()

        // Set Setup Future Usage based on intent mode (matches handleDeferredIntentConfirmation logic)
        switch intentConfig.mode {
        case .setup(_, let setupFutureUsage):
            // Respect the SetupIntent's configured SFU value
            confirmationTokenParams.setupFutureUsage = setupFutureUsage.paymentIntentParamsValue
        case .payment:
            // For PaymentIntents, only set SFU if customer wants to save OR intent config requires it
            if shouldSavePaymentMethod {
                // TODO use value from intent/PMOSFU? Use the top level or PMO SFU value
                confirmationTokenParams.setupFutureUsage = .offSession
            }
        }

        // Set mandate data - use explicit or auto-generate for specific payment methods
        if let mandateData = mandateData {
            // Use explicit mandate data if provided
            confirmationTokenParams.mandateData = mandateData
        } else {
            let paymentMethodType = Self.paymentMethodType(from: confirmType)

            // Auto-generate for payment methods that require it with setup_future_usage
            let requiresMandateDataWithSFU: [STPPaymentMethodType] = [.payPal, .cashApp, .revolutPay, .amazonPay, .klarna, .satispay]
            // Check if we'll have setup_future_usage set (either explicitly by user or by intent config)
            let willHaveSetupFutureUsage = (confirmationTokenParams.setupFutureUsage != .none)
            if requiresMandateDataWithSFU.contains(paymentMethodType) && willHaveSetupFutureUsage {
                confirmationTokenParams.mandateData = .makeWithInferredValues()
            }

            // Auto-generate mandate data for bank-based payment methods (matches STPPaymentIntentParams.mandateData behavior)
            // These payment methods automatically get mandate data in the regular flow, so confirmation token flow should behave the same
            let bankBasedPaymentMethods: [STPPaymentMethodType] = [.AUBECSDebit, .bacsDebit, .bancontact, .iDEAL, .SEPADebit, .EPS, .sofort, .link, .USBankAccount]
            if bankBasedPaymentMethods.contains(paymentMethodType) {
                confirmationTokenParams.mandateData = .makeWithInferredValues()
            }
        }

        return confirmationTokenParams
    }
    
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
