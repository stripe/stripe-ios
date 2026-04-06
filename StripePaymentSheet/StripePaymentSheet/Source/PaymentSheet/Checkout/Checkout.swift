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
/// so ``state`` is guaranteed to be ``State/loaded(_:)`` immediately after initialization.
///
/// Observe session changes with SwiftUI by using ``state`` (published via `ObservableObject`),
/// or in UIKit by setting a ``delegate``.
@_spi(CheckoutSessionsPreview)
@MainActor
public final class Checkout: ObservableObject {
    // MARK: - Public Properties

    /// The current state of the checkout session.
    ///
    /// After initialization this is always ``State/loaded(_:)``. It transitions to
    /// ``State/loading(_:)`` while a mutation (e.g. applying a promo code) is in flight.
    @Published public private(set) var state: State

    /// A delegate notified when the session state changes.
    public weak var delegate: CheckoutDelegate?

    // MARK: - Private Properties

    /// Concrete accessor for internal use where `STPCheckoutSession`-specific
    /// properties (e.g. `allResponseFields`, `billingAddressOverride`) are needed.
    private var stpSession: STPCheckoutSession? {
        state.session as? STPCheckoutSession
    }

    weak var integrationDelegate: CheckoutIntegrationDelegate?

    private let clientSecret: String
    private let apiClient: STPAPIClient

    /// Number of session-mutating API calls currently in flight.
    private var sessionUpdateCount = 0

    // MARK: - Initialization

    /// Loads a Checkout Session from Stripe and returns a ready-to-use instance.
    ///
    /// - Parameters:
    ///   - clientSecret: The client secret for your Checkout Session (e.g. `cs_xxx_secret_yyy`).
    ///   - apiClient: The API client to use. Defaults to ``STPAPIClient.shared``.
    /// - Throws: ``CheckoutError`` if the client secret is invalid or the session cannot be loaded.
    public init(clientSecret: String, apiClient: STPAPIClient = .shared) async throws {
        guard !clientSecret.isEmpty else {
            throw CheckoutError.invalidClientSecret
        }
        self.clientSecret = clientSecret
        self.apiClient = apiClient

        let sessionId = Self.extractSessionId(from: clientSecret)
        do {
            let checkoutSession = try await apiClient.initCheckoutSession(checkoutSessionId: sessionId)
            self.state = .loaded(checkoutSession)
            checkoutSession.onConfirmed = { [weak self] response in
                self?.updateSession(response)
            }
        } catch {
            throw CheckoutError.apiError(message: error.nonGenericDescription)
        }
    }

    /// Internal initializer for unit tests that injects a pre-loaded session.
    init(clientSecret: String, session: STPCheckoutSession, apiClient: STPAPIClient = .shared) {
        self.clientSecret = clientSecret
        self.apiClient = apiClient
        self.state = .loaded(session)
        session.onConfirmed = { [weak self] response in
            self?.updateSession(response)
        }
    }

    // MARK: - Promotion Codes

    /// Applies a promotion code to the session.
    /// - Parameter code: The promotion code to apply.
    /// - Throws: ``CheckoutError`` if applying the promotion code fails.
    public func applyPromotionCode(_ code: String) async throws {
        try requireOpenSession()
        try await withSessionUpdateGuard {
            try await performAPIUpdate(.setPromotionCode(code))
        }
    }

    /// Removes the currently applied promotion code.
    /// - Throws: ``CheckoutError`` if removing the promotion code fails.
    public func removePromotionCode() async throws {
        try requireOpenSession()
        try await withSessionUpdateGuard {
            try await performAPIUpdate(.setPromotionCode(""))
        }
    }

    // MARK: - Line Items

    /// Updates the quantity of a line item.
    /// - Parameter params: The line item ID and new quantity to set.
    /// - Throws: ``CheckoutError`` if the update fails.
    public func updateQuantity(with params: LineItemUpdate) async throws {
        try requireOpenSession()
        try await withSessionUpdateGuard {
            try await performAPIUpdate(.setLineItemQuantity(lineItemId: params.lineItemId, quantity: params.quantity))
        }
    }

