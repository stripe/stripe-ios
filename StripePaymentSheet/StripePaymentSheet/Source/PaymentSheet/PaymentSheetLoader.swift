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
        completion: @escaping (Result<LoadResult, Error>) -> Void
    ) {
        Task { @MainActor in
            do {
                let loadResult = try await load(mode: mode, configuration: configuration, analyticsHelper: analyticsHelper, integrationShape: integrationShape, isUpdate: isUpdate)
                completion(.success(loadResult))
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
    ) async throws -> LoadResult {
        printTimingLog("START load")
        analyticsHelper.logLoadStarted()
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

            // Fetch ElementsSession
            async let _elementsSessionAndIntent: ElementSessionAndIntent = fetchElementsSessionAndIntent(mode: mode, configuration: configuration, analyticsHelper: analyticsHelper)

            // Load misc singletons
            await loadMiscellaneousSingletons()

            let elementsSessionAndIntent = try await _elementsSessionAndIntent
            let intent = elementsSessionAndIntent.intent
            let elementsSession = elementsSessionAndIntent.elementsSession
            // Overwrite the form specs that were already loaded from disk
            printTimingLog("START loadFormSpecs")
            switch intent {
            case .paymentIntent, .deferredIntent, .checkoutSession:
                if !elementsSession.isBackupInstance {
                    _ = FormSpecProvider.shared.loadFrom(elementsSession.paymentMethodSpecs as Any)
                }
            case .setupIntent:
                break // Not supported
            }
            printTimingLog("END loadFormSpecs")

            // List the Customer's saved PaymentMethods
            async let savedPaymentMethods = fetchSavedPaymentMethods(intent: intent, elementsSession: elementsSession, configuration: configuration)

            // Load link account session. Continue without Link if it errors.
            let linkAccount = try? await lookupLinkAccount(
                elementsSession: elementsSession,
                configuration: configuration,
                isUpdate: isUpdate
            )
            LinkAccountContext.shared.account = linkAccount

            // Log experiment exposures
            printTimingLog("START logExperiments")
            if let arbId = elementsSession.experimentsData?.arbId {
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
            printTimingLog("END logExperiments")

            // Filter out payment methods that the PI/SI or PaymentSheet doesn't support
            printTimingLog("START filterPaymentMethods")
            let filteredSavedPaymentMethods = try await savedPaymentMethods
                .filter { elementsSession.orderedPaymentMethodTypes.contains($0.type) }
                .filter {
                    $0.supportsSavedPaymentMethod(
                        configuration: configuration,
                        intent: intent,
                        elementsSession: elementsSession
                    )
                }
                .filter { Self.shouldIncludePaymentMethod($0, allowedCountries: configuration.billingDetailsCollectionConfiguration.allowedCountries) }
            printTimingLog("END filterPaymentMethods")

            printTimingLog("START computePaymentMethodTypes")
            let isLinkEnabled = PaymentSheet.isLinkEnabled(elementsSession: elementsSession, configuration: configuration)
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
            printTimingLog("END computePaymentMethodTypes")

            // Initialize telemetry. Don't wait for this to finish to return.
            STPTelemetryClient.shared.sendTelemetryData()

            let loadResult = LoadResult(
                intent: intent,
                elementsSession: elementsSession,
                savedPaymentMethods: filteredSavedPaymentMethods,
                paymentMethodTypes: paymentMethodTypes
            )

            // Send load finished analytic
            // ⚠️ Important: Log load succeeded at the very end, to ensure it measures the entire amount of time this method took.
            // This is hacky; the logic to determine the default selected payment method belongs to the SavedPaymentOptionsViewController. We invoke it here just to report it to analytics before that VC loads.
            printTimingLog("START makeViewModels")
            let (defaultSelectedIndex, paymentOptionsViewModels) = SavedPaymentOptionsViewController.makeViewModels(
                savedPaymentMethods: filteredSavedPaymentMethods,
                customerID: configuration.customer?.id,
                showApplePay: integrationShape.canDefaultToLinkOrApplePay ? isApplePayEnabled : false,
                showLink: integrationShape.canDefaultToLinkOrApplePay ? isLinkEnabled : false,
                elementsSession: elementsSession,
                defaultPaymentMethod: elementsSession.customer?.getDefaultPaymentMethod()
            )
            printTimingLog("END makeViewModels")
            analyticsHelper.logLoadSucceeded(
                intent: intent,
                elementsSession: elementsSession,
                defaultPaymentMethod: paymentOptionsViewModels.stp_boundSafeObject(at: defaultSelectedIndex),
                orderedPaymentMethodTypes: paymentMethodTypes
            )
            printTimingLog("END load")
            return loadResult
        } catch {
            analyticsHelper.logLoadFailed(error: error)
            throw error
        }
    }

    // MARK: - Helper methods that load things

    /// Loads miscellaneous singletons
    static func loadMiscellaneousSingletons() async {
        printTimingLog("START loadMiscellaneousSingletons")
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
        printTimingLog("END loadMiscellaneousSingletons")
    }

    static func lookupLinkAccount(
        elementsSession: STPElementsSession,
        configuration: PaymentElementConfiguration,
        isUpdate: Bool
    ) async throws -> PaymentSheetLinkAccount? {
        // If we already have a verified Link account and the merchant is just calling `update` on FlowController or Embedded,
        // keep the account logged-in. Otherwise, the user has to verify via OTP again.
        if isUpdate, let currentLinkAccount = LinkAccountContext.shared.account, currentLinkAccount.sessionState == .verified {
            return currentLinkAccount
        }

        // Lookup Link account if Link is enabled or the holdback killswitch is not enabled.
        // Note: When the holdback experiment is over, we can ignore the killswitch and only lookup when Link is enabled.
        let isLinkEnabled = PaymentSheet.isLinkEnabled(elementsSession: elementsSession, configuration: configuration)
        let isLookupForHoldbackEnabled = elementsSession.flags["elements_disable_link_global_holdback_lookup"] != true

        guard isLinkEnabled || isLookupForHoldbackEnabled else {
            return nil
        }

        // Don't log this as a lookup on the backend side if Link is not enabled.
        // As in, this will be true when this lookup is only happening to gather dimensions for the holdback experiment.
        // Note: When the holdback experiment is over, we can remove this parameter from the lookup call.
        let doNotLogConsumerFunnelEvent = !isLinkEnabled

        // This lookup call will only happen if we have access to a user's email:
        return try await _lookupLinkAccount(
            elementsSession: elementsSession,
            configuration: configuration,
            doNotLogConsumerFunnelEvent: doNotLogConsumerFunnelEvent
        )
    }

    private static func _lookupLinkAccount(
        elementsSession: STPElementsSession,
        configuration: PaymentElementConfiguration,
        doNotLogConsumerFunnelEvent: Bool
    ) async throws -> PaymentSheetLinkAccount? {
        let linkAccountService = LinkAccountService(apiClient: configuration.apiClient, elementsSession: elementsSession)
        func lookUpConsumerSession(email: String?, emailSource: EmailSource) async throws -> PaymentSheetLinkAccount? {
            return try await withCheckedThrowingContinuation { continuation in
                printTimingLog("START lookUpLinkAccount")
                linkAccountService.lookupAccount(
                    withEmail: email,
                    emailSource: emailSource,
                    doNotLogConsumerFunnelEvent: doNotLogConsumerFunnelEvent
                ) { result in
                    printTimingLog("END lookUpLinkAccount")
                    switch result {
                    case .success(let linkAccount):
                        continuation.resume(with: .success(linkAccount))
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            }
        }

        if let email = configuration.defaultBillingDetails.email {
            return try await lookUpConsumerSession(email: email, emailSource: .customerEmail)
        } else if let customerID = configuration.customer?.id,
                  let ephemeralKey = configuration.customer?.ephemeralKeySecret(basedOn: elementsSession)
        {
            printTimingLog("START retrieveCustomer")
            let customer = try await configuration.apiClient.retrieveCustomer(customerID, using: ephemeralKey)
            printTimingLog("END retrieveCustomer")
            // If there's an error in this call we can just ignore it
            return try await lookUpConsumerSession(email: customer.email, emailSource: .customerObject)
        } else {
            return nil
        }
    }

    typealias ElementSessionAndIntent = (elementsSession: STPElementsSession, intent: Intent)
    static func fetchElementsSessionAndIntent(mode: PaymentSheet.InitializationMode, configuration: PaymentElementConfiguration, analyticsHelper: PaymentSheetAnalyticsHelper) async throws -> ElementSessionAndIntent {
        printTimingLog("START fetchElementsSession")
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
        printTimingLog("END fetchElementsSession")
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

    static func fetchSavedPaymentMethods(
        intent: Intent,
        elementsSession: STPElementsSession,
        configuration: PaymentElementConfiguration
    ) async throws -> [STPPaymentMethod] {
        printTimingLog("START fetchSavedPaymentMethods")
        // Retrieve the payment methods from ElementsSession or by making direct API calls
        var savedPaymentMethods: [STPPaymentMethod]
        if let elementsSessionPaymentMethods = elementsSession.customer?.paymentMethods {
            savedPaymentMethods = elementsSessionPaymentMethods
        } else if case let .checkoutSession(checkoutSession) = intent,
                  let customerPaymentMethods = checkoutSession.customer?.paymentMethods {
            savedPaymentMethods = customerPaymentMethods
        } else {
            savedPaymentMethods = try await fetchSavedPaymentMethodsUsingApiClient(configuration: configuration, elementsSession: elementsSession)
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

        // Hide any saved cards whose brands or funding types are not allowed
        let cardFundingFilter = configuration.cardFundingFilter(for: elementsSession)
        let result = savedPaymentMethods.filter {
            guard let card = $0.card else { return true }
            // Filter by card brand
            if !configuration.cardBrandFilter.isAccepted(cardBrand: card.preferredDisplayBrand) {
                return false
            }
            // Filter by card funding type
            // If funding is nil, treat it as .other (unknown) and check if that's accepted
            let fundingType: STPCardFundingType = card.funding.map { STPCard.funding(from: $0) } ?? .other
            if !cardFundingFilter.isAccepted(cardFundingType: fundingType) {
                return false
            }
            return true
        }
        printTimingLog("END fetchSavedPaymentMethods")
        return result
    }

    static func fetchSavedPaymentMethodsUsingApiClient(configuration: PaymentElementConfiguration, elementsSession: STPElementsSession) async throws -> [STPPaymentMethod] {
        guard let customerID = configuration.customer?.id,
              case .legacyCustomerEphemeralKey(let ephemeralKey) = configuration.customer?.customerAccessProvider else {
            return []
        }

        let orderdPaymentMethodTypes = elementsSession.orderedPaymentMethodTypes

        // We don't support Link payment methods with customer ephemeral keys
        let types = PaymentSheet.supportedSavedPaymentMethods.filter { $0 != .link && orderdPaymentMethodTypes.contains($0) }
        return try await withCheckedThrowingContinuation { continuation in
            configuration.apiClient.listPaymentMethods(
                forCustomer: customerID,
                using: ephemeralKey,
                types: types,
                limit: 100
            ) { paymentMethods, error in
                guard var paymentMethods, error == nil else {
                    let error = error ?? PaymentSheetError.fetchPaymentMethodsFailure
                    continuation.resume(throwing: error)
                    return
                }
                // Get Link payment methods
                var dedupedLinkPaymentMethods: [STPPaymentMethod] = []
                let linkPaymentMethods = paymentMethods.filter { paymentMethod in
                    let isLinkCard = paymentMethod.type == .card && paymentMethod.card?.wallet?.type == .link
                    return isLinkCard
                }
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
                continuation.resume(returning: paymentMethods)
            }
        }
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

    static var _enableGranularTimingLogs: Bool = false
}

/// Debug prints to help measure timing of things.
/// Typical usage:
/// 1. Run MPELatencyTest.swift
/// 2. Copy the output
/// 3. Run `pbpaste | ./ci_scripts/generate_loader_flamegraph.rb`
func printTimingLog(_ event: String) {
    guard PaymentSheetLoader._enableGranularTimingLogs else { return }
    print("[LOADER_TIMING] \(event) \(Date().timeIntervalSince1970)")
}
