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
    }

    /// Fetches the PaymentIntent or SetupIntent and Customer's saved PaymentMethods
    static func load(
        mode: PaymentSheet.InitializationMode,
        configuration: PaymentSheet.Configuration,
        analyticsHelper: PaymentSheetAnalyticsHelper,
        isFlowController: Bool,
        completion: @escaping (Result<LoadResult, Error>) -> Void
    ) {
        analyticsHelper.logLoadStarted()

        Task { @MainActor in
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
                switch intent {
                case .paymentIntent:
                    if !elementsSession.isBackupInstance {
                        _ = FormSpecProvider.shared.loadFrom(elementsSession.paymentMethodSpecs as Any)
                    }
                case .setupIntent:
                    break // Not supported
                case .deferredIntent:
                    if !elementsSession.isBackupInstance {
                        _ = FormSpecProvider.shared.loadFrom(elementsSession.paymentMethodSpecs as Any)
                    }
                }

                // List the Customer's saved PaymentMethods
                async let savedPaymentMethods = fetchSavedPaymentMethods(elementsSession: elementsSession, configuration: configuration)

                // Load link account session. Continue without Link if it errors.
                let linkAccount = try? await lookupLinkAccount(elementsSession: elementsSession, configuration: configuration)
                LinkAccountContext.shared.account = linkAccount

                // Filter out payment methods that the PI/SI or PaymentSheet doesn't support
                let filteredSavedPaymentMethods = try await savedPaymentMethods
                    .filter { elementsSession.orderedPaymentMethodTypes.contains($0.type) }
                    .filter {
                        $0.supportsSavedPaymentMethod(
                            configuration: configuration,
                            intent: intent,
                            elementsSession: elementsSession
                        )
                    }

                let isLinkEnabled = PaymentSheet.isLinkEnabled(elementsSession: elementsSession, configuration: configuration)
                let isApplePayEnabled = PaymentSheet.isApplePayEnabled(elementsSession: elementsSession, configuration: configuration)

                // Send load finished analytic
                // This is hacky; the logic to determine the default selected payment method belongs to the SavedPaymentOptionsViewController. We invoke it here just to report it to analytics before that VC loads.
                let (defaultSelectedIndex, paymentOptionsViewModels) = SavedPaymentOptionsViewController.makeViewModels(
                    savedPaymentMethods: filteredSavedPaymentMethods,
                    customerID: configuration.customer?.id,
                    showApplePay: isFlowController ? isApplePayEnabled : false,
                    showLink: isFlowController ? isLinkEnabled : false
                )
                let paymentMethodTypes = PaymentSheet.PaymentMethodType.filteredPaymentMethodTypes(from: intent, elementsSession: elementsSession, configuration: configuration, logAvailability: false)
                analyticsHelper.logLoadSucceeded(
                    intent: intent,
                    elementsSession: elementsSession,
                    defaultPaymentMethod: paymentOptionsViewModels.stp_boundSafeObject(at: defaultSelectedIndex),
                    orderedPaymentMethodTypes: paymentMethodTypes
                )
                if isFlowController {
                    analyticsHelper.startTimeMeasurement(.checkout)
                }

                // Call completion
                let loadResult = LoadResult(
                    intent: intent,
                    elementsSession: elementsSession,
                    savedPaymentMethods: filteredSavedPaymentMethods
                )
                completion(.success(loadResult))
            } catch {
                analyticsHelper.logLoadFailed(error: error)
                completion(.failure(error))
            }
        }
    }

    // MARK: - Helper methods that load things

    /// Loads miscellaneous singletons
    static func loadMiscellaneousSingletons() async {
        await withCheckedContinuation { continuation in
            Task {
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
    }

    static func lookupLinkAccount(elementsSession: STPElementsSession, configuration: PaymentSheet.Configuration) async throws -> PaymentSheetLinkAccount? {
        // Only lookup the consumer account if Link is supported
        guard PaymentSheet.isLinkEnabled(elementsSession: elementsSession, configuration: configuration) else {
            return nil
        }

        let linkAccountService = LinkAccountService(apiClient: configuration.apiClient)
        func lookUpConsumerSession(email: String?) async throws -> PaymentSheetLinkAccount? {
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

        if let email = configuration.defaultBillingDetails.email {
            return try await lookUpConsumerSession(email: email)
        } else if let customerID = configuration.customer?.id,
                  let ephemeralKey = configuration.customer?.ephemeralKeySecretBasedOn(elementsSession: elementsSession)
        {
            let customer = try await configuration.apiClient.retrieveCustomer(customerID, using: ephemeralKey)
            // If there's an error in this call we can just ignore it
            return try await lookUpConsumerSession(email: customer.email)
        } else {
            return nil
        }
    }

    typealias ElementSessionAndIntent = (elementsSession: STPElementsSession, intent: Intent)
    static func fetchElementsSessionAndIntent(mode: PaymentSheet.InitializationMode, configuration: PaymentSheet.Configuration, analyticsHelper: PaymentSheetAnalyticsHelper) async throws -> ElementSessionAndIntent {
        let intent: Intent
        let elementsSession: STPElementsSession
        let clientDefaultPaymentMethod = defaultStripePaymentMethodId(forCustomerID: configuration.customer?.id)

        switch mode {
        case .paymentIntentClientSecret(let clientSecret):
            let paymentIntent: STPPaymentIntent
            do {
                (paymentIntent, elementsSession) = try await configuration.apiClient.retrieveElementsSession(paymentIntentClientSecret: clientSecret,
                                                                                                             clientDefaultPaymentMethod: clientDefaultPaymentMethod,
                                                                                                             configuration: configuration)
            } catch let error {
                analyticsHelper.log(event: .paymentSheetElementsSessionLoadFailed, error: error)
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
            } catch let error as NSError where error == NSError.stp_genericFailedToParseResponseError() {
                // Most errors are useful and should be reported back to the merchant to help them debug their integration (e.g. bad connection, unknown parameter, invalid api key).
                // If we get `stp_genericFailedToParseResponseError`, it means the request succeeded but we couldn't parse the response.
                // In this case, fall back to a backup ElementsSession with the payment methods from the merchant's intent config or, if none were supplied, a card.
                analyticsHelper.log(event: .paymentSheetElementsSessionLoadFailed, error: error)
                let paymentMethodTypes = intentConfig.paymentMethodTypes?.map { STPPaymentMethod.type(from: $0) } ?? [.card]
                elementsSession = .makeBackupElementsSession(allResponseFields: [:], paymentMethodTypes: paymentMethodTypes)
                intent = .deferredIntent(intentConfig: intentConfig)
            }
        }
        // Ensure that there's at least 1 payment method type available for the intent and configuration.
        let paymentMethodTypes = PaymentSheet.PaymentMethodType.filteredPaymentMethodTypes(from: intent, elementsSession: elementsSession, configuration: configuration, logAvailability: true)
        guard !paymentMethodTypes.isEmpty else {
            throw PaymentSheetError.noPaymentMethodTypesAvailable(intentPaymentMethods: elementsSession.orderedPaymentMethodTypes)
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

    static func defaultStripePaymentMethodId(forCustomerID customerID: String?) -> String? {
        guard let defaultPaymentMethod = CustomerPaymentOption.defaultPaymentMethod(for: customerID),
              case .stripeId(let paymentMethodId) = defaultPaymentMethod else {
            return nil
        }
        return paymentMethodId
    }

    static let savedPaymentMethodTypes: [STPPaymentMethodType] = [.card, .USBankAccount, .SEPADebit]
    static func fetchSavedPaymentMethods(elementsSession: STPElementsSession, configuration: PaymentSheet.Configuration) async throws -> [STPPaymentMethod] {
        // Retrieve the payment methods from ElementsSession or by making direct API calls
        var savedPaymentMethods: [STPPaymentMethod]
        if let elementsSessionPaymentMethods = elementsSession.customer?.paymentMethods {
            savedPaymentMethods = elementsSessionPaymentMethods
        } else {
            savedPaymentMethods = try await fetchSavedPaymentMethodsUsingApiClient(configuration: configuration)
        }

        // Move default PM to front
        if let customerID = configuration.customer?.id {
            let defaultPaymentMethod = CustomerPaymentOption.defaultPaymentMethod(for: customerID)
            if let defaultPMIndex = savedPaymentMethods.firstIndex(where: {
                $0.stripeId == defaultPaymentMethod?.value
            }) {
                let defaultPM = savedPaymentMethods.remove(at: defaultPMIndex)
                savedPaymentMethods.insert(defaultPM, at: 0)
            }
        }

        return savedPaymentMethods
    }

    static func fetchSavedPaymentMethodsUsingApiClient(configuration: PaymentSheet.Configuration) async throws -> [STPPaymentMethod] {
        guard let customerID = configuration.customer?.id,
              let ephemeralKey = configuration.customer?.ephemeralKeySecret,
              !ephemeralKey.isEmpty else {
            return []
        }
        return try await withCheckedThrowingContinuation { continuation in
            configuration.apiClient.listPaymentMethods(
                forCustomer: customerID,
                using: ephemeralKey,
                types: savedPaymentMethodTypes,
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
                    return !isWalletCard
                }
                // Add in our deduped Link PMs, if any
                paymentMethods += dedupedLinkPaymentMethods
                continuation.resume(returning: paymentMethods)
            }
        }
    }
}