    // MARK: - Shipping

    /// Selects a shipping option for the session.
    /// - Parameter optionId: The ID of the shipping rate to select.
    /// - Throws: ``CheckoutError`` if the update fails.
    public func selectShippingOption(_ optionId: String) async throws {
        try requireOpenSession()
        try await withSessionUpdateGuard {
            try await performAPIUpdate(.setShippingRate(optionId))
        }
    }

    // MARK: - Addresses

    /// Sets the billing address for this checkout.
    ///
    /// The address is stored locally and merged into PaymentSheet configuration
    /// when presenting payment UI. If automatic tax is enabled and the tax
    /// address source is "billing", the address is also sent to the server to
    /// compute updated tax amounts.
    ///
    /// - Parameter params: The billing address to set. To reset tax computation
    ///   to a country-only region, pass an ``AddressUpdate`` with just the country.
    /// - Throws: ``CheckoutError`` if the session is not open, or if
    ///   the server request fails.
    public func updateBillingAddress(_ params: AddressUpdate) async throws {
        let currentSession = try requireOpenSession()
        if currentSession.shouldSendTaxRegion(for: "billing") {
            try await withSessionUpdateGuard {
                try await performAPIUpdate(.setTaxRegion(params.address), applyOverrides: { session in
                    // Set the local address override on the refreshed session after a successful API call.
                    session.billingAddressOverride = params
                })
            }
        } else {
            guard currentSession.billingAddressOverride != params else { return }
            currentSession.billingAddressOverride = params
            state = .loaded(currentSession)
            delegate?.checkout(self, didChangeState: state)
        }
    }

    /// Sets the shipping address for this checkout.
    ///
    /// The address is stored locally and merged into PaymentSheet configuration
    /// when presenting payment UI. If automatic tax is enabled and the tax
    /// address source is "shipping", the address is also sent to the server to
    /// compute updated tax amounts.
    ///
    /// - Parameter params: The shipping address to set. To reset tax computation
    ///   to a country-only region, pass an ``AddressUpdate`` with just the country.
    /// - Throws: ``CheckoutError`` if the session is not open, or if
    ///   the server request fails.
    public func updateShippingAddress(_ params: AddressUpdate) async throws {
        let currentSession = try requireOpenSession()
        if currentSession.shouldSendTaxRegion(for: "shipping") {
            try await withSessionUpdateGuard {
                try await performAPIUpdate(.setTaxRegion(params.address), applyOverrides: { session in
                    // Set the local address override on the refreshed session after a successful API call.
                    session.shippingAddressOverride = params
                })
            }
        } else {
            guard currentSession.shippingAddressOverride != params else { return }
            currentSession.shippingAddressOverride = params
            state = .loaded(currentSession)
            delegate?.checkout(self, didChangeState: state)
        }
    }

    // MARK: - Currency

    /// Selects a currency for the session (adaptive pricing).
    /// - Parameter currency: The three-letter ISO currency code to switch to (e.g. "gbp").
    /// - Throws: ``CheckoutError`` if the update fails.
    func selectCurrency(_ currency: String) async throws {
        try requireOpenSessionForInSheetUpdate()
        try await withSessionUpdateGuard {
            try await performAPIUpdate(.setCurrency(currency))
        }
    }

    // MARK: - Tax ID

    /// Sets the customer's tax ID on the session.
    /// - Parameter params: The tax ID type and value to set.
    /// - Throws: ``CheckoutError`` if the update fails.
    public func updateTaxId(with params: TaxIdUpdate) async throws {
        try requireOpenSession()
        try await withSessionUpdateGuard {
            try await performAPIUpdate(.setTaxId(type: params.type, value: params.value))
        }
    }

    // MARK: - Internal Methods

