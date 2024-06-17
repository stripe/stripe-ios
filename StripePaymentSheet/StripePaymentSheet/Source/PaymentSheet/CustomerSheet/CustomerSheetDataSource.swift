//
//  CustomerSheetDataSource.swift
//  StripePaymentSheet
//

import Foundation

class CustomerSheetDataSource {
    enum DataSource {
        case customerSession(CustomerSessionAdapter)
        case customerAdapter(CustomerAdapter)
    }
    let dataSource: DataSource
    let configuration: CustomerSheet.Configuration

    init(_ customerSessionAdapter: CustomerAdapter,
         configuration: CustomerSheet.Configuration) {
        self.dataSource = .customerAdapter(customerSessionAdapter)
        self.configuration = configuration
    }

    init(_ customerSessionAdapter: CustomerSessionAdapter) {
        self.dataSource = .customerSession(customerSessionAdapter)
        self.configuration = customerSessionAdapter.configuration
    }

    func loadPaymentMethodInfo(completion: @escaping (Result<([STPPaymentMethod], CustomerPaymentOption?, STPElementsSession), Error>) -> Void) {
        switch dataSource {
        case .customerSession(let customerSessionAdapter):
            loadPaymentMethodInfo(customerSessionAdapter: customerSessionAdapter, completion: completion)
        case .customerAdapter(let customerAdapter):
            return loadPaymentMethodInfo(customerAdapter: customerAdapter, completion: completion)
        }
    }
    func loadPaymentMethodInfo(customerSessionAdapter: CustomerSessionAdapter,
                               completion: @escaping (Result<([STPPaymentMethod], CustomerPaymentOption?, STPElementsSession), Error>) -> Void) {
        Task {
            do {
                async let (elementsSessionResult, customerSessionClientSecret) = try customerSessionAdapter.elementsSessionWithCustomerSessionClientSecret()

                // Ensure local specs are loaded prior to the ones from elementSession
                await loadFormSpecs()
                let customerId = try await customerSessionClientSecret.customerId
                let paymentOption = customerSessionAdapter.fetchSelectedPaymentOption(for: customerId)
                let elementSession = try await elementsSessionResult

                // Override with specs from elementSession
                _ = FormSpecProvider.shared.loadFrom(elementSession.paymentMethodSpecs as Any)

                let savedPaymentMethods = elementSession.customer?.paymentMethods ?? []
                return completion(.success((savedPaymentMethods, paymentOption, elementSession)))
            } catch {
                return completion(.failure(error))
            }
        }
    }

