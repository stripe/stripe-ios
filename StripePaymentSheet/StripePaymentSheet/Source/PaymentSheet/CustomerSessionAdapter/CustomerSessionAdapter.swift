//
//  CustomerSessionAdapter.swift
//  StripePaymentSheet
//

import Foundation
@_spi(STP) import StripePayments

private let CachedCustomerMaxAge: TimeInterval = 60 * 30 // 30 minutes, server-side timeout is 60

class CustomerSessionAdapter {
    typealias CustomerSessionClientSecretProvider = () async throws -> CustomerSessionClientSecret

    let customerSessionClientSecretProvider: CustomerSessionClientSecretProvider
    private var _cachedCustomerSessionClientSecret: CachedCustomerSessionClientSecret?
    let intentConfiguration: CustomerSheet.IntentConfiguration
    let configuration: CustomerSheet.Configuration

    struct CachedCustomerSessionClientSecret {
        let customerSessionClientSecret: CustomerSessionClientSecret
        let apiKey: String
        let customerId: String
        let cacheDate: Date

        init(customerSessionClientSecret: CustomerSessionClientSecret, apiKey: String) {
            self.customerSessionClientSecret = customerSessionClientSecret
            self.customerId = customerSessionClientSecret.customerId
            self.cacheDate = Date()
            self.apiKey = apiKey
        }
        func isExpired() -> Bool {
            return cacheDate + CachedCustomerMaxAge > Date()
        }
    }

    init(customerSessionClientSecretProvider: @escaping CustomerSessionClientSecretProvider,
         intentConfiguration: CustomerSheet.IntentConfiguration,
         configuration: CustomerSheet.Configuration) {
        self.customerSessionClientSecretProvider = customerSessionClientSecretProvider
        self.intentConfiguration = intentConfiguration
        self.configuration = configuration
    }

    func cachedCustomerSessionClientSecret() async throws -> CachedCustomerSessionClientSecret {
        if let cachedCustomerSessionClientSecret = self._cachedCustomerSessionClientSecret,
           !cachedCustomerSessionClientSecret.isExpired() {
            return cachedCustomerSessionClientSecret
        }
        let (_, cachedCustomerSessionClientSecret) = try await elementsSessionWithCustomerSessionClientSecret()
        return cachedCustomerSessionClientSecret
    }

    func elementsSession() async throws -> STPElementsSession {
        let (elementsSession, _) = try await elementsSessionWithCustomerSessionClientSecret()
        return elementsSession
    }
    func elementsSession(setupIntentClientSecret: String) async throws -> (STPSetupIntent, STPElementsSession) {
        let (elementsSession, _) = try await elementsSessionWithCustomerSessionClientSecret(setupIntentClientSecret: setupIntentClientSecret)

        guard let paymentMethodPreference = elementsSession.allResponseFields["payment_method_preference"] as? [AnyHashable: Any],
              let setupIntentDict = paymentMethodPreference["setup_intent"] as? [AnyHashable: Any],
              let setupIntent = STPSetupIntent.decodedObject(fromAPIResponse: setupIntentDict) else {
            throw PaymentSheetError.unknown(debugDescription: "SetupIntent missing from v1/elements/sessions response")
        }
        return (setupIntent, elementsSession)
    }

    func elementsSessionWithCustomerSessionClientSecret(setupIntentClientSecret: String? = nil) async throws -> (STPElementsSession, CachedCustomerSessionClientSecret) {
        if let cachedCustomerSessionClientSecret = self._cachedCustomerSessionClientSecret,
           !cachedCustomerSessionClientSecret.isExpired() {
            let elementsSession = try await elementsSession(customerSessionClientSecret: cachedCustomerSessionClientSecret.customerSessionClientSecret, setupIntentClientSecret: setupIntentClientSecret)
            return (elementsSession, cachedCustomerSessionClientSecret)
        } else {
            let customerSessionClientSecret = try await customerSessionClientSecretProvider()
            let elementsSessionResponse = try await elementsSession(customerSessionClientSecret: customerSessionClientSecret, setupIntentClientSecret: setupIntentClientSecret)
            guard let apiKey = elementsSessionResponse.customer?.customerSession.apiKey,
                  !apiKey.isEmpty else {
                throw CustomerSheetError.unknown(debugDescription: "Failed to claim CustomerSession")
            }

            let tempCachedCustomerSessionClientSecret = CachedCustomerSessionClientSecret(customerSessionClientSecret: customerSessionClientSecret,
                                                                                          apiKey: apiKey)
            self._cachedCustomerSessionClientSecret = tempCachedCustomerSessionClientSecret
            return (elementsSessionResponse, tempCachedCustomerSessionClientSecret)
        }
    }

