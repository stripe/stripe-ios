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
/// print(checkout.state.session)
/// ```
///
/// The async initializer loads the session from Stripe before returning,
/// so ``state`` is guaranteed to be ``State.loaded(_:)`` immediately after initialization.
///
/// Observe session changes with SwiftUI by using ``state`` (published via `ObservableObject`),
/// or in UIKit by setting a ``delegate``.
@_spi(STP)
@_spi(ReactNativeSDK)
@MainActor
public final class Checkout: ObservableObject {
    // MARK: - Public Properties

    /// The current state of the checkout session.
    ///
    /// After initialization this is always ``State.loaded(_:)``. It transitions to
    /// ``State.loading(_:)`` while a mutation is in flight.
    @Published public internal(set) var state: State

    /// The configuration supplied at initialization.
    public let configuration: Configuration

    /// A delegate notified when session data changes.
    public weak var delegate: CheckoutDelegate?

    // MARK: - Internal Properties

    /// The underlying `STPCheckoutSession` backing the current public ``state``.
    ///
    /// Marked `nonisolated(unsafe)` because PaymentSheet internals read this from non-MainActor
    /// contexts. This is safe: reads only occur after the session is loaded and while the payment
    /// UI is presented, a window during which no mutations occur. Writes are always on MainActor
    /// because they go through `Checkout`'s MainActor-isolated mutation methods.
    /// Requiring full MainActor isolation would propagate `@MainActor` through nearly all of
    /// PaymentSheet's internal types, which is not warranted by the actual concurrency risk.
    nonisolated(unsafe) private(set) var stpSession: STPCheckoutSession!

    weak var integrationDelegate: CheckoutIntegrationDelegate?

    let flagImageManager = AdaptivePricingFlagImageManager()
    let clientSecret: String
    let apiClient: STPAPIClient

    /// Serial queue of in-flight session updates. Each task waits for the previous task before running.
    var pendingOperations: [Task<Void, Error>] = []

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
            let checkoutSession = try await apiClient.initCheckoutSession(
                checkoutSessionId: sessionId,
                adaptivePricingAllowed: configuration.adaptivePricing.allowed
            )
            await flagImageManager.prefetchFlagImages(for: checkoutSession)
            self.stpSession = checkoutSession
            self.state = .loaded(checkoutSession.makePublicSession())
        } catch {
            throw CheckoutError.apiError(message: error.nonGenericDescription)
        }
    }

#if DEBUG
    /// Internal initializer for unit tests that injects a pre-loaded session.
    init(
        clientSecret: String,
        configuration: Configuration = Configuration(),
        session: STPCheckoutSession,
        apiClient: STPAPIClient = .shared
    ) async {
        self.clientSecret = clientSecret
        self.configuration = configuration
        self.apiClient = apiClient
        await flagImageManager.prefetchFlagImages(for: session)
        self.stpSession = session
        self.state = .loaded(session.makePublicSession())
    }

    /// Synchronous test-only initializer that wraps a pre-loaded session without async work.
    init(session: STPCheckoutSession) {
        self.clientSecret = ""
        self.configuration = Configuration()
        self.apiClient = .shared
        self.stpSession = session
        self.state = .loaded(session.makePublicSession())
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
        try await updateBillingAddress(name: name, phone: phone, address: address, skipSheetPresentedCheck: false)
    }

    func updateBillingAddress(
        name: String? = nil,
        phone: String? = nil,
        address: Address,
        skipSheetPresentedCheck: Bool
    ) async throws {
        guard let currentSession = stpSession else { return }
        let contactAddress = ContactAddress(name: name, phone: phone, address: address)
        guard currentSession.billingAddress != contactAddress else { return }
        let notifyDelegate = !skipSheetPresentedCheck
        if currentSession.shouldSendTaxRegion(for: "billing") {
            try await performUpdate(.setTaxRegion(address), skipSheetPresentedCheck: skipSheetPresentedCheck, notifyIntegrationDelegate: notifyDelegate, applying: {
                self.stpSession?.billingAddress = contactAddress
            })
        } else {
            try await performUpdate(skipSheetPresentedCheck: skipSheetPresentedCheck, notifyIntegrationDelegate: notifyDelegate, applying: {
                self.stpSession?.billingAddress = contactAddress
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
        guard let currentSession = stpSession else { return }
        let contactAddress = ContactAddress(name: name, phone: phone, address: address)
        guard currentSession.shippingAddress != contactAddress else { return }
        if currentSession.shouldSendTaxRegion(for: "shipping") {
            try await performUpdate(.setTaxRegion(address), applying: {
                self.stpSession?.shippingAddress = contactAddress
            })
        } else {
            try await performUpdate(applying: {
                self.stpSession?.shippingAddress = contactAddress
            })
        }
    }

    // MARK: - Server Updates

    /// Runs an async function that calls your server to update the Checkout Session,
    /// then automatically refreshes ``state`` with the latest session data.
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
            let refreshedCheckoutSession: STPCheckoutSession
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

    /// Replaces the current session, preserves client-side overrides, and notifies delegates.
    ///
    /// Client-side address overrides are copied from the current session to `newSession`
    /// automatically. To update an address, set it on `stpSession` before calling this method.
    func commitSession(_ newSession: STPCheckoutSession, notifyIntegrationDelegate: Bool = true) async throws {
        // Preserve client-side address overrides on the new session.
        newSession.billingAddress = stpSession?.billingAddress
        newSession.shippingAddress = stpSession?.shippingAddress
        stpSession = newSession
        let publicSession = newSession.makePublicSession()
        state = pendingOperations.isEmpty ? .loaded(publicSession) : .loading(publicSession)
        // Skip delegate if another op is queued—it'll notify when it commits.
        if isLastPendingOperation && notifyIntegrationDelegate {
            try await integrationDelegate?.checkoutDidUpdate(self)
        }
        delegate?.checkout(self, didChangeState: state)
    }

}
