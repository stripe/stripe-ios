//
//  STPBackendAPIAdapter.swift
//  StripeiOS
//
//  Created by Jack Flintermann on 1/12/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

@_spi(STP) import StripePayments


/// A "bridge" from our pre-built UI (`STPPaymentContext`, `STPPaymentOptionsViewController`)
/// to your backend to fetch Customer-related information needed to power those views.
/// Typically, you will not need to implement this protocol yourself. You
/// should instead use `STPCustomerContext`, which implements <STPBackendAPIAdapter>
/// and manages retrieving and updating a Stripe customer for you.
/// - seealso: STPCustomerContext.h
/// If you would prefer retrieving and updating your Stripe customer object via
/// your own backend instead of using `STPCustomerContext`, you should make your
/// application's API client conform to this interface.
@_spi(PrivateBetaSavedPaymentMethodsSheet) public protocol CustomerAdapter {
    //    TODO: this is now decoupled from STPCustomer and the legacy API parameters, which is nice
    /// Retrieves a list of Payment Methods attached to a customer.
    /// If you are implementing your own <STPBackendAPIAdapter>:
    /// Call the list method ( https://stripe.com/docs/api/payment_methods/list )
    /// with the Stripe customer. If this API call succeeds, call `completion(paymentMethods)`
    /// with the list of PaymentMethods. Otherwise, call `completion(error)` with the error
    /// that occurred.
    /// - Parameter completion:  Call this callback with the list of Payment Methods attached to the
    /// customer.  For example, `completion(paymentMethods)` (if your call succeeds) or
    /// `completion(error)` if an error is returned.
    func fetchPaymentMethods() async throws -> [STPPaymentMethod]
    
    /// Adds a Payment Method to a customer.
    /// If you are implementing your own <STPBackendAPIAdapter>:
    /// On your backend, retrieve the Stripe customer associated with your logged-in user.
    /// Then, call the Attach method on the Payment Method with that customer's ID
    /// ( https://stripe.com/docs/api/payment_methods/attach ). If this API call succeeds,
    /// call `completion(nil)`. Otherwise, call `completion(error)` with the error that
    /// occurred.
    /// - Parameters:
    ///   - paymentMethod:   A valid Payment Method
    ///   - completion:      Call this callback when you're done adding the payment method
    /// to the customer on your backend. For example, `completion(nil)` (if your call succeeds)
    /// or `completion(error)` if an error is returned.
    func attachPaymentMethod(_ paymentMethodId: String) async throws
    
    /// Deletes the given Payment Method from the customer.
    /// If you are implementing your own <STPBackendAPIAdapter>:
    /// Call the Detach method ( https://stripe.com/docs/api/payment_methods/detach )
    /// on the Payment Method. If this API call succeeds, call `completion(nil)`.
    /// Otherwise, call `completion(error)` with the error that occurred.
    /// - Parameters:
    ///   - paymentMethod:   The Payment Method to delete from the customer
    ///   - completion:      Call this callback when you're done deleting the Payment Method
    /// from the customer on your backend. For example, `completion(nil)` (if your call
    /// succeeds) or `completion(error)` if an error is returned.
    func detachPaymentMethod(paymentMethodId: String) async throws
    
    /// Set the last selected Payment Method Option
    func setSelectedPaymentMethodOption(paymentOption: PersistablePaymentMethodOption?) async throws
    
    /// Retrieve the last selected Payment Method Option for the customer
    func fetchSelectedPaymentMethodOption() async throws -> PersistablePaymentMethodOption?
    
    /// Returns the a client secret configured to attach a new payment method to a customer.
    /// See docs:
    func setupIntentClientSecretForCustomerAttach() async throws -> String
    
    /// Whether this backend adapter is able to create setup intents.
    var canCreateSetupIntents: Bool { get }
}

@_spi(PrivateBetaSavedPaymentMethodsSheet) public struct CustomerEphemeralKey {
    @_spi(PrivateBetaSavedPaymentMethodsSheet) public let id: String
    @_spi(PrivateBetaSavedPaymentMethodsSheet) public let ephemeralKeySecret: String
    
    @_spi(PrivateBetaSavedPaymentMethodsSheet) public init(customerId: String, ephemeralKeySecret: String) {
        self.id = customerId
        self.ephemeralKeySecret = ephemeralKeySecret
    }
}

// expose swift
// write a legacy and non-legacy customer adapter
@_spi(PrivateBetaSavedPaymentMethodsSheet) open class StripeCustomerAdapter: CustomerAdapter {
    let customerEphemeralKeyProvider: (() async throws -> CustomerEphemeralKey)
    let setupIntentClientSecretProvider: (() async throws -> String)?
    let apiClient: STPAPIClient
    /// - Parameter setupIntentClientSecretProvider: Optional, but recommended. Return a SetupIntent Client Secret when requested. This will be used to confirm a new payment method.
    /// If this is missing, you will only be able to add cards without authentication steps.
    public init(customerEphemeralKeyProvider: @escaping () async throws -> CustomerEphemeralKey,
                setupIntentClientSecretProvider: (() async throws -> String)? = nil,
                apiClient: STPAPIClient = .shared) {
        self.customerEphemeralKeyProvider = customerEphemeralKeyProvider
        self.setupIntentClientSecretProvider = setupIntentClientSecretProvider
        self.apiClient = apiClient
    }

    private struct CachedCustomerEphemeralKey {
        let customerEphemeralKey: CustomerEphemeralKey
        let cacheDate = Date()
    }
    
