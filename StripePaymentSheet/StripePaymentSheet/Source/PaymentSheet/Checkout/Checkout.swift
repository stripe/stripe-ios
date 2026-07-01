//
//  Checkout.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 2/25/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Combine
import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

/// Manages a Checkout Session lifecycle.
///
/// ```swift
/// let checkout = try await Checkout(clientSecret: "cs_xxx_secret_yyy")
/// print(checkout.session)
/// ```
///
/// The async initializer loads the session from Stripe before returning.
///
/// Observe loading state and session changes with SwiftUI by using ``isLoading`` and ``session``
/// (published via `ObservableObject`), or in UIKit by setting a ``delegate``.
@_spi(STP)
@_spi(ReactNativeSDK)
@MainActor
public final class Checkout: ObservableObject {
    // MARK: - Public Properties

    /// The current loading state of the checkout session.
    ///
    /// After initialization this is always ``false``. It transitions to ``true``
    /// while a mutation is in flight.
    @Published public internal(set) var isLoading: Bool = false {
        didSet {
            isLoading ? delegate?.checkoutDidBeginLoading(self) : delegate?.checkoutDidFinishLoading(self)
        }
    }

    /// The Checkout Session, updated from Stripe after every mutation.
    @Published public internal(set) var session: Session {
        didSet {
            delegate?.checkoutDidUpdateSession(self, session: session)
        }
    }

    /// The configuration supplied at initialization.
    public let configuration: Configuration

    /// A delegate notified when session data changes.
    public weak var delegate: CheckoutDelegate?

    // MARK: - Internal Properties

    weak var integrationDelegate: CheckoutIntegrationDelegate?

    let flagImageManager = AdaptivePricingFlagImageManager()
    let clientSecret: String
    let apiClient: STPAPIClient

    /// Serial queue of in-flight session updates. Each task waits for the previous task before running.
    var pendingOperations: [Task<Void, Error>] = [] {
        didSet {
            // If the queue has gone from empty to non-empty, we set
            //  isLoading to true. We avoid setting it if the queue
            //  was already non-empty to prevent duplicate delegate calls
            if !pendingOperations.isEmpty && !isLoading {
                isLoading = true
            }

            // If the queue has gone from non-empty to empty, we set
            //  isLoading to false. There shouldn't be a situation in
            //  which the isLoading is already false, but we check just in case.
            if pendingOperations.isEmpty && isLoading {
                isLoading = false
            }
        }
    }

    var isLastPendingOperation: Bool {
        pendingOperations.count <= 1
    }

    /// Default timeout used by ``awaitPendingOperations(timeout:)``.
    nonisolated static let defaultPendingOperationsTimeout: TimeInterval = 30

    /// Timeout enforced on the merchant's closure in ``runServerUpdate(_:)``.
    nonisolated static let serverUpdateTimeout: TimeInterval = 20

    // MARK: - Initialization

    /// Loads a Checkout Session from Stripe and returns a ready-to-use instance.
    ///
    /// - Parameters:
    ///   - clientSecret: The client secret for your Checkout Session (e.g. `cs_xxx_secret_yyy`).
    ///   - configuration: Configuration options for the checkout. Defaults to ``Configuration.init()``.
    ///   - apiClient: The API client to use. Defaults to ``STPAPIClient.shared``.
    /// - Throws: ``CheckoutError`` if the client secret is invalid or the session cannot be loaded.
    public init(
        clientSecret: String,
        configuration: Configuration = Configuration(),
        apiClient: STPAPIClient = .shared
    ) async throws {
        guard !clientSecret.isEmpty else {
            throw CheckoutError.invalidClientSecret
        }
        self.clientSecret = clientSecret
        self.configuration = configuration
        self.apiClient = apiClient

        let sessionId = Self.extractSessionId(from: clientSecret)
        do {
            let apiResponse = try await apiClient.initCheckoutSession(
                checkoutSessionId: sessionId,
                adaptivePricingAllowed: configuration.adaptivePricing.allowed
            )
            let loadedSession = apiResponse.makePublicSession()
            await flagImageManager.prefetchFlagImages(for: loadedSession)
            self.session = loadedSession
        } catch {
            throw CheckoutError.apiError(message: error.nonGenericDescription)
        }
    }

#if DEBUG
    /// Internal initializer for unit tests that injects a pre-loaded API response.
    init(
        clientSecret: String,
        configuration: Configuration = Configuration(),
        apiResponse: STPCheckoutSessionAPIResponse,
        apiClient: STPAPIClient = .shared
    ) async {
        self.clientSecret = clientSecret
        self.configuration = configuration
        self.apiClient = apiClient
        let loadedSession = apiResponse.makePublicSession()
        await flagImageManager.prefetchFlagImages(for: loadedSession)
        self.session = loadedSession
    }