    private func elementsSession(customerSessionClientSecret: CustomerSessionClientSecret, setupIntentClientSecret: String?) async throws -> STPElementsSession {
        let clientDefaultPaymentMethod = fetchClientDefaultPaymentMethod(for: customerSessionClientSecret.customerId)
        if let setupIntentClientSecret {
            return try await self.configuration.apiClient.retrieveElementsSessionForCustomerSheet(setupIntentClientSecret: setupIntentClientSecret,
                                                                                                  clientDefaultPaymentMethod: clientDefaultPaymentMethod,
                                                                                                  customerSessionClientSecret: customerSessionClientSecret)
        } else {
            return try await self.configuration.apiClient.retrieveDeferredElementsSessionForCustomerSheet(paymentMethodTypes: intentConfiguration.paymentMethodTypes,
                                                                                                          clientDefaultPaymentMethod: clientDefaultPaymentMethod,
                                                                                                          customerSessionClientSecret: customerSessionClientSecret)
        }
    }
}
extension CustomerSessionAdapter {
    func fetchClientDefaultPaymentMethod(for customerId: String) -> String? {
        guard let defaultPaymentMethod = CustomerPaymentOption.localDefaultPaymentMethod(for: customerId),
           case .stripeId(let stripePaymentMethodId) = defaultPaymentMethod else {
            return nil
        }
        return stripePaymentMethodId
    }

    func fetchSelectedPaymentOption(for customerId: String, elementsSession: STPElementsSession) -> CustomerPaymentOption? {
        return CustomerPaymentOption.selectedPaymentMethod(for: customerId, elementsSession: elementsSession, surface: .customerSheet)
    }

    func detachPaymentMethod(paymentMethod: STPPaymentMethod) async throws {

        let cachedCustomerSessionClientSecret = try await cachedCustomerSessionClientSecret()
        return try await withCheckedThrowingContinuation({ continuation in
            if paymentMethod.type == .card {
                self.configuration.apiClient.detachPaymentMethodRemoveDuplicates(
                    paymentMethod.stripeId,
                    customerId: cachedCustomerSessionClientSecret.customerId,
                    fromCustomerUsing: cachedCustomerSessionClientSecret.apiKey,
                    withCustomerSessionClientSecret: cachedCustomerSessionClientSecret.customerSessionClientSecret.clientSecret) { error in
                        if let error = error {
                            continuation.resume(throwing: error)
                            return
                        }
                        continuation.resume()
                }
            } else {
                configuration.apiClient.detachPaymentMethod(
                    paymentMethod.stripeId,
                    fromCustomerUsing: cachedCustomerSessionClientSecret.apiKey,
                    withCustomerSessionClientSecret: cachedCustomerSessionClientSecret.customerSessionClientSecret.clientSecret) { error in
                        if let error = error {
                            continuation.resume(throwing: error)
                            return
                        }
                        continuation.resume()
                    }
            }
        })
    }

    func updatePaymentMethod(paymentMethodId: String, paymentMethodUpdateParams: STPPaymentMethodUpdateParams) async throws -> STPPaymentMethod {
        let cachedCustomerSessionClientSecret = try await cachedCustomerSessionClientSecret()
        return try await self.configuration.apiClient.updatePaymentMethod(with: paymentMethodId,
                                                                          paymentMethodUpdateParams: paymentMethodUpdateParams,
                                                                          ephemeralKeySecret: cachedCustomerSessionClientSecret.apiKey)
    }

    func setAsDefaultPaymentMethod(paymentMethodId: String) async throws -> STPCustomer {
        let cachedCustomerSessionClientSecret = try await cachedCustomerSessionClientSecret()
        return try await self.configuration.apiClient.setAsDefaultPaymentMethod(paymentMethodId, for: cachedCustomerSessionClientSecret.customerId, using: cachedCustomerSessionClientSecret.apiKey)
    }
}
