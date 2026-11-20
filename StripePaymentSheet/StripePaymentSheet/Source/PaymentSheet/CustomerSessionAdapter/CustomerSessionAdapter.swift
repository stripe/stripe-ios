//
//  CustomerSessionAdapter.swift
//  StripePaymentSheet
//

import Foundation
@_spi(InternalOnlyAPI) import StripePayments

private let CachedCustomerMaxAge: TimeInterval = 60 * 30 // 30 minutes, server-side timeout is 60

class CustomerSessionAdapter {
    typealias CustomerSessionClientSecretProvider = () async throws -> CustomerSessionClientSecret

    private let customerSessionClientSecretProvider: CustomerSessionClientSecretProvider
    private var _cachedCustomerSessionClientSecret: CachedCustomerSessionClientSecret?
    private let timeProvider: () -> Date

    private var unexpiredCachedSession: CachedCustomerSessionClientSecret? {
        guard let cachedSession = _cachedCustomerSessionClientSecret, !cachedSession.isExpired() else {
            return nil
        }
        return cachedSession
    }
    let intentConfiguration: CustomerSheet.IntentConfiguration
    let configuration: CustomerSheet.Configuration

    struct CachedCustomerSessionClientSecret {
        let customerSessionClientSecret: CustomerSessionClientSecret
        let apiKey: String
        let customerId: String
        let cacheDate: Date
        private let timeProvider: () -> Date

        // Preserve existing local selections for integrations that still supply a Customer ID.
        var localCustomerId: String {
            return customerSessionClientSecret.customerId ?? customerId
        }

        init(customerSessionClientSecret: CustomerSessionClientSecret,
             apiKey: String,
             customerId: String,
             timeProvider: @escaping () -> Date = Date.init) {
            self.customerSessionClientSecret = customerSessionClientSecret
            self.customerId = customerId
            self.cacheDate = timeProvider()
            self.apiKey = apiKey
            self.timeProvider = timeProvider
        }

        func isExpired() -> Bool {
            return timeProvider() >= (cacheDate + CachedCustomerMaxAge)
        }
    }

    init(customerSessionClientSecretProvider: @escaping CustomerSessionClientSecretProvider,
         intentConfiguration: CustomerSheet.IntentConfiguration,
         configuration: CustomerSheet.Configuration,
         timeProvider: @escaping () -> Date = Date.init) {
        self.customerSessionClientSecretProvider = customerSessionClientSecretProvider
        self.intentConfiguration = intentConfiguration
        self.configuration = configuration
        self.timeProvider = timeProvider
    }

    func cachedCustomerSessionClientSecret() async throws -> CachedCustomerSessionClientSecret {
        if let cachedSession = unexpiredCachedSession {
            return cachedSession
        }
        let (_, cachedSession) = try await elementsSessionWithCustomerSessionClientSecret()
        return cachedSession
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
        let cachedSession = unexpiredCachedSession
        let clientSecret: CustomerSessionClientSecret
        if let cachedSession {
            clientSecret = cachedSession.customerSessionClientSecret
        } else {
            clientSecret = try await customerSessionClientSecretProvider()
        }

        let elementsSession = try await elementsSession(
            customerSessionClientSecret: clientSecret,
            setupIntentClientSecret: setupIntentClientSecret,
            customerId: cachedSession?.localCustomerId ?? clientSecret.customerId
        )
        if let cachedSession {
            return (elementsSession, cachedSession)
        }
        guard let customerSession = elementsSession.customer?.customerSession,
              !customerSession.apiKey.isEmpty else {
            throw CustomerSheetError.unknown(debugDescription: "Failed to claim CustomerSession")
        }

        let newSession = CachedCustomerSessionClientSecret(
            customerSessionClientSecret: clientSecret,
            apiKey: customerSession.apiKey,
            customerId: customerSession.customer,
            timeProvider: timeProvider
        )
        _cachedCustomerSessionClientSecret = newSession
        return (elementsSession, newSession)
    }

    private func elementsSession(customerSessionClientSecret: CustomerSessionClientSecret, setupIntentClientSecret: String?, customerId: String?) async throws -> STPElementsSession {
        let clientDefaultPaymentMethod = customerId.flatMap { fetchClientDefaultPaymentMethod(for: $0) }
        if let setupIntentClientSecret {
            return try await self.configuration.apiClient.retrieveElementsSessionForCustomerSheet(setupIntentClientSecret: setupIntentClientSecret,
                                                                                                  clientDefaultPaymentMethod: clientDefaultPaymentMethod,
                                                                                                  customerSessionClientSecret: customerSessionClientSecret)
        } else {
            return try await self.configuration.apiClient.retrieveDeferredElementsSessionForCustomerSheet(paymentMethodTypes: intentConfiguration.paymentMethodTypes,
                                                                                                          onBehalfOf: intentConfiguration.onBehalfOf,
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