    /// Replaces the current session, preserves client-side overrides, and notifies the delegate.
    ///
    /// - Parameter applyOverrides: Called with the new session after existing overrides are
    ///   preserved but before state is published. Use this to set client-side properties
    ///   (e.g. address overrides) that should be visible to the delegate and observers.
    func updateSession(_ newSession: STPCheckoutSession, applyOverrides: ((STPCheckoutSession) -> Void)? = nil) {
        // Preserve client-side address overrides on the new session.
        newSession.billingAddressOverride = stpSession?.billingAddressOverride
        newSession.shippingAddressOverride = stpSession?.shippingAddressOverride
        applyOverrides?(newSession)
        newSession.onConfirmed = { [weak self] response in
            self?.updateSession(response)
        }
        let changed = stpSession?.allResponseFields as NSDictionary? != newSession.allResponseFields as NSDictionary
        state = .loaded(newSession)
        if changed {
            delegate?.checkout(self, didChangeState: state)
        }
    }

    // MARK: - Private Methods

    /// Tracks that a session update is in progress for the duration of `body`.
    /// Transitions state to `.loading` while the body executes.
    /// Uses a counter so overlapping calls don't clear the flag early.
    /// Note: an actor wouldn't help — actors are reentrant at suspension points,
    /// so the same interleaving would occur.
    private func withSessionUpdateGuard<T>(_ body: () async throws -> T) async rethrows -> T {
        sessionUpdateCount += 1
        state = .loading(state.session)
        defer {
            sessionUpdateCount -= 1
            if sessionUpdateCount == 0, case .loading(let session) = state {
                state = .loaded(session)
            }
        }
        return try await body()
    }

    /// Validates that the session is open (but allows the sheet to be presented).
    /// Used by mutations triggered from inside the presented sheet (e.g. currency selection).
    @discardableResult
    private func requireOpenSessionForInSheetUpdate() throws -> STPCheckoutSession {
        guard let currentSession = stpSession else {
            stpAssertionFailure("Expected STPCheckoutSession, got \(type(of: state.session))")
            throw CheckoutError.apiError(message: "Unexpected session type: expected STPCheckoutSession")
        }
        guard currentSession.status == .open else {
            throw CheckoutError.sessionNotOpen
        }
        return currentSession
    }

    /// Validates that the session is open and no sheet is presented.
    @discardableResult
    private func requireOpenSession() throws -> STPCheckoutSession {
        guard let currentSession = stpSession else {
            stpAssertionFailure("Expected STPCheckoutSession, got \(type(of: state.session))")
            throw CheckoutError.apiError(message: "Unexpected session type: expected STPCheckoutSession")
        }
        guard currentSession.status == .open else {
            throw CheckoutError.sessionNotOpen
        }
        guard integrationDelegate?.isSheetPresented != true else {
            throw CheckoutError.sheetCurrentlyPresented
        }
        return currentSession
    }

    /// Sends a mutation to the Stripe API and refreshes the session.
    ///
    /// The update endpoint returns partial data, so we always re-fetch the full session
    /// afterward to keep ``state`` as the single source of truth.
    ///
    /// - Parameter applyOverrides: Forwarded to ``updateSession(_:applyOverrides:)``.
    ///   Runs only after a successful API call — use this to set client-side overrides
    ///   on the refreshed session so local state stays in sync with the backend.
    private func performAPIUpdate(
        _ update: SessionUpdate,
        applyOverrides: ((STPCheckoutSession) -> Void)? = nil
    ) async throws {
        do {
            let sessionId = Self.extractSessionId(from: clientSecret)
            _ = try await apiClient.updateCheckoutSession(
                checkoutSessionId: sessionId,
                parameters: update.parameters
            )
            let refreshedCheckoutSession = try await apiClient.initCheckoutSession(checkoutSessionId: sessionId)
            updateSession(refreshedCheckoutSession, applyOverrides: applyOverrides)
        } catch {
            throw CheckoutError.apiError(message: error.nonGenericDescription)
        }
    }

    /// Returns the session ID portion of a client secret.
    ///
    /// Client secrets use the format `cs_xxx_secret_yyy`; this method returns `cs_xxx`.
    nonisolated static func extractSessionId(from clientSecret: String) -> String {
        guard let range = clientSecret.range(of: "_secret_") else {
            return clientSecret
        }
        return String(clientSecret[..<range.lowerBound])
    }

}
