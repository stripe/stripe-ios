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
    /// `PaymentSheet.load()` result.
    enum LoadingResult {
        case success(
            intent: Intent,
            savedPaymentMethods: [STPPaymentMethod],
            isLinkEnabled: Bool
        )
        case failure(Error)
    }

    /// Fetches the PaymentIntent or SetupIntent and Customer's saved PaymentMethods
    static func load(
        mode: PaymentSheet.InitializationMode,
        configuration: PaymentSheet.Configuration,
        completion: @escaping (LoadingResult) -> Void
    ) {
        let loadingStartDate = Date()
        STPAnalyticsClient.sharedClient.logPaymentSheetEvent(event: .paymentSheetLoadStarted)

        Task { @MainActor in
            do {
                // Fetch PaymentIntent, SetupIntent, or ElementsSession
                async let _intent = fetchIntent(mode: mode, configuration: configuration)

                // List the Customer's saved PaymentMethods
                // TODO: Use v1/elements/sessions to fetch saved PMS https://jira.corp.stripe.com/browse/MOBILESDK-964
                async let savedPaymentMethods = fetchSavedPaymentMethods(configuration: configuration)

                // Load misc singletons
                await loadMiscellaneousSingletons()

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

                STPAnalyticsClient.sharedClient.logPaymentSheetEvent(event: .paymentSheetLoadSucceeded,
                                                                     duration: Date().timeIntervalSince(loadingStartDate))
                completion(
                    .success(
                        intent: intent,
                        savedPaymentMethods: filteredSavedPaymentMethods,
                        isLinkEnabled: intent.supportsLink
                    )
                )
            } catch {
                STPAnalyticsClient.sharedClient.logPaymentSheetEvent(event: .paymentSheetLoadFailed,
                                                                     duration: Date().timeIntervalSince(loadingStartDate),
                                                                     error: error)
                completion(.failure(error))
            }
        }
    }

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

        if let email = configuration.defaultBillingDetails.email {
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

    static func fetchIntent(mode: PaymentSheet.InitializationMode, configuration: PaymentSheet.Configuration) async throws -> Intent {
        let intent: Intent
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
                throw PaymentSheetError.paymentIntentInTerminalState(status: paymentIntent.status)
            }
            intent = .paymentIntent(paymentIntent)
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
                throw PaymentSheetError.setupIntentInTerminalState(status: setupIntent.status)
            }
            intent = .setupIntent(setupIntent)

        case .deferredIntent(let intentConfig):
            let elementsSession = try await configuration.apiClient.retrieveElementsSession(withIntentConfig: intentConfig)
            intent = .deferredIntent(elementsSession: elementsSession, intentConfig: intentConfig)
        }
        // Ensure that there's at least 1 payment method type available for the intent and configuration.
        let paymentMethodTypes = PaymentSheet.PaymentMethodType.filteredPaymentMethodTypes(from: intent, configuration: configuration)
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

    static func fetchSavedPaymentMethods(configuration: PaymentSheet.Configuration) async throws -> [STPPaymentMethod] {
        let savedPaymentMethodTypes: [STPPaymentMethodType] = [.card, .USBankAccount, .SEPADebit]  // hardcoded for now
        guard let customerID = configuration.customer?.id, let ephemeralKey = configuration.customer?.ephemeralKeySecret else {
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
                // Remove cards that originated from Apple or Google Pay
                paymentMethods = paymentMethods.filter { paymentMethod in
                    let isAppleOrGooglePay = paymentMethod.type == .card && [.applePay, .googlePay].contains(paymentMethod.card?.wallet?.type)
                    return !isAppleOrGooglePay
                }
                continuation.resume(returning: paymentMethods)
            }
        }
    }
}