    private var _cachedEphemeralKey: CachedCustomerEphemeralKey?
    var customerEphemeralKey: CustomerEphemeralKey {
        get async throws {
            if let cachedKey = _cachedEphemeralKey,
               cachedKey.cacheDate + CachedCustomerMaxAge > Date() {
                return cachedKey.customerEphemeralKey
            }
            let newKey = try await self.customerEphemeralKeyProvider()
            _cachedEphemeralKey = CachedCustomerEphemeralKey(customerEphemeralKey: newKey)
            return newKey
        }
    }
    
    public var canCreateSetupIntents: Bool {
        return setupIntentClientSecretProvider != nil
    }
    
    /// Retrieves a list of Payment Methods attached to a customer.
    /// If you are implementing your own <CustomerAdapter>:
    /// Call the list method ( https://stripe.com/docs/api/payment_methods/list )
    /// with the Stripe customer. If this API call succeeds, call `completion(paymentMethods)`
    /// with the list of PaymentMethods. Otherwise, call `completion(error)` with the error
    /// that occurred.
    /// - Parameter completion:  Call this callback with the list of Payment Methods attached to the
    /// customer.  For example, `completion(paymentMethods)` (if your call succeeds) or
    /// `completion(error)` if an error is returned.
    open func fetchPaymentMethods() async throws -> [STPPaymentMethod] {
        let customerEphemeralKey = try await customerEphemeralKey
        return try await withCheckedThrowingContinuation({ continuation in
            // List the Customer's saved PaymentMethods
            let savedPaymentMethodTypes: [STPPaymentMethodType] = [.card, .USBankAccount]  // hardcoded for now
            apiClient.listPaymentMethods(
                forCustomer: customerEphemeralKey.id,
                using: customerEphemeralKey.ephemeralKeySecret,
                types: savedPaymentMethodTypes
            ) { paymentMethods, error in
                guard let paymentMethods = paymentMethods, error == nil else {
                    let error = error ?? NSError() // TODO: make default error
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(with: .success(paymentMethods))
            }
        })
    }
    
    /// Adds a Payment Method to a customer.
    /// If you are implementing your own <STPBackendAPIAdapter>:
    /// On your backend, retrieve the Stripe customer associated with your logged-in user.
    /// Then, call the Attach method on the Payment Method with that customer's ID
    /// ( https://stripe.com/docs/api/payment_methods/attach ). If this API call succeeds,
    /// call `completion(nil)`. Otherwise, call `completion(error)` with the error that
    /// occurred.
    /// - Parameters:
    ///   - paymentMethod:   A valid Payment Method
    ///   - completion:      Call this callback when you're done adding the payment method
    /// to the customer on your backend. For example, `completion(nil)` (if your call succeeds)
    /// or `completion(error)` if an error is returned.
    open func attachPaymentMethod(_ paymentMethodId: String) async throws {
        let customerEphemeralKey = try await customerEphemeralKey
        return try await withCheckedThrowingContinuation({ continuation in
            apiClient.attachPaymentMethod(paymentMethodId, customerID: customerEphemeralKey.id, ephemeralKeySecret: customerEphemeralKey.ephemeralKeySecret) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume()
            }
        })
    }
  
    /// Deletes the given Payment Method from the customer.
    /// If you are implementing your own <STPBackendAPIAdapter>:
    /// Call the Detach method ( https://stripe.com/docs/api/payment_methods/detach )
    /// on the Payment Method. If this API call succeeds, call `completion(nil)`.
    /// Otherwise, call `completion(error)` with the error that occurred.
    /// - Parameters:
    ///   - paymentMethod:   The Payment Method to delete from the customer
    ///   - completion:      Call this callback when you're done deleting the Payment Method
    /// from the customer on your backend. For example, `completion(nil)` (if your call
    /// succeeds) or `completion(error)` if an error is returned.
    open func detachPaymentMethod(paymentMethodId: String) async throws {
        let customerEphemeralKey = try await customerEphemeralKey
        return try await withCheckedThrowingContinuation({ continuation in
            apiClient.detachPaymentMethod(paymentMethodId, fromCustomerUsing: customerEphemeralKey.id) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume()
            }
        })
    }
    
    /// You can subclass this to change the destination of the selected payment method option.
    open func setSelectedPaymentMethodOption(paymentOption: PersistablePaymentMethodOption?) async throws {
        let customerEphemeralKey = try await customerEphemeralKey
        
        PersistablePaymentMethodOption.setDefaultPaymentMethod(paymentOption, forCustomer: customerEphemeralKey.id)
    }
    
    /// You can subclass this to change the destination of the selected payment method option.
    open func fetchSelectedPaymentMethodOption() async throws -> PersistablePaymentMethodOption? {
        let customerEphemeralKey = try await customerEphemeralKey
        
        return PersistablePaymentMethodOption.defaultPaymentMethod(for: customerEphemeralKey.id)
    }
    
    /// Returns the a client secret configured to attach a new payment method to a customer.
    /// See docs:
    open func setupIntentClientSecretForCustomerAttach() async throws -> String {
        guard let setupIntentClientSecretProvider = setupIntentClientSecretProvider else {
            throw NSError() // no client secret provider!
        }
        return try await setupIntentClientSecretProvider()
    }
}

/// Stores the key we use in NSUserDefaults to save a dictionary of Customer id to their last selected payment method ID
private let kLastSelectedPaymentMethodDefaultsKey =
    UserDefaults.StripePaymentsUIKeys.customerToLastSelectedPaymentMethod.rawValue
private let CachedCustomerMaxAge: TimeInterval = 60 * 30 // 30 minutes, server-side timeout is 60