    /// Synchronous test-only initializer that wraps a pre-loaded API response without async work.
    init(apiResponse: STPCheckoutSessionAPIResponse) {
        self.clientSecret = ""
        self.configuration = Configuration()
        self.apiClient = .shared
        self.session = apiResponse.makePublicSession()
    }
#endif

    // MARK: - Pending Operations

    /// Waits for all in-flight session updates (mutations, etc.) to complete.
    ///
    /// - Returns immediately if no operations are pending.
    /// - Waits for the operations pending when this method is called; operations
    ///   enqueued afterward are not included in this wait.
    /// - If any pending operation throws, the first such error is rethrown.
    /// - If the wait exceeds `timeout`, throws ``CheckoutError.timedOut``.
    ///
    /// - Parameters:
    ///   - timeout: Maximum time to wait, in seconds.
    func awaitPendingOperations(
        timeout: TimeInterval = Checkout.defaultPendingOperationsTimeout
    ) async throws {
        let snapshot = pendingOperations
        guard !snapshot.isEmpty else { return }

        let result = await withTimeout(timeout) {
            var firstError: Error?
            for operation in snapshot {
                do {
                    try await operation.value
                } catch {
                    firstError = firstError ?? error
                }
            }
            if let firstError { throw firstError }
        }
        if case .failure(let error) = result {
            throw error is TimeoutError ? CheckoutError.timedOut : error
        }
    }

    // MARK: - Promotion Codes

    /// Applies a promotion code to the session.
    /// - Parameter code: The promotion code to apply.
    /// - Throws: ``CheckoutError`` if applying the promotion code fails.
    public func applyPromotionCode(_ code: String) async throws {
        try await performUpdate(.setPromotionCode(code))
    }

    /// Removes the currently applied promotion code.
    /// - Throws: ``CheckoutError`` if removing the promotion code fails.
    public func removePromotionCode() async throws {
        try await performUpdate(.setPromotionCode(""))
    }

    // MARK: - Line Items

    /// Updates the quantity of a line item.
    /// - Parameters:
    ///   - lineItemId: The line item ID to update.
    ///   - quantity: The new quantity to set.
    /// - Throws: ``CheckoutError`` if the update fails.
    public func updateQuantity(lineItemId: String, quantity: Int) async throws {
        try await performUpdate(.setLineItemQuantity(lineItemId: lineItemId, quantity: quantity))
    }

    // MARK: - Shipping

    /// Selects a shipping option for the session.
    /// - Parameter optionId: The ID of the shipping rate to select.
    /// - Throws: ``CheckoutError`` if the update fails.
    public func selectShippingOption(_ optionId: String) async throws {
        try await performUpdate(.setShippingRate(optionId))
    }

    // MARK: - Addresses

    /// Sets the billing address for this checkout.
    ///
    /// The address is stored locally and merged into PaymentSheet configuration
    /// when presenting payment UI. If automatic tax is enabled and the tax
    /// address source is "billing", the address is also sent to the server to
    /// compute updated tax amounts.
    ///
    /// - Parameters:
    ///   - name: The customer's full name.
    ///   - phone: The customer's phone number.
    ///   - address: The billing address to set. To reset tax computation
    ///     to a country-only region, pass a ``Checkout.Address`` with just the country.
    /// - Throws: ``CheckoutError`` if the session is not open, or if
    ///   the server request fails.
    public func updateBillingAddress(
        name: String? = nil,
        phone: String? = nil,
        address: Address
    ) async throws {
        let contactAddress = ContactAddress(name: name, phone: phone, address: address)
        guard session.billingAddress != contactAddress else { return }
        if session.shouldSendTaxRegion(for: "billing") {
            try await performUpdate(.setTaxRegion(address), applying: {
                self.session.makeCopyOverriding(billingAddress: contactAddress)
            })
        } else {
            try await performUpdate(applying: {
                self.session.makeCopyOverriding(billingAddress: contactAddress)
            })
        }
    }

