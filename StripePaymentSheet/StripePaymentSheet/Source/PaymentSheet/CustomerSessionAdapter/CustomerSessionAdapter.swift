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

    func elementsSessionWithCustomerSessionClientSecret() async throws -> (STPElementsSession, CachedCustomerSessionClientSecret) {
        if let cachedCustomerSessionClientSecret = self._cachedCustomerSessionClientSecret,
           !cachedCustomerSessionClientSecret.isExpired() {
            let elementsSession = try await elementsSession(customerSessionClientSecret: cachedCustomerSessionClientSecret.customerSessionClientSecret)
            return (elementsSession, cachedCustomerSessionClientSecret)
        } else {
            let customerSessionClientSecret = try await customerSessionClientSecretProvider()
            let elementsSessionResponse = try await elementsSession(customerSessionClientSecret: customerSessionClientSecret)
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

    private func elementsSession(customerSessionClientSecret: CustomerSessionClientSecret) async throws -> STPElementsSession{
        return try await self.configuration.apiClient.retrieveElementsSessionForCustomerSheet(paymentMethodTypes: intentConfiguration.paymentMethodTypes,
                                                                                              customerSessionClientSecret: customerSessionClientSecret)
    }
}
extension CustomerSessionAdapter {

    func detachPaymentMethod(paymentMethodId: String) async throws {
        let cachedCustomerSessionClientSecret = try await cachedCustomerSessionClientSecret()
        return try await withCheckedThrowingContinuation({ continuation in
            self.configuration.apiClient.detachPaymentMethodRemoveDuplicates(paymentMethodId,
                                                                             customerId: cachedCustomerSessionClientSecret.customerId,
                                                                             fromCustomerUsing: cachedCustomerSessionClientSecret.apiKey) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume()
            }
        })
    }

    func updatePaymentMethod(paymentMethodId: String, paymentMethodUpdateParams: STPPaymentMethodUpdateParams) async throws -> STPPaymentMethod {
        let cachedCustomerSessionClientSecret = try await cachedCustomerSessionClientSecret()
        return try await self.configuration.apiClient.updatePaymentMethod(with: paymentMethodId,
                                                                          paymentMethodUpdateParams: paymentMethodUpdateParams,
                                                                          ephemeralKeySecret: cachedCustomerSessionClientSecret.apiKey)
    }
}
