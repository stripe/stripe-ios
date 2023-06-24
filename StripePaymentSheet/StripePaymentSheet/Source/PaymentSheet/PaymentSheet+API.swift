//
//  PaymentSheet+API.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 12/10/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeApplePay
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore
import UIKit

@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
extension PaymentSheet {
    /// `PaymentSheet.load()` result.
    enum LoadingResult {
        case success(
            intent: Intent,
            savedPaymentMethods: [STPPaymentMethod],
            isLinkEnabled: Bool
        )
        case failure(Error)
    }

    /// Confirms a PaymentIntent with the given PaymentOption and returns a PaymentResult
    static func confirm(
        configuration: PaymentSheet.Configuration,
        authenticationContext: STPAuthenticationContext,
        intent: Intent,
        paymentOption: PaymentOption,
        paymentHandler: STPPaymentHandler,
        isFlowController: Bool = false,
        paymentMethodID: String? = nil,
        completion: @escaping (PaymentSheetResult) -> Void
    ) {
        // Translates a STPPaymentHandler result to a PaymentResult
        let paymentHandlerCompletion: (STPPaymentHandlerActionStatus, NSObject?, NSError?) -> Void = { status, _, error in
            completion(makePaymentSheetResult(for: status, error: error))
        }

        switch paymentOption {
        // MARK: - Apple Pay
        case .applePay:
            guard
                let applePayContext = STPApplePayContext.create(
                    intent: intent,
                    configuration: configuration,
                    completion: completion
                )
            else {
                let message =
                    "Attempted Apple Pay but it's not supported by the device, not configured, or missing a presenter"
                assertionFailure(message)
                completion(.failed(error: PaymentSheetError.unknown(debugDescription: message)))
                return
            }
            applePayContext.presentApplePay()

        // MARK: - New Payment Method
        case let .new(confirmParams):
            switch intent {
            // MARK: ↪ PaymentIntent
            case .paymentIntent(let paymentIntent):
                // The Dashboard app cannot pass `paymentMethodParams` ie payment_method_data
                if configuration.apiClient.publishableKeyIsUserKey {
                    configuration.apiClient.createPaymentMethod(with: confirmParams.paymentMethodParams) {
                        paymentMethod,
                        error in
                        if let error = error {
                            completion(.failed(error: error))
                            return
                        }
                        let paymentIntentParams = confirmParams.makeDashboardParams(
                            paymentIntentClientSecret: paymentIntent.clientSecret,
                            paymentMethodID: paymentMethod?.stripeId ?? "",
                            configuration: configuration
                        )
                        paymentIntentParams.shipping = makeShippingParams(
                            for: paymentIntent,
                            configuration: configuration
                        )
                        paymentHandler.confirmPayment(
                            paymentIntentParams,
                            with: authenticationContext,
                            completion: paymentHandlerCompletion
                        )
                    }
                } else {
                    let params = makePaymentIntentParams(
                        confirmPaymentMethodType: .new(
                            params: confirmParams.paymentMethodParams,
                            shouldSave: confirmParams.saveForFutureUseCheckboxState == .selected
                        ),
                        paymentIntent: paymentIntent,
                        configuration: configuration
                    )
                    paymentHandler.confirmPayment(
                        params,
                        with: authenticationContext,
                        completion: paymentHandlerCompletion
                    )
                }
            // MARK: ↪ SetupIntent
            case .setupIntent(let setupIntent):
                let setupIntentParams = makeSetupIntentParams(
                    confirmPaymentMethodType: .new(
                        params: confirmParams.paymentMethodParams,
                        shouldSave: false
                    ),
                    setupIntent: setupIntent,
                    configuration: configuration
                )
                paymentHandler.confirmSetupIntent(
                    setupIntentParams,
                    with: authenticationContext,
                    completion: paymentHandlerCompletion
                )
            // MARK: ↪ Deferred Intent
            case .deferredIntent(_, let intentConfig):
                handleDeferredIntentConfirmation(
                    confirmType: .new(
                        params: confirmParams.paymentMethodParams,
                        shouldSave: confirmParams.saveForFutureUseCheckboxState == .selected
                    ),
                    configuration: configuration,
                    intentConfig: intentConfig,
                    authenticationContext: authenticationContext,
                    paymentHandler: paymentHandler,
                    isFlowController: isFlowController,
                    completion: completion
                )
            }

        // MARK: - Saved Payment Method
        case let .saved(paymentMethod):
            switch intent {
            // MARK: ↪ PaymentIntent
            case .paymentIntent(let paymentIntent):
                let paymentIntentParams = makePaymentIntentParams(confirmPaymentMethodType: .saved(paymentMethod), paymentIntent: paymentIntent, configuration: configuration)

                // The Dashboard app requires MOTO
                if configuration.apiClient.publishableKeyIsUserKey {
                    paymentIntentParams.paymentMethodOptions?.setMoto()
                }

                paymentHandler.confirmPayment(
                    paymentIntentParams,
                    with: authenticationContext,
                    completion: paymentHandlerCompletion
                )
            // MARK: ↪ SetupIntent
            case .setupIntent(let setupIntent):
                let setupIntentParams = makeSetupIntentParams(
                    confirmPaymentMethodType: .saved(paymentMethod),
                    setupIntent: setupIntent,
                    configuration: configuration
                )
                paymentHandler.confirmSetupIntent(
                    setupIntentParams,
                    with: authenticationContext,
                    completion: paymentHandlerCompletion
                )
            // MARK: ↪ Deferred Intent
            case .deferredIntent(_, let intentConfig):
                handleDeferredIntentConfirmation(
                    confirmType: .saved(paymentMethod),
                    configuration: configuration,
                    intentConfig: intentConfig,
                    authenticationContext: authenticationContext,
                    paymentHandler: paymentHandler,
                    isFlowController: isFlowController,
                    completion: completion
                )
            }
        // MARK: - Link
        case .link(let confirmOption):
            let confirmWithPaymentMethodParams: (STPPaymentMethodParams) -> Void = { paymentMethodParams in
                switch intent {
                case .paymentIntent(let paymentIntent):
                    let paymentIntentParams = STPPaymentIntentParams(clientSecret: paymentIntent.clientSecret)
                    paymentIntentParams.paymentMethodParams = paymentMethodParams
                    paymentIntentParams.returnURL = configuration.returnURL
                    paymentIntentParams.shipping = makeShippingParams(for: paymentIntent, configuration: configuration)
                    paymentHandler.confirmPayment(
                        paymentIntentParams,
                        with: authenticationContext,
                        completion: paymentHandlerCompletion
                    )
                case .setupIntent(let setupIntent):
                    let setupIntentParams = STPSetupIntentConfirmParams(clientSecret: setupIntent.clientSecret)
                    setupIntentParams.paymentMethodParams = paymentMethodParams
                    setupIntentParams.returnURL = configuration.returnURL
                    paymentHandler.confirmSetupIntent(
                        setupIntentParams,
                        with: authenticationContext,
                        completion: paymentHandlerCompletion
                    )
                case .deferredIntent(_, let intentConfig):
                    handleDeferredIntentConfirmation(
                        confirmType: .new(
                            params: paymentMethodParams,
                            shouldSave: false
                        ),
                        configuration: configuration,
                        intentConfig: intentConfig,
                        authenticationContext: authenticationContext,
                        paymentHandler: paymentHandler,
                        isFlowController: isFlowController,
                        completion: completion
                    )
                }
            }
            let confirmWithPaymentMethod: (STPPaymentMethod) -> Void = { paymentMethod in
                let mandateCustomerAcceptanceParams = STPMandateCustomerAcceptanceParams()
                let onlineParams = STPMandateOnlineParams(ipAddress: "", userAgent: "")
                // Tell Stripe to infer mandate info from client
                onlineParams.inferFromClient = true
                mandateCustomerAcceptanceParams.onlineParams = onlineParams
                mandateCustomerAcceptanceParams.type = .online
                let mandateData = STPMandateDataParams(customerAcceptance: mandateCustomerAcceptanceParams)
                switch intent {
                case .paymentIntent(let paymentIntent):
                    let paymentIntentParams = STPPaymentIntentParams(clientSecret: paymentIntent.clientSecret)
                    paymentIntentParams.paymentMethodId = paymentMethod.stripeId
                    paymentIntentParams.returnURL = configuration.returnURL
                    paymentIntentParams.shipping = makeShippingParams(for: paymentIntent, configuration: configuration)
                    paymentIntentParams.mandateData = mandateData
                    paymentHandler.confirmPayment(
                        paymentIntentParams,
                        with: authenticationContext,
                        completion: paymentHandlerCompletion
                    )
                case .setupIntent(let setupIntent):
                    let setupIntentParams = STPSetupIntentConfirmParams(clientSecret: setupIntent.clientSecret)
                    setupIntentParams.paymentMethodID = paymentMethod.stripeId
                    setupIntentParams.returnURL = configuration.returnURL
                    setupIntentParams.mandateData = mandateData
                    paymentHandler.confirmSetupIntent(
                        setupIntentParams,
                        with: authenticationContext,
                        completion: paymentHandlerCompletion
                    )
                case .deferredIntent(_, let intentConfig):
                    handleDeferredIntentConfirmation(
                        confirmType: .saved(paymentMethod),
                        configuration: configuration,
                        intentConfig: intentConfig,
                        authenticationContext: authenticationContext,
                        paymentHandler: paymentHandler,
                        isFlowController: isFlowController,
                        completion: completion
                    )
                }
            }

            let confirmWithPaymentDetails:
                (
                    PaymentSheetLinkAccount,
                    ConsumerPaymentDetails
                ) -> Void = { linkAccount, paymentDetails in
                    guard let paymentMethodParams = linkAccount.makePaymentMethodParams(from: paymentDetails) else {
                        let error = PaymentSheetError.unknown(
                            debugDescription: "Paying with Link without valid session"
                        )
                        completion(.failed(error: error))
                        return
                    }

                    confirmWithPaymentMethodParams(paymentMethodParams)
                }

            let createPaymentDetailsAndConfirm:
                (
                    PaymentSheetLinkAccount,
                    STPPaymentMethodParams
                ) -> Void = { linkAccount, paymentMethodParams in
                    guard linkAccount.sessionState == .verified else {
                        assertionFailure("Creating payment details without a verified session")
                        // Attempt to confirm directly with params
                        confirmWithPaymentMethodParams(paymentMethodParams)
                        return
                    }

                    linkAccount.createPaymentDetails(with: paymentMethodParams) { result in
                        switch result {
                        case .success(let paymentDetails):
                            confirmWithPaymentDetails(linkAccount, paymentDetails)
                        case .failure:
                            assertionFailure("Failed to create payment details")
                            // Attempt to confirm directly with params
                            confirmWithPaymentMethodParams(paymentMethodParams)
                        }
                    }
                }

            switch confirmOption {
            case .wallet:
                let linkController = PayWithLinkController(intent: intent, configuration: configuration)
                linkController.present(completion: completion)
            case .signUp(let linkAccount, let phoneNumber, let legalName, let paymentMethodParams):
                linkAccount.signUp(with: phoneNumber, legalName: legalName, consentAction: .checkbox) { result in
                    switch result {
                    case .success:
                        STPAnalyticsClient.sharedClient.logLinkSignupComplete()
                        createPaymentDetailsAndConfirm(linkAccount, paymentMethodParams)
                    case .failure(let error as NSError):
                        STPAnalyticsClient.sharedClient.logLinkSignupFailure()

                        let isUserInputError =
                            (error.domain == STPError.stripeDomain
                                && error.code == STPErrorCode.invalidRequestError.rawValue)

                        if isUserInputError {
                            // The request failed because invalid info was provided. In this case
                            // we should surface the error and let the user correct the information
                            // and try again.
                            completion(.failed(error: error))
                        } else {
                            // Attempt to confirm directly with params as a fallback.
                            confirmWithPaymentMethodParams(paymentMethodParams)
                        }
                    }
                }
            case .withPaymentDetails(let linkAccount, let paymentDetails):
                confirmWithPaymentDetails(linkAccount, paymentDetails)
            case .withPaymentMethodParams(let linkAccount, let paymentMethodParams):
                createPaymentDetailsAndConfirm(linkAccount, paymentMethodParams)
            case .withPaymentMethod(let paymentMethod):
                confirmWithPaymentMethod(paymentMethod)
            }
        }
    }