    /// Sets the shipping address for this checkout.
    ///
    /// The address is stored locally and merged into PaymentSheet configuration
    /// when presenting payment UI. If automatic tax is enabled and the tax
    /// address source is "shipping", the address is also sent to the server to
    /// compute updated tax amounts.
    ///
    /// - Parameters:
    ///   - name: The customer's full name.
    ///   - phone: The customer's phone number.
    ///   - address: The shipping address to set. To reset tax computation
    ///     to a country-only region, pass a ``Checkout.Address`` with just the country.
    /// - Throws: ``CheckoutError`` if the session is not open, or if
    ///   the server request fails.
    public func updateShippingAddress(
        name: String? = nil,
        phone: String? = nil,
        address: Address
    ) async throws {
        if let allowedCountries = session.allowedShippingCountries,
           !allowedCountries.contains(address.country) {
            throw CheckoutError.invalidShippingCountry(countryCode: address.country)
        }
        let contactAddress = ContactAddress(name: name, phone: phone, address: address)
        guard session.shippingAddress != contactAddress else { return }
        if session.shouldSendTaxRegion(for: "shipping") {
            try await performUpdate(.setTaxRegion(address), applying: {
                self.session.makeCopyOverriding(shippingAddress: contactAddress)
            })
        } else {
            try await performUpdate(applying: {
                self.session.makeCopyOverriding(shippingAddress: contactAddress)
            })
        }
    }

    // MARK: - Server Updates

    /// Runs an async function that calls your server to update the Checkout Session,
    /// then automatically refreshes ``session`` with the latest session data.
    ///
    /// A 20-second timeout is enforced. If `updateFunction` doesn't complete
    /// within 20 seconds, this method throws ``CheckoutError.timedOut``.
    ///
    /// - Parameter updateFunction: An async throwing function that makes a request
    ///   to your server to update the Checkout Session.
    /// - Throws: ``CheckoutError`` if the function times out, the session is not
    ///   open, or the refresh fails.
    public func runServerUpdate(
        _ updateFunction: @escaping () async throws -> Void
    ) async throws {
        try await enqueueSessionUpdate {
            try self.requireSheetNotPresented()
            let result = await withTimeout(Self.serverUpdateTimeout) {
                try await updateFunction()
            }
            if case .failure(let error) = result {
                if error is TimeoutError {
                    throw CheckoutError.timedOut
                }
                throw CheckoutError.apiError(message: error.localizedDescription)
            }
            let sessionId = Self.extractSessionId(from: self.clientSecret)
            let refreshedCheckoutSession: STPCheckoutSessionAPIResponse
            do {
                refreshedCheckoutSession = try await self.apiClient.initCheckoutSession(
                    checkoutSessionId: sessionId,
                    adaptivePricingAllowed: self.configuration.adaptivePricing.allowed
                )
            } catch {
                throw CheckoutError.apiError(message: error.nonGenericDescription)
            }
            try await self.commitSession(refreshedCheckoutSession)
        }
    }

    // MARK: - State updates

    /// Replaces the current session from an API response, preserves client-side overrides, and notifies delegates.
    ///
    /// Client-side address overrides are copied from the current session to the new one
    /// automatically. To update an address, pass a `localMutation` closure.
    func commitSession(
        _ apiResponse: STPCheckoutSessionAPIResponse? = nil,
        applying localMutation: (@MainActor @Sendable () -> Session)? = nil,
        skipIntegrationNotification: Bool = false
    ) async throws {
        // Generate a new session from the API response, or fall back to the current session.
        let newSession = apiResponse?.makePublicSession() ?? session

        // Preserve client-side address overrides on the new session.
        let sessionWithLocalAddress = newSession.makeCopyOverriding(
            billingAddress: session.billingAddress,
            shippingAddress: session.shippingAddress
        )

        // Apply any additional local mutations to the session.
        let finalSession = localMutation?() ?? sessionWithLocalAddress

        // Update the session and notify delegates.
        session = finalSession

        // Skip delegate if another op is queued—it'll notify when it commits.
        if isLastPendingOperation && !skipIntegrationNotification {
            try await integrationDelegate?.checkoutDidUpdate(self)
        }
    }
}