    func loadPaymentMethodInfo(customerAdapter: CustomerAdapter, completion: @escaping (Result<([STPPaymentMethod], CustomerPaymentOption?, STPElementsSession), Error>) -> Void) {
        Task {
            do {
                async let paymentMethodsResult = try customerAdapter.fetchPaymentMethods()
                async let selectedPaymentMethodResult = try customerAdapter.fetchSelectedPaymentOption()
                async let elementsSessionResult = try self.configuration.apiClient.retrieveElementsSessionForCustomerSheet(paymentMethodTypes: customerAdapter.paymentMethodTypes,
                                                                                                                           clientDefaultPaymentMethod: nil,
                                                                                                                           customerSessionClientSecret: nil)

                // Ensure local specs are loaded prior to the ones from elementSession
                await loadFormSpecs()

                let (paymentMethods, selectedPaymentMethod, elementSession) = try await (paymentMethodsResult, selectedPaymentMethodResult, elementsSessionResult)

                // Override with specs from elementSession
                _ = FormSpecProvider.shared.loadFrom(elementSession.paymentMethodSpecs as Any)

                completion(.success((paymentMethods, selectedPaymentMethod, elementSession)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func loadFormSpecs() async {
        await withCheckedContinuation { continuation in
            Task {
                FormSpecProvider.shared.load { _ in
                    continuation.resume()
                }
            }
        }
    }
}

extension CustomerSheetDataSource {
    func merchantSupportedPaymentMethodTypes(elementsSession: STPElementsSession) -> [STPPaymentMethodType] {
        switch dataSource {
        case .customerSession:
            return elementsSession.orderedPaymentMethodTypes
        case .customerAdapter(let customerAdapter):
            return customerAdapter.canCreateSetupIntents ? elementsSession.orderedPaymentMethodTypes : [.card]
        }
    }

    var canCreateSetupIntents: Bool {
        switch dataSource {
        case .customerAdapter(let customerAdapter):
            return customerAdapter.canCreateSetupIntents
        case .customerSession:
            return true
        }
    }

    func attachPaymentMethod(_ paymentMethodId: String) async throws {
        switch dataSource {
        case .customerAdapter(let customerAdapter):
            try await customerAdapter.attachPaymentMethod(paymentMethodId)
        case .customerSession:
            assertionFailure("Attach payment methods are not supported with CustomerSessions")
        }
    }

    func fetchSavedPaymentMethods() async throws -> [STPPaymentMethod]? {
        switch dataSource {
        case .customerAdapter(let customerAdapter):
            return try await customerAdapter.fetchPaymentMethods()
        case .customerSession(let customerSessionAdapter):
            let elementsSessionResult = try await customerSessionAdapter.elementsSession()
            return elementsSessionResult.customer?.paymentMethods
        }
    }

    func fetchSetupIntentClientSecret() async throws -> String? {
        switch dataSource {
        case .customerAdapter(let customerAdapter):
            return try await customerAdapter.setupIntentClientSecretForCustomerAttach()
        case .customerSession(let customerSessionAdapter):
            return try await customerSessionAdapter.intentConfiguration.setupIntentClientSecretProvider()
        }
    }

    func setSelectedPaymentOption(paymentOption: CustomerPaymentOption?) async throws {
        switch dataSource {
        case .customerAdapter(let customerAdapter):
            try await customerAdapter.setSelectedPaymentOption(paymentOption: paymentOption)
        case .customerSession(let customerSessionAdapter):
            let customerSessionClientSecret = try await customerSessionAdapter.customerSessionClientSecretProvider()
            CustomerPaymentOption.setDefaultPaymentMethod(paymentOption, forCustomer: customerSessionClientSecret.customerId)
        }
    }

    func detachPaymentMethod(paymentMethodId: String) async throws {
        switch dataSource {
        case .customerAdapter(let customerAdapter):
            try await customerAdapter.detachPaymentMethod(paymentMethodId: paymentMethodId)
        case .customerSession(let customerSessionAdapter):
            try await customerSessionAdapter.detachPaymentMethod(paymentMethodId: paymentMethodId)
        }
    }

    func updatePaymentMethod(paymentMethodId: String, paymentMethodUpdateParams: STPPaymentMethodUpdateParams) async throws -> STPPaymentMethod {
        switch dataSource {
        case .customerAdapter(let customerAdapter):
            return try await customerAdapter.updatePaymentMethod(paymentMethodId: paymentMethodId, paymentMethodUpdateParams: paymentMethodUpdateParams)
        case .customerSession(let customerSessionAdapter):
            return try await customerSessionAdapter.updatePaymentMethod(paymentMethodId: paymentMethodId, paymentMethodUpdateParams: paymentMethodUpdateParams)
        }
    }

    func savePaymentMethodConsentBehavior() -> PaymentSheetFormFactory.SavePaymentMethodConsentBehavior {
        switch dataSource {
        case .customerAdapter:
            return .legacy
        case .customerSession:
            return .customerSheetWithCustomerSession
        }
    }

    func paymentMethodRemove(elementsSession: STPElementsSession) -> Bool {
        switch dataSource {
        case .customerAdapter:
            return true
        case .customerSession:
            return elementsSession.allowsRemovalOfPaymentMethodsForCustomerSheet()
        }
    }
}
