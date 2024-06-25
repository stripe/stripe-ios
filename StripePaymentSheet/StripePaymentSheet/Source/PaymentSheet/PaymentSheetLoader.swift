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
        let savedPaymentMethods: [STPPaymentMethod]
        let isLinkEnabled: Bool
        let isApplePayEnabled: Bool
    }

    /// Fetches the PaymentIntent or SetupIntent and Customer's saved PaymentMethods
    static func load(
        mode: PaymentSheet.InitializationMode,
        configuration: PaymentSheet.Configuration,
        analyticsClient: STPAnalyticsClient = .sharedClient,
        isFlowController: Bool,
        completion: @escaping (Result<LoadResult, Error>) -> Void
    ) {
        let loadingStartDate = Date()
        analyticsClient.logPaymentSheetEvent(event: .paymentSheetLoadStarted)

        Task { @MainActor in
            do {
                if !mode.isDeferred && configuration.apiClient.publishableKeyIsUserKey {
                    // User keys can't pass payment_method_data directly to /confirm, which is what the non-deferred intent flows do
                    assertionFailure("Dashboard isn't supported in non-deferred intent flows")
                }

                // Fetch ElementsSession
                async let _intent = fetchIntent(mode: mode, configuration: configuration, analyticsClient: analyticsClient)

                // Load misc singletons
                await loadMiscellaneousSingletons()

                let intent = try await _intent
                // Overwrite the form specs that were already loaded from disk
                switch intent {
                case .paymentIntent(let elementsSession, _):
                    if !elementsSession.isBackupInstance {
                        _ = FormSpecProvider.shared.loadFrom(elementsSession.paymentMethodSpecs as Any)
                    }
                case .setupIntent:
                    break // Not supported
                case .deferredIntent(elementsSession: let elementsSession, intentConfig: _):
                    if !elementsSession.isBackupInstance {
                        _ = FormSpecProvider.shared.loadFrom(elementsSession.paymentMethodSpecs as Any)
                    }
                }

                // Clear the payment method form cache
                PaymentMethodFormViewController.clearFormCache()

                // List the Customer's saved PaymentMethods
                async let savedPaymentMethods = fetchSavedPaymentMethods(intent: intent, configuration: configuration)

                // Load link account session. Continue without Link if it errors.
                let linkAccount = try? await lookupLinkAccount(intent: intent, configuration: configuration)
                LinkAccountContext.shared.account = linkAccount

                // Filter out payment methods that the PI/SI or PaymentSheet doesn't support
                let filteredSavedPaymentMethods = try await savedPaymentMethods
                    .filter { intent.recommendedPaymentMethodTypes.contains($0.type) }
                    .filter {
                        $0.supportsSavedPaymentMethod(
                            configuration: configuration,
                            intent: intent
                        )
                    }

                // Determine if Link and Apple Pay are enabled
                let isLinkEnabled = isLinkEnabled(intent: intent, configuration: configuration)
                let isApplePayEnabled = StripeAPI.deviceSupportsApplePay()
                    && configuration.applePay != nil
                    && intent.isApplePayEnabled

                // Send load finished analytic
                // This is hacky; the logic to determine the default selected payment method belongs to the SavedPaymentOptionsViewController. We invoke it here just to report it to analytics before that VC loads.
                let (defaultSelectedIndex, paymentOptionsViewModels) = SavedPaymentOptionsViewController.makeViewModels(
                    savedPaymentMethods: filteredSavedPaymentMethods,
                    customerID: configuration.customer?.id,
                    showApplePay: isFlowController ? isApplePayEnabled : false,
                    showLink: isFlowController ? isLinkEnabled : false
                )
                analyticsClient.logPaymentSheetLoadSucceeded(
                    loadingStartDate: loadingStartDate,
                    linkEnabled: isLinkEnabled,
                    defaultPaymentMethod: paymentOptionsViewModels.stp_boundSafeObject(at: defaultSelectedIndex),
                    intentAnalyticsValue: intent.analyticsValue
                )
                if isFlowController {
                    AnalyticsHelper.shared.startTimeMeasurement(.checkout)
                }

                // Call completion
                let loadResult = LoadResult(
                    intent: intent,
                    savedPaymentMethods: filteredSavedPaymentMethods,
                    isLinkEnabled: isLinkEnabled,
                    isApplePayEnabled: isApplePayEnabled
                )
                completion(.success(loadResult))
            } catch {
                analyticsClient.logPaymentSheetEvent(event: .paymentSheetLoadFailed,
                                                                     duration: Date().timeIntervalSince(loadingStartDate),
                                                                     error: error)
                completion(.failure(error))
            }
        }
    }

    // MARK: - Helpers

    static func isLinkEnabled(intent: Intent, configuration: PaymentSheet.Configuration) -> Bool {
        guard intent.supportsLink else {
            return false
        }
        return !configuration.requiresBillingDetailCollection()
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

    static func lookupLinkAccount(intent: Intent, configuration: PaymentSheet.Configuration) async throws -> PaymentSheetLinkAccount? {
        // Only lookup the consumer account if Link is supported
        guard isLinkEnabled(intent: intent, configuration: configuration) else {
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
                  let ephemeralKey = configuration.customer?.ephemeralKeySecretBasedOn(intent: intent)
        {
            let customer = try await configuration.apiClient.retrieveCustomer(customerID, using: ephemeralKey)
            // If there's an error in this call we can just ignore it
            return try await lookUpConsumerSession(email: customer.email)
        } else {
            return nil
        }
    }

    static func fetchIntent(mode: PaymentSheet.InitializationMode, configuration: PaymentSheet.Configuration, analyticsClient: STPAnalyticsClient) async throws -> Intent {
        let intent: Intent
        let clientDefaultPaymentMethod = defaultStripePaymentMethodId(forCustomerID: configuration.customer?.id)

        switch mode {
        case .paymentIntentClientSecret(let clientSecret):
            let paymentIntent: STPPaymentIntent
            let elementsSession: STPElementsSession
            do {
                (paymentIntent, elementsSession) = try await configuration.apiClient.retrieveElementsSession(paymentIntentClientSecret: clientSecret,
                                                                                                             clientDefaultPaymentMethod: clientDefaultPaymentMethod,
                                                                                                             configuration: configuration)
            } catch let error {
                analyticsClient.logPaymentSheetEvent(event: .paymentSheetElementsSessionLoadFailed, error: error)
                // Fallback to regular retrieve PI when retrieve PI with preferences fails
                paymentIntent = try await configuration.apiClient.retrievePaymentIntent(clientSecret: clientSecret)
                elementsSession = .makeBackupElementsSession(with: paymentIntent)
            }
            guard ![.succeeded, .canceled, .requiresCapture].contains(paymentIntent.status) else {
                // Error if the PaymentIntent is in a terminal state
                throw PaymentSheetError.paymentIntentInTerminalState(status: paymentIntent.status)
            }
            intent = .paymentIntent(elementsSession: elementsSession, paymentIntent: paymentIntent)
        case .setupIntentClientSecret(let clientSecret):
            let setupIntent: STPSetupIntent
            let elementsSession: STPElementsSession
            do {
                (setupIntent, elementsSession) = try await configuration.apiClient.retrieveElementsSession(setupIntentClientSecret: clientSecret,
                                                                                                           clientDefaultPaymentMethod: clientDefaultPaymentMethod,
                                                                                                           configuration: configuration)
            } catch let error {
                analyticsClient.logPaymentSheetEvent(event: .paymentSheetElementsSessionLoadFailed, error: error)
                // Fallback to regular retrieve SI when retrieve SI with preferences fails
                setupIntent = try await configuration.apiClient.retrieveSetupIntent(clientSecret: clientSecret)
                elementsSession = .makeBackupElementsSession(with: setupIntent)
            }
            guard ![.succeeded, .canceled].contains(setupIntent.status) else {
                // Error if the SetupIntent is in a terminal state
                throw PaymentSheetError.setupIntentInTerminalState(status: setupIntent.status)
            }
            intent = .setupIntent(elementsSession: elementsSession, setupIntent: setupIntent)
        case .deferredIntent(let intentConfig):
            do {
                let elementsSession = try await configuration.apiClient.retrieveElementsSession(withIntentConfig: intentConfig,
                                                                                                clientDefaultPaymentMethod: clientDefaultPaymentMethod,
                                                                                                configuration: configuration)
                intent = .deferredIntent(elementsSession: elementsSession, intentConfig: intentConfig)
            } catch let error as NSError where error == NSError.stp_genericFailedToParseResponseError() {
                // Most errors are useful and should be reported back to the merchant to help them debug their integration (e.g. bad connection, unknown parameter, invalid api key).
                // If we get `stp_genericFailedToParseResponseError`, it means the request succeeded but we couldn't parse the response.
                // In this case, fall back to a backup ElementsSession with the payment methods from the merchant's intent config or, if none were supplied, a card.
                analyticsClient.logPaymentSheetEvent(event: .paymentSheetElementsSessionLoadFailed, error: error)
                let paymentMethodTypes = intentConfig.paymentMethodTypes?.map { STPPaymentMethod.type(from: $0) } ?? [.card]
                intent = .deferredIntent(elementsSession: .makeBackupElementsSession(allResponseFields: [:], paymentMethodTypes: paymentMethodTypes), intentConfig: intentConfig)
            }
        }
        // Ensure that there's at least 1 payment method type available for the intent and configuration.
        let paymentMethodTypes = PaymentSheet.PaymentMethodType.filteredPaymentMethodTypes(from: intent, configuration: configuration, logAvailability: true)
        guard !paymentMethodTypes.isEmpty else {
            throw PaymentSheetError.noPaymentMethodTypesAvailable(intentPaymentMethods: intent.recommendedPaymentMethodTypes)
        }
        // Warn the merchant if we see unactivated payment method types in the Intent
        if !intent.unactivatedPaymentMethodTypes.isEmpty {
            let message = """
            [Stripe SDK] Warning: Your Intent contains the following payment method types which are activated for test mode but not activated for live mode: \(intent.unactivatedPaymentMethodTypes.map({ $0.displayName }).joined(separator: ",")). These payment method types will not be displayed in live mode until they are activated. To activate these payment method types visit your Stripe dashboard.
            More information: https://support.stripe.com/questions/activate-a-new-payment-method
            """
            print(message)
        }
        return intent
    }

    static func defaultStripePaymentMethodId(forCustomerID customerID: String?) -> String? {
        guard let defaultPaymentMethod = CustomerPaymentOption.defaultPaymentMethod(for: customerID),
              case .stripeId(let paymentMethodId) = defaultPaymentMethod else {
            return nil
        }
        return paymentMethodId
    }

    static let savedPaymentMethodTypes: [STPPaymentMethodType] = [.card, .USBankAccount, .SEPADebit]
    static func fetchSavedPaymentMethods(intent: Intent, configuration: PaymentSheet.Configuration) async throws -> [STPPaymentMethod] {
        if let elementsSessionPaymentMethods = intent.elementsSession.customer?.paymentMethods {
            return elementsSessionPaymentMethods
        } else {
            return try await fetchSavedPaymentMethodsUsingApiClient(configuration: configuration)
        }
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
                types: savedPaymentMethodTypes
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
