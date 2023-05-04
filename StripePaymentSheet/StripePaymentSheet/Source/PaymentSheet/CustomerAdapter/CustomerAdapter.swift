//
//  CustomerAdapter.swift
//  StripeiOS
//
//  Copyright © 2023 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI

/// A "bridge" from wallet mode to your backend to fetch Customer-related information.
/// Typically, you will not need to implement this protocol yourself. You
/// should instead use `StripeCustomerAdapter`, which implements <CustomerAdapter>
/// and manages retrieving and updating a Stripe customer for you.
/// If you would prefer retrieving and updating your Stripe customer object via
/// your own backend instead of using `StripeCustomerAdapter`, you should make your
/// application's API client conform to this interface.
@_spi(PrivateBetaSavedPaymentMethodsSheet) public protocol CustomerAdapter {
    /// Retrieves a list of Payment Methods attached to a customer.
    /// If you are implementing your own <CustomerAdapter>:
    /// Call the list method ( https://stripe.com/docs/api/payment_methods/list )
    /// with the Stripe customer. If this API call succeeds, return the list of payment methods.
    /// Otherwise, throw an error.
    func fetchPaymentMethods() async throws -> [STPPaymentMethod]

    /// Adds a Payment Method to a customer.
    /// If you are implementing your own <CustomerAdapter>:
    /// On your backend, retrieve the Stripe customer associated with your logged-in user.
    /// Then, call the Attach method on the Payment Method with that customer's ID
    /// ( https://stripe.com/docs/api/payment_methods/attach ).
    /// If this API call fails, throw the error that occurred.
    /// - Parameters:
    ///   - paymentMethod:   A valid Stripe Payment Method ID
    func attachPaymentMethod(_ paymentMethodId: String) async throws

    /// Deletes the given Payment Method from the customer.
    /// If you are implementing your own <CustomerAdapter>:
    /// Call the Detach method ( https://stripe.com/docs/api/payment_methods/detach )
    /// on the Payment Method.
    /// If this API call fails, throw the error that occurred.
    /// - Parameters:
    ///   - paymentMethod:   The Stripe Payment Method ID to delete from the customer
    func detachPaymentMethod(paymentMethodId: String) async throws

    /// Set the last selected payment method for the customer.
    /// To unset the default payment method, pass `nil` as the `paymentOption`.
    /// If you are implementing your own <CustomerAdapter>:
    /// Save a representation of the passed `paymentOption` as the customer's default payment method.
    func setSelectedPaymentMethodOption(paymentOption: PersistablePaymentMethodOption?) async throws

    /// Retrieve the last selected payment method for the customer.
    /// If you are implementing your own <CustomerAdapter>:
    /// Return a PersistablePaymentMethodOption for the customer's default selected payment method.
    /// If no default payment method is selected, return nil.
    func fetchSelectedPaymentMethodOption() async throws -> PersistablePaymentMethodOption?

    /// Creates a SetupIntent configured to attach a new payment method to a customer, then returns the client secret for the created SetupIntent.
    func setupIntentClientSecretForCustomerAttach() async throws -> String

    /// Whether this CustomerAdapter is able to create Setup Intents.
    /// A Setup Intent is recommended when attaching a new card to a Customer, and required for non-card payment methods.
    /// If you are implementing your own <CustomerAdapter>:
    /// Return `true` if setupIntentClientSecretForCustomerAttach is implemented. Otherwise, return false.
    var canCreateSetupIntents: Bool { get }
}

/// An ephemeral key for the Stripe Customer
@_spi(PrivateBetaSavedPaymentMethodsSheet) public struct CustomerEphemeralKey {
    /// The identifier of the Stripe Customer object.
    /// See https://stripe.com/docs/api/customers/object#customer_object-id
    @_spi(PrivateBetaSavedPaymentMethodsSheet) public let id: String
    /// A short-lived token that allows the SDK to access a Customer's payment methods
    @_spi(PrivateBetaSavedPaymentMethodsSheet) public let ephemeralKeySecret: String

    /// Initializes a CustomerConfiguration
    @_spi(PrivateBetaSavedPaymentMethodsSheet) public init(customerId: String, ephemeralKeySecret: String) {
        self.id = customerId
        self.ephemeralKeySecret = ephemeralKeySecret
    }
}

/// A `StripeCustomerAdapter` retrieves and updates a Stripe customer and their attached
/// payment methods using an ephemeral key, a short-lived API key scoped to a specific
/// customer object. If your current user logs out of your app and a new user logs in,
/// be sure to create a new instance of `StripeCustomerAdapter`.
@_spi(PrivateBetaSavedPaymentMethodsSheet) open class StripeCustomerAdapter: CustomerAdapter {
    let customerEphemeralKeyProvider: (() async throws -> CustomerEphemeralKey)
    let setupIntentClientSecretProvider: (() async throws -> String)?
    let apiClient: STPAPIClient

    /// - Parameter customerEphemeralKeyProvider: A block that returns a CustomerEphemeralKey.
    ///             When called, create an ephemeral key for a customer on your backend, then return it.
    /// - Parameter setupIntentClientSecretProvider: Optional but recommended for cards, required for other payment methods.
    ///             Return a SetupIntent client secret when requested. This will be used to confirm a new payment method.
    ///             If this is missing, you will only be able to add cards without authentication steps.
    /// - Parameter apiClient: The STPAPIClient instance for this StripeCustomerAdapter. Defaults to `.shared`.
    ///
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
                    let error = error ?? PaymentSheetError.unknown(debugDescription: "Unexpected response from Stripe API.") // TODO: make a better default error
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(with: .success(paymentMethods))
            }
        })
    }

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

    open func setSelectedPaymentMethodOption(paymentOption: PersistablePaymentMethodOption?) async throws {
        let customerEphemeralKey = try await customerEphemeralKey

        PersistablePaymentMethodOption.setDefaultPaymentMethod(paymentOption, forCustomer: customerEphemeralKey.id)
    }

    open func fetchSelectedPaymentMethodOption() async throws -> PersistablePaymentMethodOption? {
        let customerEphemeralKey = try await customerEphemeralKey

        return PersistablePaymentMethodOption.defaultPaymentMethod(for: customerEphemeralKey.id)
    }

    open func setupIntentClientSecretForCustomerAttach() async throws -> String {
        guard let setupIntentClientSecretProvider = setupIntentClientSecretProvider else {
            throw PaymentSheetError.unknown(debugDescription: "setupIntentClientSecretForCustomerAttach, but setupIntentClientSecretProvider is nil") // TODO: This is a programming error, setupIntentClientSecretForCustomerAttach should not be called if canCreateSetupIntents is false
        }
        return try await setupIntentClientSecretProvider()
    }
}

/// Stores the key we use in NSUserDefaults to save a dictionary of Customer id to their last selected payment method ID
private let kLastSelectedPaymentMethodDefaultsKey =
    UserDefaults.StripePaymentSheetKeys.customerToLastSelectedPaymentMethod.rawValue
private let CachedCustomerMaxAge: TimeInterval = 60 * 30 // 30 minutes, server-side timeout is 60
