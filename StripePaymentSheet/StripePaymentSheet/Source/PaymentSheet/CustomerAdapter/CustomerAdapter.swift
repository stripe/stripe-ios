//
//  CustomerAdapter.swift
//  StripeiOS
//
//  Copyright © 2023 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI

/// A "bridge" from wallet mode to your backend to fetch Customer-related information.
/// Typically, you will not need to implement this protocol yourself. You
/// should instead use `StripeCustomerAdapter`, which implements <CustomerAdapter>
/// and manages retrieving and updating a Stripe customer for you.
/// If you would prefer retrieving and updating your Stripe customer object via
/// your own backend instead of using `StripeCustomerAdapter`, you should make your
/// application's API client conform to this interface.
/// - Warning:
/// When implementing your own CustomerAdapter, ensure your application complies with
/// all applicable laws and regulations, including data privacy and consumer protection.
public protocol CustomerAdapter {
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
    func setSelectedPaymentOption(paymentOption: CustomerPaymentOption?) async throws

    /// Retrieve the last selected payment method for the customer.
    /// If you are implementing your own <CustomerAdapter>:
    /// Return a CustomerPaymentOption for the customer's default selected payment method.
    /// If no default payment method is selected, return nil.
    func fetchSelectedPaymentOption() async throws -> CustomerPaymentOption?

    /// Creates a SetupIntent configured to attach a new payment method to a customer, then returns the client secret for the created SetupIntent.
    func setupIntentClientSecretForCustomerAttach() async throws -> String

    /// Updates a payment method with the provided  `STPPaymentMethodUpdateParams`.
    /// - Parameters:
    ///   - paymentMethodId: Identifier of the payment method to update.
    ///   - paymentMethodUpdateParams: The `STPPaymentMethodUpdateParams` to update the payment method with.
    /// - Returns: If this API call succeeds, returns the updated payment method, otherwise, throws an error.
    /// - seealso: https://stripe.com/docs/api/payment_methods/update
    func updatePaymentMethod(paymentMethodId: String, paymentMethodUpdateParams: STPPaymentMethodUpdateParams) async throws -> STPPaymentMethod

    /// A list of payment method types to display to the customers
    /// Valid values include: "card", "us_bank_account", "sepa_debit"
    /// If nil or empty, the SDK will dynamically determine the payment methods using your Stripe Dashboard settings.
    var paymentMethodTypes: [String]? { get }

    /// Whether this CustomerAdapter is able to create Setup Intents.
    /// A Setup Intent is recommended when attaching a new card to a Customer, and required for non-card payment methods.
    /// If you are implementing your own <CustomerAdapter>:
    /// Return `true` if setupIntentClientSecretForCustomerAttach is implemented. Otherwise, return false.
    var canCreateSetupIntents: Bool { get }
}

/// An ephemeral key for the Stripe Customer
public struct CustomerEphemeralKey {
    /// The identifier of the Stripe Customer object.
    /// See https://stripe.com/docs/api/customers/object#customer_object-id
    public let id: String
    /// A short-lived token that allows the SDK to access a Customer's payment methods
    public let ephemeralKeySecret: String

    /// Initializes a CustomerConfiguration
    public init(customerId: String, ephemeralKeySecret: String) {
        self.id = customerId
        self.ephemeralKeySecret = ephemeralKeySecret
    }
}

/// A `StripeCustomerAdapter` retrieves and updates a Stripe customer and their attached
/// payment methods using an ephemeral key, a short-lived API key scoped to a specific
/// customer object. If your current user logs out of your app and a new user logs in,
/// be sure to create a new instance of `StripeCustomerAdapter`.
open class StripeCustomerAdapter: CustomerAdapter {
    let customerEphemeralKeyProvider: (() async throws -> CustomerEphemeralKey)
    let setupIntentClientSecretProvider: (() async throws -> String)?
    let apiClient: STPAPIClient
    public let paymentMethodTypes: [String]?

