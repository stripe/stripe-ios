//
//  PaymentSheetLoader.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 6/23/23.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore

final class PaymentSheetLoader {
    /// All the data that PaymentSheetLoader loaded.
    struct LoadResult {
        let intent: Intent
        let elementsSession: STPElementsSession
        let savedPaymentMethods: [STPPaymentMethod]
        /// The payment method types that should be shown (i.e. filtered)
        let paymentMethodTypes: [PaymentSheet.PaymentMethodType]
    }

    enum IntegrationShape {
        case paymentSheet
        case flowController
        case embedded

        var canDefaultToLinkOrApplePay: Bool {
            switch self {
            case .paymentSheet:
                return false
            case .flowController, .embedded:
                return true
            }
        }
    }

    static func load(
        mode: PaymentSheet.InitializationMode,
        configuration: PaymentElementConfiguration,
        analyticsHelper: PaymentSheetAnalyticsHelper,
        integrationShape: IntegrationShape,
        isUpdate: Bool = false,
        completion: @escaping (Result<(LoadResult, ConfirmationChallenge), Error>) -> Void
    ) {
        Task { @MainActor in
            do {
                let (loadResult, confirmationChallenge) = try await load(mode: mode, configuration: configuration, analyticsHelper: analyticsHelper, integrationShape: integrationShape, isUpdate: isUpdate)
                completion(.success((loadResult, confirmationChallenge)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Loads everything needed to render and use all MPE variants (PaymentSheet, FlowController, EmbeddedPaymentElement).
    /// ⚠️ Everything that takes time to load (eg fetched from network or disk) should be in this method so that `logLoadSucceeded` accurately captures the amount of time it took to load.
    @MainActor
    static func load(
        mode: PaymentSheet.InitializationMode,
        configuration: PaymentElementConfiguration,
        analyticsHelper: PaymentSheetAnalyticsHelper,
        integrationShape: IntegrationShape,
        isUpdate: Bool = false
    ) async throws -> (LoadResult, ConfirmationChallenge) {
        let loadTimings: LoadTimings = .init(loadingStartDate: Date())
        loadTimings.logStart("logLoadStarted")
        analyticsHelper.logLoadStarted(isUpdate: isUpdate)
        loadTimings.logEnd("logLoadStarted")
        // Note loadTimings isn't on PaymentSheetAnalyticsHelper because of an issue where multiple `update` calls can trigger concurrent loads, overwriting the storage of the single analytics helper. We need storage specific to *this* load.
        do {
            // Validate inputs
            if !mode.isDeferred && configuration.apiClient.publishableKeyIsUserKey {
                // User keys can't pass payment_method_data directly to /confirm, which is what the non-deferred intent flows do
                assertionFailure("Dashboard isn't supported in non-deferred intent flows")
            }
            if case .deferredIntent(let intentConfiguration) = mode,
               let error = intentConfiguration.validate() {
                throw error
            }
            if case .checkoutSession = mode, configuration.customer != nil {
                stpAssertionFailure("Configuration.customer must not be set when using a CheckoutSession. The CheckoutSession manages its own customer.")
                throw PaymentSheetError.integrationError(nonPIIDebugDescription: "PaymentSheet.Configuration.customer must not be set when using a CheckoutSession.")
            }
            // defaultBillingDetails.email is populated from the CheckoutSession's customerEmail (if not already set) by applyAddressOverrides, which runs before the loader.
            if case .checkoutSession = mode, configuration.defaultBillingDetails.email == nil {
                stpAssertionFailure("An email address is required when using a CheckoutSession. Set configuration.defaultBillingDetails.email or ensure the CheckoutSession has a customer_email.")
                throw PaymentSheetError.integrationError(nonPIIDebugDescription: "An email address is required when using a CheckoutSession. Set PaymentSheet.Configuration.defaultBillingDetails.email or ensure the CheckoutSession has a customer_email.")
            }

            // Fetch ElementsSession
            // ⚠️ Note using `async let` instead of Tasks here triggered a crash when compiling with Xcode 26.4 / Swift 6.3
            let elementsSessionAndIntentTask = Task {
                try await fetchElementsSessionAndIntent(mode: mode, configuration: configuration, analyticsHelper: analyticsHelper, loadTimings: loadTimings)
            }

            // Fetch Customer email if using EK for Link and it wasn't provided in `configuration`. If using CS, Customer will be in v1/e/s response.
            let prefetchedLinkEmailAndSourceTask = Task {
                try? await getCustomerEmailForLinkWithEphemeralKey(configuration: configuration, loadTimings: loadTimings)
            }
            // Fetch Customer SPMs if using EK b/c they're not in the v1/e/s response.
            let prefetchedSavedPaymentMethodsTask = Task {
                try await fetchSavedPaymentMethodsWithEphemeralKey(configuration: configuration, loadTimings: loadTimings)
            }

            // Load misc singletons
            loadTimings.logStart("loadMiscellaneousSingletons")
            await loadMiscellaneousSingletons()
            loadTimings.logEnd("loadMiscellaneousSingletons")

            let elementsSessionAndIntent = try await elementsSessionAndIntentTask.value
            let intent = elementsSessionAndIntent.intent
            let elementsSession = elementsSessionAndIntent.elementsSession
            // Overwrite the form specs that were already loaded from disk
            loadTimings.logStart("loadFormSpecs")
            switch intent {
            case .paymentIntent, .deferredIntent, .checkoutSession:
                if !elementsSession.isBackupInstance {
                    _ = FormSpecProvider.shared.loadFrom(elementsSession.paymentMethodSpecs as Any)
                }
            case .setupIntent:
                break // Not supported
            }
            loadTimings.logEnd("loadFormSpecs")

            let isLinkEnabled = PaymentSheet.isLinkEnabled(elementsSession: elementsSession, configuration: configuration)
            let lookupLinkAccountTask = Task { @MainActor in
                let prefetchedLinkEmailAndSource = await prefetchedLinkEmailAndSourceTask.value
                let linkAccount = try? await Self.lookupLinkAccount(
                    elementsSession: elementsSession,
                    configuration: configuration,
                    prefetchedEmailAndSource: prefetchedLinkEmailAndSource,
                    loadTimings: loadTimings,
                    isUpdate: isUpdate
                )

                // We don't want to set the global singleton if we timed out, because that means setting it after MPE has finished loading, which the code is not necessarily expecting.
                guard !Task.isCancelled else { return }
                if isLinkEnabled {
                    LinkAccountContext.shared.account = linkAccount
                }
                Self.logLinkExperimentExposures(
                    elementsSession: elementsSession,
                    configuration: configuration,
                    linkAccount: linkAccount,
                    analyticsHelper: analyticsHelper
                )
            }
            // Only block on link lookup if it's enabled.
            var didLinkLookupTimeOut: Bool?
            if isLinkEnabled {
                let result = await withTimeout(5.0) {
                    await lookupLinkAccountTask.value
                }
                switch result {
                case .success:
                    didLinkLookupTimeOut = false
                case .failure(let error):
                    if error is TimeoutError {
                        didLinkLookupTimeOut = true
                        // Since we're using unstructured Tasks, we have to manually cancel it.
                        lookupLinkAccountTask.cancel()
                    }
                }
            }

            loadTimings.logStart("computePaymentMethodTypes")
            let isApplePayEnabled = PaymentSheet.isApplePayEnabled(elementsSession: elementsSession, configuration: configuration)

            // Disable FC Lite if killswitch is enabled
            let isFcLiteKillswitchEnabled = elementsSession.flags["elements_disable_fc_lite"] == true
            FinancialConnectionsSDKAvailability.fcLiteKillswitchEnabled = isFcLiteKillswitchEnabled

            let remoteFcLiteOverrideEnabled = elementsSession.flags["elements_prefer_fc_lite"] == true
            FinancialConnectionsSDKAvailability.remoteFcLiteOverride = remoteFcLiteOverrideEnabled

            let paymentMethodTypes = PaymentSheet.PaymentMethodType.filteredPaymentMethodTypes(from: intent, elementsSession: elementsSession, configuration: configuration, logAvailability: true)

            // Assert if using konbini or blik with confirmation tokens
            if case .deferredIntent(let intentConfiguration) = mode,
               intentConfiguration.confirmationTokenConfirmHandler != nil {
                if paymentMethodTypes.contains(.stripe(.konbini)) || paymentMethodTypes.contains(.stripe(.blik)) {
                    stpAssertionFailure("Konbini and BLIK payment methods are not supported with ConfirmationTokens. Use init(mode:paymentMethodTypes:onBehalfOf:paymentMethodConfigurationId:confirmHandler:requireCVCRecollection:) instead.")
                }
            }

            // Ensure that there's at least 1 payment method type available for the intent and configuration.
            guard !paymentMethodTypes.isEmpty else {
                throw PaymentSheetError.noPaymentMethodTypesAvailable(intentPaymentMethods: elementsSession.orderedPaymentMethodTypes)
            }
            loadTimings.logEnd("computePaymentMethodTypes")

            // Initialize telemetry. Don't wait for this to finish to return.
            STPTelemetryClient.shared.sendTelemetryData()

            // Filter out saved payment methods that the PI/SI or PaymentSheet doesn't support
            let prefetchedSavedPaymentMethods = try await prefetchedSavedPaymentMethodsTask.value
            let filteredSavedPaymentMethods = filterSavedPaymentMethods(intent: intent, elementsSession: elementsSession, configuration: configuration, prefetchedSPMs: prefetchedSavedPaymentMethods, loadTimings: loadTimings)

            let loadResult = LoadResult(
                intent: intent,
                elementsSession: elementsSession,
                savedPaymentMethods: filteredSavedPaymentMethods,
                paymentMethodTypes: paymentMethodTypes
            )
            let confirmationChallenge = ConfirmationChallenge(
                elementsSession: elementsSession,
                stripeAttest: configuration.apiClient.stripeAttest
            )

            // This is hacky; the logic to determine the default selected payment method belongs to the SavedPaymentOptionsViewController. We invoke it here just to report it to analytics before that VC loads.
            loadTimings.logStart("makeViewModels")
            let (defaultSelectedIndex, paymentOptionsViewModels) = SavedPaymentOptionsViewController.makeViewModels(
                savedPaymentMethods: filteredSavedPaymentMethods,
                customerID: configuration.customer?.id,
                showApplePay: integrationShape.canDefaultToLinkOrApplePay ? isApplePayEnabled : false,
                showLink: integrationShape.canDefaultToLinkOrApplePay ? isLinkEnabled : false,
                elementsSession: elementsSession,
                defaultPaymentMethod: elementsSession.customer?.getDefaultPaymentMethod()
            )

            // Temporary band-aid for pre-loading card art: fire-and-forget fetch to warm the in-meory cache for PS.FC
            // and embedded PaymentOptionDisplayData APIs.
            // TODO: Revisit overall pre-loading approach to make this work for other payment methods
            if let defaultPaymentMethod = paymentOptionsViewModels.stp_boundSafeObject(at: defaultSelectedIndex),
               case .saved(let stpPaymentMethod) = defaultPaymentMethod {
                stpPaymentMethod.preloadCardArtImage(cardArtEnabled: configuration.appearance.cardArtEnabled)
            }
            loadTimings.logEnd("makeViewModels")

            // Send load finished analytic
            // ⚠️ Important: Log load succeeded at the very end, to ensure it measures the entire amount of time this method took.
            analyticsHelper.logLoadSucceeded(
                intent: intent,
                elementsSession: elementsSession,
                defaultPaymentMethod: paymentOptionsViewModels.stp_boundSafeObject(at: defaultSelectedIndex),
                orderedPaymentMethodTypes: paymentMethodTypes,
                loadTimings: loadTimings,
                isUpdate: isUpdate,
                hasCardArt: hasCardArt(savedPaymentMethods: filteredSavedPaymentMethods, appearance: configuration.appearance),
                didLinkLookupTimeOut: didLinkLookupTimeOut
            )
            return (loadResult, confirmationChallenge)
        } catch {
            analyticsHelper.logLoadFailed(error: error, loadTimings: loadTimings, isUpdate: isUpdate)
            throw error
        }
    }

    /// Returns `true` if the card art feature is enabled and at least one saved card has a card art image URL.
    static func hasCardArt(savedPaymentMethods: [STPPaymentMethod], appearance: PaymentSheet.Appearance) -> Bool {
        appearance.cardArtEnabled && savedPaymentMethods.contains { $0.type == .card && $0.card?.cardArt?.artImage?.url != nil }
    }

    // MARK: - Helper methods that load things

    /// Loads miscellaneous singletons
    @MainActor
    static func loadMiscellaneousSingletons() async {
        await withCheckedContinuation { continuation in
            AddressSpecProvider.shared.loadAddressSpecs {
                // Load form specs
                FormSpecProvider.shared.load { _ in
                    // Load BSB data
                    BSBNumberProvider.shared.loadBSBData {
                        continuation.resume()
                    }
                }
            }
        }
    }

    @MainActor
    static func lookupLinkAccount(
        elementsSession: STPElementsSession,
        configuration: PaymentElementConfiguration,
        prefetchedEmailAndSource: (email: String, source: EmailSource)?,
        loadTimings: LoadTimings,
        isUpdate: Bool
    ) async throws -> PaymentSheetLinkAccount? {
        // If we already have a verified Link account and the merchant is just calling `update` on FlowController or Embedded,
        // keep the account logged-in. Otherwise, the user has to verify via OTP again.
        if isUpdate, let currentLinkAccount = LinkAccountContext.shared.account, currentLinkAccount.sessionState == .verified {
            return currentLinkAccount
        }

        // Lookup Link account if Link is enabled, or if Link is disabled due to the holdback experiment (to collect experiment dimensions).
        let isLinkEnabled = PaymentSheet.isLinkEnabled(elementsSession: elementsSession, configuration: configuration)
        let isLinkInHoldbackExperiment = PaymentSheet.isLinkInHoldbackExperiment(elementsSession: elementsSession)
        let isLookupForHoldbackEnabled = elementsSession.flags["elements_disable_link_global_holdback_lookup"] != true

        guard isLinkEnabled || (isLinkInHoldbackExperiment && isLookupForHoldbackEnabled) else {
            return nil
        }
        loadTimings.logStart("lookUpLinkAccount")
        defer {
            loadTimings.logEnd("lookUpLinkAccount")
        }

        // Don't log this as a lookup on the backend side if Link is not enabled.
        // As in, this will be true when this lookup is only happening to gather dimensions for the holdback experiment.
        // Note: When the holdback experiment is over, we can remove this parameter from the lookup call.
        let doNotLogConsumerFunnelEvent = !isLinkEnabled

        // This lookup call will only happen if we have access to a user's email:
        // There are a couple different sources.
        let lookupEmail: (email: String, source: EmailSource)
        if let email = configuration.defaultBillingDetails.email {
            // 1. Merchant provided in `defaultBillingDetails`
            lookupEmail = (email, EmailSource.customerEmail)
        } else if let prefetchedEmailAndSource {
            // 2. We fetched the Customer object before calling this method to get its email when using EKs
            lookupEmail = prefetchedEmailAndSource
        } else if let email = elementsSession.customer?.email {
            // 3. The v1/e/s response returns the email when using CustomerSession
            lookupEmail = (email, EmailSource.customerObject)
        } else {
            return nil
        }

        let linkAccountService = LinkAccountService(apiClient: configuration.apiClient, elementsSession: elementsSession)
        return try await linkAccountService.lookupAccount(
            withEmail: lookupEmail.email,
            emailSource: lookupEmail.source,
            doNotLogConsumerFunnelEvent: doNotLogConsumerFunnelEvent
        )
    }

    @MainActor
    private static func logLinkExperimentExposures(
        elementsSession: STPElementsSession,
        configuration: PaymentElementConfiguration,
        linkAccount: PaymentSheetLinkAccount?,
        analyticsHelper: PaymentSheetAnalyticsHelper
    ) {
        Task {
            guard let arbId = elementsSession.experimentsData?.arbId else {
                return
            }
            let linkGlobalHoldbackExperiment = LinkGlobalHoldback(
                arbId: arbId,
                session: elementsSession,
                configuration: configuration,
                linkAccount: linkAccount,
                integrationShape: analyticsHelper.integrationShape
            )
            analyticsHelper.logExposure(experiment: linkGlobalHoldbackExperiment)

            let linkGlobalHoldbackAAExperiment = LinkGlobalHoldbackAA(
                arbId: arbId,
                session: elementsSession,
                configuration: configuration,
                linkAccount: linkAccount,
                integrationShape: analyticsHelper.integrationShape
            )
            analyticsHelper.logExposure(experiment: linkGlobalHoldbackAAExperiment)

            let linkAbTestExperiment = LinkABTest(
                arbId: arbId,
                session: elementsSession,
                configuration: configuration,
                linkAccount: linkAccount,
                integrationShape: analyticsHelper.integrationShape
            )
            analyticsHelper.logExposure(experiment: linkAbTestExperiment)
        }
    }

    /// If configuration uses Ephemeral Key, retrieve Customer object and return email
    @MainActor
    static func getCustomerEmailForLinkWithEphemeralKey(configuration: PaymentElementConfiguration, loadTimings: LoadTimings) async throws -> (email: String, source: EmailSource)? {
        guard
            configuration.defaultBillingDetails.email == nil, // If email was already provided, don't make a network request to retrieve it.
            let customerID = configuration.customer?.id,
            case .legacyCustomerEphemeralKey(let ephemeralKey) = configuration.customer?.customerAccessProvider
        else {
            return nil
        }
        loadTimings.logStart("retrieveCustomer")
        defer {
            loadTimings.logEnd("retrieveCustomer")
        }
        let customer = try await configuration.apiClient.retrieveCustomer(customerID, using: ephemeralKey)
        if let email = customer.email {
            return (email, EmailSource.customerObject)
        }
        return nil
    }

    typealias ElementSessionAndIntent = (elementsSession: STPElementsSession, intent: Intent)
    @MainActor
    static func fetchElementsSessionAndIntent(mode: PaymentSheet.InitializationMode, configuration: PaymentElementConfiguration, analyticsHelper: PaymentSheetAnalyticsHelper, loadTimings: LoadTimings) async throws -> ElementSessionAndIntent {
        loadTimings.logStart("fetchElementsSession")
        defer {
            loadTimings.logEnd("fetchElementsSession")
        }
        let intent: Intent
        let elementsSession: STPElementsSession
        let clientDefaultPaymentMethod: String? = {
            guard let customer = configuration.customer else {
                return nil
            }
            return defaultStripePaymentMethodId(forCustomerID: customer.id)
        }()

        switch mode {
        case .paymentIntentClientSecret(let clientSecret):
            let paymentIntent: STPPaymentIntent
            do {
                (paymentIntent, elementsSession) = try await configuration.apiClient.retrieveElementsSession(paymentIntentClientSecret: clientSecret,
                                                                                                             clientDefaultPaymentMethod: clientDefaultPaymentMethod,
                                                                                                             configuration: configuration)
            } catch let error {
                analyticsHelper.log(event: .paymentSheetElementsSessionLoadFailed, error: error)
                guard shouldFallback(for: error) else {
                    throw error
                }
                // Fallback to regular retrieve PI when retrieve PI with preferences fails
                paymentIntent = try await configuration.apiClient.retrievePaymentIntent(clientSecret: clientSecret)
                elementsSession = .makeBackupElementsSession(with: paymentIntent)
            }
            guard ![.succeeded, .canceled, .requiresCapture].contains(paymentIntent.status) else {
                // Error if the PaymentIntent is in a terminal state
                throw PaymentSheetError.paymentIntentInTerminalState(status: paymentIntent.status)
            }
            intent = .paymentIntent(paymentIntent)
        case .setupIntentClientSecret(let clientSecret):
            let setupIntent: STPSetupIntent
            do {
                (setupIntent, elementsSession) = try await configuration.apiClient.retrieveElementsSession(setupIntentClientSecret: clientSecret,
                                                                                                           clientDefaultPaymentMethod: clientDefaultPaymentMethod,
                                                                                                           configuration: configuration)
            } catch let error {
                analyticsHelper.log(event: .paymentSheetElementsSessionLoadFailed, error: error)
                guard shouldFallback(for: error) else {
                    throw error
                }
                // Fallback to regular retrieve SI when retrieve SI with preferences fails
                setupIntent = try await configuration.apiClient.retrieveSetupIntent(clientSecret: clientSecret)
                elementsSession = .makeBackupElementsSession(with: setupIntent)
            }
            guard ![.succeeded, .canceled].contains(setupIntent.status) else {
                // Error if the SetupIntent is in a terminal state
                throw PaymentSheetError.setupIntentInTerminalState(status: setupIntent.status)
            }
            intent = .setupIntent(setupIntent)
        case .deferredIntent(let intentConfig):
            do {
                elementsSession = try await configuration.apiClient.retrieveDeferredElementsSession(withIntentConfig: intentConfig,
                                                                                                clientDefaultPaymentMethod: clientDefaultPaymentMethod,
                                                                                                configuration: configuration)
                intent = .deferredIntent(intentConfig: intentConfig)
            } catch {
                analyticsHelper.log(event: .paymentSheetElementsSessionLoadFailed, error: error)
                guard shouldFallback(for: error) else {
                    throw error
                }
                // Fall back to a backup ElementsSession with the payment methods from the merchant's intent config or, if none were supplied, a card.
                let paymentMethodTypes = intentConfig.paymentMethodTypes?.map { STPPaymentMethod.type(from: $0) } ?? [.card]
                elementsSession = .makeBackupElementsSession(allResponseFields: [:], paymentMethodTypes: paymentMethodTypes)
                intent = .deferredIntent(intentConfig: intentConfig)
            }
        case .checkoutSession(let checkoutSession):
            guard let elementsSessionJSON = checkoutSession.allResponseFields["elements_session"] as? [AnyHashable: Any],
                  let decodedElementsSession = STPElementsSession.decodedObject(fromAPIResponse: elementsSessionJSON) else {
                throw PaymentSheetError.unknown(debugDescription: "Failed to decode elements session from provided checkout session object")
            }
            elementsSession = decodedElementsSession
            intent = .checkoutSession(checkoutSession)
        }

        // Warn the merchant if we see unactivated payment method types in the Intent
        if !elementsSession.unactivatedPaymentMethodTypes.isEmpty {
            let message = """
            [Stripe SDK] Warning: Your Intent contains the following payment method types which are activated for test mode but not activated for live mode: \(elementsSession.unactivatedPaymentMethodTypes.map({ $0.displayName }).joined(separator: ",")). These payment method types will not be displayed in live mode until they are activated. To activate these payment method types visit your Stripe dashboard.
            More information: https://support.stripe.com/questions/activate-a-new-payment-method
            """
            print(message)
        }
        return (elementsSession, intent)
    }

    static func shouldFallback(for error: Error) -> Bool {
        let error = error as NSError
        // Show fallback for unknown server errors (500s).
        // Otherwise, don't fall back in order to
        // 1. avoid loading a potentially degraded UX instead of prompting the customer to retry loading (e.g. bad network).
        // 2. let the merchant see potential integration errors (e.g. bad publishable key, invalid intent configuration)
        if
            let httpStatusCode = error.userInfo[STPError.httpStatusCodeKey] as? Int,
            httpStatusCode >= 500
        {
            return true
        }
        return false
    }

    static func defaultStripePaymentMethodId(forCustomerID customerID: String?) -> String? {
        guard let defaultPaymentMethod = CustomerPaymentOption.localDefaultPaymentMethod(for: customerID),
              case .stripeId(let paymentMethodId) = defaultPaymentMethod else {
            return nil
        }
        return paymentMethodId
    }

    @MainActor
    static func filterSavedPaymentMethods(
        intent: Intent,
        elementsSession: STPElementsSession,
        configuration: PaymentElementConfiguration,
        prefetchedSPMs: [STPPaymentMethod]?,
        loadTimings: LoadTimings
    ) -> [STPPaymentMethod] {
        loadTimings.logStart("filterPaymentMethods")
        defer { loadTimings.logEnd("filterPaymentMethods") }
        // Retrieve the payment methods from ElementsSession or by making direct API calls
        var savedPaymentMethods: [STPPaymentMethod]
        if let elementsSessionPaymentMethods = elementsSession.customer?.paymentMethods {
            // A. SPMs are on ElementSessions object when using CustomerSession.
            savedPaymentMethods = elementsSessionPaymentMethods
        } else if case let .checkoutSession(checkoutSession) = intent,
                  let customerPaymentMethods = checkoutSession.customer?.paymentMethods {
            // B. SPMs are on CheckoutSession object
            savedPaymentMethods = customerPaymentMethods
        } else if let prefetchedSPMs {
            // C. SPMs are pre-fetched prior to this point when using Ephemeral Keys.
            // Filter them manually now that we have the v1/e/s response. This step should ~mimick the filtering in v1/elements/sessions.
            savedPaymentMethods = prefetchedSPMs
        } else {
            return []
        }

        // Move default PM to front
        if let customerID = configuration.customer?.id {
            let defaultPaymentMethodOption = CustomerPaymentOption.selectedPaymentMethod(for: customerID, elementsSession: elementsSession, surface: .paymentSheet)
            if let defaultPMIndex = savedPaymentMethods.firstIndex(where: {
                $0.stripeId == defaultPaymentMethodOption?.value
            }) {
                let defaultPM = savedPaymentMethods.remove(at: defaultPMIndex)
                savedPaymentMethods.insert(defaultPM, at: 0)
            }
        }

        // Filter payment methods
        let result = savedPaymentMethods.filter { paymentMethod in
            // Filter out unsupported pm types (applies to all payment methods)
            guard elementsSession.orderedPaymentMethodTypes.contains(paymentMethod.type) else {
                return false
            }
            guard paymentMethod.supportsSavedPaymentMethod(
                configuration: configuration,
                intent: intent,
                elementsSession: elementsSession
            ) else {
                return false
            }

            // Filter out pm whose billing country is not allowed
            guard Self.shouldIncludePaymentMethod(paymentMethod, allowedCountries: configuration.billingDetailsCollectionConfiguration.allowedCountries) else {
                return false
            }

            // Card-specific filtering: brands and funding types
            if let card = paymentMethod.card {
                // Filter by card brand
                if !configuration.cardBrandFilter.isAccepted(cardBrand: card.preferredDisplayBrand) {
                    return false
                }
                // Filter by card funding type
                let cardFundingFilter = configuration.cardFundingFilter(for: elementsSession)
                let fundingType: STPCardFundingType = card.funding.map { STPCard.funding(from: $0) } ?? .other
                if !cardFundingFilter.isAccepted(cardFundingType: fundingType) {
                    return false
                }
            }

            return true
        }
        return result
    }

    /// - Returns: nil if not using EK.
    @MainActor
    static func fetchSavedPaymentMethodsWithEphemeralKey(
        configuration: PaymentElementConfiguration,
        loadTimings: LoadTimings
    ) async throws -> [STPPaymentMethod]? {
        guard
            let customerID = configuration.customer?.id,
            case .legacyCustomerEphemeralKey(let ephemeralKey) = configuration.customer?.customerAccessProvider
        else {
            return nil
        }
        loadTimings.logStart("fetchSavedPaymentMethods")
        defer {
            loadTimings.logEnd("fetchSavedPaymentMethods")
        }
        var paymentMethods = try await configuration.apiClient.listPaymentMethods(
            customerID: customerID,
            ephemeralKeySecret: ephemeralKey
        )
        // Remove unsupported types
        // We don't support Link payment methods with customer ephemeral keys
        let types = PaymentSheet.supportedSavedPaymentMethods.filter { $0 != .link }
        paymentMethods = paymentMethods.filter { types.contains($0.type) }

        // Dedupe Link PMs
        let linkPaymentMethods = paymentMethods.filter { paymentMethod in
            let isLinkCard = paymentMethod.type == .card && paymentMethod.card?.wallet?.type == .link
            return isLinkCard
        }
        var dedupedLinkPaymentMethods: [STPPaymentMethod] = []
        for linkPM in linkPaymentMethods {
            // Only add the card if it doesn't already exist
            if !dedupedLinkPaymentMethods.contains(where: { existingPM in
                existingPM.card?.last4 == linkPM.card?.last4 &&
                existingPM.card?.expYear == linkPM.card?.expYear &&
                existingPM.card?.expMonth == linkPM.card?.expMonth &&
                existingPM.card?.brand == linkPM.card?.brand
            }) {
                dedupedLinkPaymentMethods.append(linkPM)
            }
        }
        // Remove cards that originated from Apple Pay, Google Pay, Link
        paymentMethods = paymentMethods.filter { paymentMethod in
            let isWalletCard = paymentMethod.type == .card && [.applePay, .googlePay, .link].contains(paymentMethod.card?.wallet?.type)
            return !isWalletCard || configuration.disableWalletPaymentMethodFiltering
        }
        // Add in our deduped Link PMs, if any
        paymentMethods += dedupedLinkPaymentMethods
        return paymentMethods
    }

    /// Determines if a saved payment method should be included based on allowed countries filtering
    /// - Parameters:
    ///   - paymentMethod: The payment method to evaluate
    ///   - allowedCountries: Set of allowed country codes (empty set means all countries allowed)
    /// - Returns: `true` if the payment method should be included, `false` otherwise
    static func shouldIncludePaymentMethod(_ paymentMethod: STPPaymentMethod, allowedCountries: Set<String>) -> Bool {
        // Empty set means all countries are allowed (no filtering)
        guard !allowedCountries.isEmpty else { return true }

        // Hide payment methods without billing country data when filtering is active
        guard let billingCountry = paymentMethod.billingDetails?.address?.country else {
            return false
        }

        return allowedCountries.contains(billingCountry)
    }
}

extension PaymentSheetLoader {
    /// Used to measure granular load timings
    @MainActor
    class LoadTimings {
        static var shouldPrintLogs: Bool = false
        let loadingStartDate: Date
        private var timings: [String: (start: TimeInterval, end: TimeInterval)] = [:]

        init(loadingStartDate: Date? = nil) {
            self.loadingStartDate = loadingStartDate ?? Date()
        }

        var jsonObject: [String: Any] {
            timings.mapValues {
                // Convert to milliseconds because IDK if stuff like `5.9604644775390625e-06` will be a pain to deal with in our hubble queries.
                Int(($0.end - $0.start) * 1000)
            }
        }
        func logStart(_ event: String) {
            stpAssert(timings[event] == nil)
            let timestamp = Date().timeIntervalSince1970
            timings[event] = (start: timestamp, end: 0)
            if Self.shouldPrintLogs {
                print("[LOADER_TIMING] START \(event) \(timestamp)")
            }

        }
        func logEnd(_ event: String) {
            stpAssert(timings[event] != nil)
            let timestamp = Date().timeIntervalSince1970
            timings[event]?.end = timestamp
            if Self.shouldPrintLogs {
                print("[LOADER_TIMING] END \(event) \(timestamp)")
            }
        }
    }
}