    /// Fetches the PaymentIntent or SetupIntent and Customer's saved PaymentMethods
    static func load(
        mode: InitializationMode,
        configuration: Configuration,
        completion: @escaping (LoadingResult) -> Void
    ) {
        let intentPromise = Promise<Intent>()
        let paymentMethodsPromise = Promise<[STPPaymentMethod]>()
        let loadSpecsPromise = Promise<Void>()

        intentPromise.observe { result in
            switch result {
            case .success(let intent):
                paymentMethodsPromise.observe { result in
                    switch result {
                    case .success(let paymentMethods):
                        // Filter out payment methods that the PI/SI or PaymentSheet doesn't support
                        // TODO: We're fetching the customer's saved card and us_bank_account PMs, and then filtering - this is backwards!
                        let savedPaymentMethods = paymentMethods
                            .filter { intent.recommendedPaymentMethodTypes.contains($0.type) }
                            .filter {
                                $0.paymentSheetPaymentMethodType().supportsSavedPaymentMethod(
                                    configuration: configuration,
                                    intent: intent
                                )
                            }

                        // Warn the merchant if we see unactivated payment method types in the Intent
                        warnUnactivatedIfNeeded(unactivatedPaymentMethodTypes: intent.unactivatedPaymentMethodTypes)
                        // Ensure that there's at least 1 payment method type available for the intent and configuration.
                        let paymentMethodTypes = PaymentMethodType.filteredPaymentMethodTypes(from: intent, configuration: configuration)
                        guard !paymentMethodTypes.isEmpty else {
                            completion(.failure(PaymentSheetError.noPaymentMethodTypesAvailable(intentPaymentMethods: intent.recommendedPaymentMethodTypes)))
                            return
                        }

                        let linkAccountPromise = PaymentSheet.lookupLinkAccount(
                            intent: intent,
                            configuration: configuration
                        )

                        loadSpecsPromise.observe { _ in
                            // Overwrite the form specs that were already loaded from disk
//                            switch intent {
//                            case .paymentIntent(let paymentIntent):
//                                _ = FormSpecProvider.shared.loadFrom(paymentIntent.allResponseFields["payment_method_specs"] ?? [String: Any]())
//                            case .setupIntent:
//                                break // Not supported
//                            case .deferredIntent(elementsSession: let elementsSession, intentConfig: _):
//                                _ = FormSpecProvider.shared.loadFrom(elementsSession.paymentMethodSpecs as Any)
//                            }
//                            linkAccountPromise.observe { linkAccountResult in
//                                switch linkAccountResult {
//                                case .success(let linkAccount):
//                                    LinkAccountContext.shared.account = linkAccount
//
//                                    completion(
//                                        .success(
//                                            intent: intent,
//                                            savedPaymentMethods: savedPaymentMethods,
//                                            isLinkEnabled: intent.supportsLink
//                                        )
//                                    )
//                                case .failure:
//                                    LinkAccountContext.shared.account = nil
//
//                                    // Move forward without Link
//                                    completion(
//                                        .success(
//                                            intent: intent,
//                                            savedPaymentMethods: savedPaymentMethods,
//                                            isLinkEnabled: false
//                                        )
//                                    )
//                                }
//                            }
                        }
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
        
        Task {
            do {
                // 1a. Fetch PaymentIntent, SetupIntent, or ElementsSession
                async let _intent = fetchIntent(mode: mode, configuration: configuration)
                
                // 1b. List the Customer's saved PaymentMethods
                async let savedPaymentMethods = fetchSavedPaymentMethods(configuration: configuration)

                // 1c. Load misc singletons
                async let _ = loadMiscellaneousSingletons() // note: Swift implicitly waits for this before exiting the scope.
                
                let intent = try await _intent
                // Overwrite the form specs that were already loaded from disk
                switch intent {
                case .paymentIntent(let paymentIntent):
                    _ = FormSpecProvider.shared.loadFrom(paymentIntent.allResponseFields["payment_method_specs"] ?? [String: Any]())
                case .setupIntent:
                    break // Not supported
                case .deferredIntent(elementsSession: let elementsSession, intentConfig: _):
                    _ = FormSpecProvider.shared.loadFrom(elementsSession.paymentMethodSpecs as Any)
                }
                
                // Load link account session. Continue without Link if it errors.
                let linkAccount = try? await _lookupLinkAccount(intent: intent, configuration: configuration)
                LinkAccountContext.shared.account = linkAccount
                
                // Filter out payment methods that the PI/SI or PaymentSheet doesn't support
                // TODO: We're fetching the customer's saved card and us_bank_account PMs, and then filtering - this is backwards!
                let filteredSavedPaymentMethods = try await savedPaymentMethods
                    .filter { intent.recommendedPaymentMethodTypes.contains($0.type) }
                    .filter {
                        $0.paymentSheetPaymentMethodType().supportsSavedPaymentMethod(
                            configuration: configuration,
                            intent: intent
                        )
                    }

                // Warn the merchant if we see unactivated payment method types in the Intent
                warnUnactivatedIfNeeded(unactivatedPaymentMethodTypes: intent.unactivatedPaymentMethodTypes)
                // Ensure that there's at least 1 payment method type available for the intent and configuration.
                let paymentMethodTypes = PaymentMethodType.filteredPaymentMethodTypes(from: intent, configuration: configuration)
                guard !paymentMethodTypes.isEmpty else {
                    completion(.failure(PaymentSheetError.noPaymentMethodTypesAvailable(intentPaymentMethods: intent.recommendedPaymentMethodTypes)))
                    return
                }
                
                completion(
                    .success(
                        intent: intent,
                        savedPaymentMethods: filteredSavedPaymentMethods,
                        isLinkEnabled: intent.supportsLink
                    )
                )
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    /// Loads miscellaneous singletons
    static func loadMiscellaneousSingletons() async -> Bool {
        await withCheckedContinuation { continuation in
            Task {
                AddressSpecProvider.shared.loadAddressSpecs {
                    // Load form specs
                    FormSpecProvider.shared.load { _ in
                        // Load BSB data
                        BSBNumberProvider.shared.loadBSBData {
                            continuation.resume(returning: true)
                        }
                    }
                }
            }
        }
    }
    
    static func lookupLinkAccount(
        intent: Intent,
        configuration: Configuration
    ) -> Promise<PaymentSheetLinkAccount?> {
        // Only lookup the consumer account if Link is supported
        guard intent.supportsLink else {
            return .init(value: nil)
        }

        let promise = Promise<PaymentSheetLinkAccount?>()

        let linkAccountService = LinkAccountService(apiClient: configuration.apiClient)

        let consumerSessionLookupBlock: (String?) -> Void = { email in
            if let email = email, linkAccountService.hasEmailLoggedOut(email: email) {
                promise.resolve(with: nil)
                return
            }

            linkAccountService.lookupAccount(withEmail: email) { result in
                switch result {
                case .success(let linkAccount):
                    promise.resolve(with: linkAccount)
                case .failure(let error):
                    promise.reject(with: error)
                }
            }
        }

        if linkAccountService.hasSessionCookie {
            consumerSessionLookupBlock(nil)
        } else if let email = linkAccountService.getLastSignUpEmail() {
            consumerSessionLookupBlock(email)
        } else if let email = configuration.defaultBillingDetails.email {
            consumerSessionLookupBlock(email)
        } else if let customerID = configuration.customer?.id,
            let ephemeralKey = configuration.customer?.ephemeralKeySecret
        {
            configuration.apiClient.retrieveCustomer(customerID, using: ephemeralKey) { customer, _ in
                // If there's an error in this call we can just ignore it
                consumerSessionLookupBlock(customer?.email)
            }
        } else {
            promise.resolve(with: nil)
        }

        return promise
    }

    static func _lookupLinkAccount(
        intent: Intent,
        configuration: Configuration
    ) async throws -> PaymentSheetLinkAccount? {
        // Only lookup the consumer account if Link is supported
        guard intent.supportsLink else {
            return nil
        }

        let linkAccountService = LinkAccountService(apiClient: configuration.apiClient)
        func lookUpConsumerSession(email: String?) async throws -> PaymentSheetLinkAccount? {
            if let email = email, linkAccountService.hasEmailLoggedOut(email: email) {
                return nil
            }

            return try await withCheckedThrowingContinuation { continuation in
                linkAccountService.lookupAccount(withEmail: email) { result in
                    switch result {
                    case .success(let linkAccount):
                        continuation.resume(with: .success(linkAccount))
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            }
        }

        if linkAccountService.hasSessionCookie {
            return try await lookUpConsumerSession(email: nil)
        } else if let email = linkAccountService.getLastSignUpEmail() {
            return try await lookUpConsumerSession(email: email)
        } else if let email = configuration.defaultBillingDetails.email {
            return try await lookUpConsumerSession(email: email)
        } else if let customerID = configuration.customer?.id,
            let ephemeralKey = configuration.customer?.ephemeralKeySecret
        {
            let customer = try await configuration.apiClient.retrieveCustomer(customerID, using: ephemeralKey)
            // If there's an error in this call we can just ignore it
            return try await lookUpConsumerSession(email: customer.email)
        } else {
            return nil
        }
    }
    
    static func fetchIntent(mode: InitializationMode, configuration: Configuration) async throws -> Intent {
        switch mode {
        case .paymentIntentClientSecret(let clientSecret):
            let paymentIntent: STPPaymentIntent
            do {
                paymentIntent = try await configuration.apiClient.retrievePaymentIntentWithPreferences(withClientSecret: clientSecret)
            } catch {
                // Fallback to regular retrieve PI when retrieve PI with preferences fails
                paymentIntent = try await configuration.apiClient.retrievePaymentIntent(clientSecret: clientSecret)
            }
            guard ![.succeeded, .canceled, .requiresCapture].contains(paymentIntent.status) else {
                // Error if the PaymentIntent is in a terminal state
                let message = "PaymentSheet received a PaymentIntent in a terminal state: \(paymentIntent.status)"
                throw PaymentSheetError.unknown(debugDescription: message)
            }
            return .paymentIntent(paymentIntent)
        case .setupIntentClientSecret(let clientSecret):
            let setupIntent: STPSetupIntent
            do {
                setupIntent = try await configuration.apiClient.retrieveSetupIntentWithPreferences(withClientSecret: clientSecret)
            } catch {
                // Fallback to regular retrieve SI when retrieve SI with preferences fails
                setupIntent = try await configuration.apiClient.retrieveSetupIntent(clientSecret: clientSecret)
            }
            guard ![.succeeded, .canceled].contains(setupIntent.status) else {
                // Error if the SetupIntent is in a terminal state
                let message = "PaymentSheet received a SetupIntent in a terminal state: \(setupIntent.status)"
                throw PaymentSheetError.unknown(debugDescription: message)
            }
            return .setupIntent(setupIntent)

        case .deferredIntent(let intentConfig):
            let elementsSession = try await configuration.apiClient.retrieveElementsSession(withIntentConfig: intentConfig)
            return .deferredIntent(elementsSession: elementsSession, intentConfig: intentConfig)
        }
    }
    
    static func fetchSavedPaymentMethods(configuration: Configuration) async throws -> [STPPaymentMethod] {
        let savedPaymentMethodTypes: [STPPaymentMethodType] = [.card, .USBankAccount]  // hardcoded for now
        guard let customerID = configuration.customer?.id, let ephemeralKey = configuration.customer?.ephemeralKeySecret else {
            return []
        }
        return try await withCheckedThrowingContinuation { continuation in
            configuration.apiClient.listPaymentMethods(
                forCustomer: customerID,
                using: ephemeralKey,
                types: savedPaymentMethodTypes
            ) { paymentMethods, error in
                guard let paymentMethods = paymentMethods, error == nil else {
                    let error = error ?? PaymentSheetError.unknown(debugDescription: "Failed to retrieve PaymentMethods for the customer")
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: paymentMethods)
            }
        }
    }

    // MARK: - Helper methods

    private static func warnUnactivatedIfNeeded(unactivatedPaymentMethodTypes: [STPPaymentMethodType]) {
        guard !unactivatedPaymentMethodTypes.isEmpty else { return }

        let message = """
            [Stripe SDK] Warning: Your Intent contains the following payment method types which are activated for test mode but not activated for live mode: \(unactivatedPaymentMethodTypes.map({ $0.displayName }).joined(separator: ",")). These payment method types will not be displayed in live mode until they are activated. To activate these payment method types visit your Stripe dashboard.
            More information: https://support.stripe.com/questions/activate-a-new-payment-method
            """
        print(message)
    }

    static func makeShippingParams(for paymentIntent: STPPaymentIntent, configuration: PaymentSheet.Configuration)
        -> STPPaymentIntentShippingDetailsParams?
    {
        let params = STPPaymentIntentShippingDetailsParams(paymentSheetConfiguration: configuration)
        // If a merchant attaches shipping to the PI on their server, the /confirm endpoint will error if we update shipping with a “requires secret key” error message.
        // To accommodate this, don't attach if our shipping is the same as the PI's shipping
        guard !isEqual(paymentIntent.shipping, params) else {
            return nil
        }
        return params
    }

    enum ConfirmPaymentMethodType {
        case saved(STPPaymentMethod)
        /// - paymentMethod: Pass this if you created a PaymentMethod already (e.g. for the deferred flow).
        case new(params: STPPaymentMethodParams, paymentMethod: STPPaymentMethod? = nil, shouldSave: Bool)

        var shouldSave: Bool {
            switch self {
            case .saved:
                return false
            case .new(_, _, let shouldSave):
                return shouldSave
            }
        }
    }

    static func makePaymentIntentParams(
        confirmPaymentMethodType: ConfirmPaymentMethodType,
        paymentIntent: STPPaymentIntent,
        configuration: PaymentSheet.Configuration
    ) -> STPPaymentIntentParams {
        let params: STPPaymentIntentParams
        let shouldSave: Bool
        let paymentMethodType: STPPaymentMethodType
        switch confirmPaymentMethodType {
        case .saved(let paymentMethod):
            shouldSave = false
            paymentMethodType = paymentMethod.type
            params = STPPaymentIntentParams(clientSecret: paymentIntent.clientSecret, paymentMethodType: paymentMethod.type)
            params.paymentMethodId = paymentMethod.stripeId
        case let .new(paymentMethodParams, paymentMethod, _shouldSave):
            shouldSave = _shouldSave
            if let paymentMethod = paymentMethod {
                paymentMethodType = paymentMethod.type
                params = STPPaymentIntentParams(clientSecret: paymentIntent.clientSecret, paymentMethodType: paymentMethod.type)
                params.paymentMethodId = paymentMethod.stripeId
            } else {
                params = STPPaymentIntentParams(clientSecret: paymentIntent.clientSecret)
                params.paymentMethodParams = paymentMethodParams
                paymentMethodType = paymentMethodParams.type
            }

            // Paypal requires mandate_data if setting up
            if params.paymentMethodType == .payPal
                && paymentIntent.setupFutureUsage == .offSession
            {
                params.mandateData = .makeWithInferredValues()
            }
        }

        let options = STPConfirmPaymentMethodOptions()
        options.setSetupFutureUsageIfNecessary(shouldSave, paymentMethodType: paymentMethodType, customer: configuration.customer)
        params.paymentMethodOptions = options
        params.returnURL = configuration.returnURL
        params.shipping = makeShippingParams(for: paymentIntent, configuration: configuration)
        return params
    }

    static func makeSetupIntentParams(
        confirmPaymentMethodType: ConfirmPaymentMethodType,
        setupIntent: STPSetupIntent,
        configuration: PaymentSheet.Configuration
    ) -> STPSetupIntentConfirmParams {
        let params: STPSetupIntentConfirmParams
        switch confirmPaymentMethodType {
        case let .saved(paymentMethod):
            params = STPSetupIntentConfirmParams(
                clientSecret: setupIntent.clientSecret,
                paymentMethodType: paymentMethod.type
            )
            params.paymentMethodID = paymentMethod.stripeId
        case let .new(paymentMethodParams, paymentMethod, _):
            if let paymentMethod {
                params = STPSetupIntentConfirmParams(
                    clientSecret: setupIntent.clientSecret,
                    paymentMethodType: paymentMethod.type
                )
                params.paymentMethodID = paymentMethod.stripeId
            } else {
                params = STPSetupIntentConfirmParams(clientSecret: setupIntent.clientSecret)
                params.paymentMethodParams = paymentMethodParams
            }
            // Paypal requires mandate_data if setting up
            if params.paymentMethodType == .payPal {
                params.mandateData = .makeWithInferredValues()
            }
        }
        params.returnURL = configuration.returnURL
        return params
    }
}

/// A helper method to compare shipping details
private func isEqual(_ lhs: STPPaymentIntentShippingDetails?, _ rhs: STPPaymentIntentShippingDetailsParams?) -> Bool {
    guard let lhs = lhs, let rhs = rhs else {
        // One or both are nil, so they're only equal if they're both nil
        return lhs == nil && rhs == nil
    }
    // Convert lhs to a STPPaymentIntentShippingDetailsAddressParams for ease of comparison
    let addressParams = STPPaymentIntentShippingDetailsAddressParams(line1: lhs.address?.line1 ?? "")
    addressParams.line2 = lhs.address?.line2
    addressParams.city = lhs.address?.city
    addressParams.state = lhs.address?.state
    addressParams.postalCode = lhs.address?.postalCode
    addressParams.country = lhs.address?.country

    let lhsConverted = STPPaymentIntentShippingDetailsParams(address: addressParams, name: lhs.name ?? "")
    lhsConverted.phone = lhs.phone

    return rhs == lhsConverted
}