    /// - Parameter customerEphemeralKeyProvider: A block that returns a CustomerEphemeralKey.
    ///             When called, create an ephemeral key for a customer on your backend, then return it.
    /// - Parameter setupIntentClientSecretProvider: Optional but recommended for cards, required for other payment methods.
    ///             Return a SetupIntent client secret when requested. This will be used to confirm a new payment method.
    ///             If this is missing, you will only be able to add cards without authentication steps.
    /// - Parameter apiClient: The STPAPIClient instance for this StripeCustomerAdapter. Defaults to `.shared`.
    ///
    public init(customerEphemeralKeyProvider: @escaping () async throws -> CustomerEphemeralKey,
                setupIntentClientSecretProvider: (() async throws -> String)? = nil,
                paymentMethodTypes: [String]? = nil,
                apiClient: STPAPIClient = .shared) {
        STPAnalyticsClient.sharedClient.addClass(toProductUsageIfNecessary: StripeCustomerAdapter.self)
        self.customerEphemeralKeyProvider = customerEphemeralKeyProvider
        self.setupIntentClientSecretProvider = setupIntentClientSecretProvider
        self.apiClient = apiClient
        self.paymentMethodTypes = paymentMethodTypes
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

            var savedPaymentMethodTypes = CustomerSheet.supportedPaymentMethods
            if let paymentMethodTypes = self.paymentMethodTypes {
                switch CustomerSheet.customerSheetSupportedPaymentMethodTypes(paymentMethodTypes) {
                case .success(let types):
                    if let types, !types.isEmpty {
                        savedPaymentMethodTypes = types
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                    return
                }
            }

            apiClient.listPaymentMethods(
                forCustomer: customerEphemeralKey.id,
                using: customerEphemeralKey.ephemeralKeySecret,
                types: savedPaymentMethodTypes,
                limit: 100
            ) { paymentMethods, error in
                guard var paymentMethods, error == nil else {
                    let error = error ?? PaymentSheetError.unexpectedResponseFromStripeAPI // TODO: make a better default error
                    continuation.resume(throwing: error)
                    return
                }
                // Remove cards that originated from Apple or Google Pay
                paymentMethods = paymentMethods.filter { paymentMethod in
                    let isAppleOrGooglePay = paymentMethod.type == .card && [.applePay, .googlePay].contains(paymentMethod.card?.wallet?.type)
                    return !isAppleOrGooglePay
                }
                continuation.resume(with: .success(paymentMethods))
            }
        })
    }

    open func attachPaymentMethod(_ paymentMethodId: String) async throws {
        let customerEphemeralKey = try await customerEphemeralKey

        return try await withCheckedThrowingContinuation({ continuation in
            apiClient.attachPaymentMethod(paymentMethodId,
                                          customerID: customerEphemeralKey.id,
                                          ephemeralKeySecret: customerEphemeralKey.ephemeralKeySecret) { error in
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
            apiClient.detachPaymentMethod(paymentMethodId, fromCustomerUsing: customerEphemeralKey.ephemeralKeySecret) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume()
            }
        })
    }

    open func setSelectedPaymentOption(paymentOption: CustomerPaymentOption?) async throws {
        let customerEphemeralKey = try await customerEphemeralKey

        CustomerPaymentOption.setDefaultPaymentMethod(paymentOption, forCustomer: customerEphemeralKey.id)
    }

    open func fetchSelectedPaymentOption() async throws -> CustomerPaymentOption? {
        let customerEphemeralKey = try await customerEphemeralKey

        return CustomerPaymentOption.localDefaultPaymentMethod(for: customerEphemeralKey.id)
    }

    open func setupIntentClientSecretForCustomerAttach() async throws -> String {
        guard let setupIntentClientSecretProvider = setupIntentClientSecretProvider else {
            throw PaymentSheetError.setupIntentClientSecretProviderNil // TODO: This is a programming error, setupIntentClientSecretForCustomerAttach should not be called if canCreateSetupIntents is false
        }
        return try await setupIntentClientSecretProvider()
    }

    open func updatePaymentMethod(paymentMethodId: String,
                                  paymentMethodUpdateParams: STPPaymentMethodUpdateParams) async throws -> STPPaymentMethod {
        let customerEphemeralKey = try await customerEphemeralKey

        return try await apiClient.updatePaymentMethod(with: paymentMethodId,
                                                       paymentMethodUpdateParams: paymentMethodUpdateParams,
                                                       ephemeralKeySecret: customerEphemeralKey.ephemeralKeySecret)
    }
}

@_spi(STP) extension StripeCustomerAdapter: STPAnalyticsProtocol {
    @_spi(STP) public static var stp_analyticsIdentifier = "StripeCustomerAdapter"
}

/// Stores the key we use in NSUserDefaults to save a dictionary of Customer id to their last selected payment method ID
private let kLastSelectedPaymentMethodDefaultsKey =
    UserDefaults.StripePaymentSheetKeys.customerToLastSelectedPaymentMethod.rawValue
private let CachedCustomerMaxAge: TimeInterval = 60 * 30 // 30 minutes, server-side timeout is 60
