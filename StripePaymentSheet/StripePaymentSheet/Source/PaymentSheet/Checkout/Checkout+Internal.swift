//
//  Checkout+Internal.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 5/5/26.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

extension Checkout {

    // MARK: - Currency

    /// Selects a currency for the session (adaptive pricing).
    /// - Parameter currency: The three-letter ISO currency code to switch to (e.g. "gbp").
    /// - Throws: ``CheckoutError`` if the update fails.
    func selectCurrency(_ currency: String) async throws {
        try requireOpenSessionForInSheetUpdate()
        try await enqueueSessionUpdate {
            try await self.performAPIUpdate(.setCurrency(currency))
        }
    }

    // MARK: - Session Updates

    /// Replaces the current session, preserves client-side overrides, and notifies the delegate.
    ///
    /// - Parameter applyOverrides: Called with the new session after existing overrides are
    ///   preserved but before state is published. Use this to set client-side properties
    ///   (e.g. address overrides) that should be visible to the delegate and observers.
    func updateSession(_ newSession: STPCheckoutSession, applyOverrides: ((STPCheckoutSession) -> Void)? = nil) {
        // Preserve client-side address overrides on the new session.
        newSession.billingAddress = stpSession?.billingAddress
        newSession.shippingAddress = stpSession?.shippingAddress
        applyOverrides?(newSession)
        newSession.onConfirmed = { [weak self] response in
            self?.updateSession(response)
        }
        let changed = stpSession?.allResponseFields as NSDictionary? != newSession.allResponseFields as NSDictionary
        setSession(newSession)
        if changed {
            delegate?.checkout(self, didChangeState: state)
        }
    }

    /// Runs `body` as a tracked session update, serialized behind any in-flight ops.
    ///
    /// Operations execute in strict FIFO order: each task waits for the previous
    /// task before running its body. While the queue is non-empty, ``state`` is
    /// `.loading`; once the queue drains it returns to `.loaded`.
    internal func enqueueSessionUpdate(
        _ body: @MainActor @escaping () async throws -> Void
    ) async throws {
        let predecessor = pendingOperations.last
        let operation = Task<Void, Error> { @MainActor in
            // Keep later ops moving even if an earlier queued op failed.
            if let predecessor { _ = try? await predecessor.value }
            try await body()
        }

        pendingOperations.append(operation)
        if let session = stpSession { setSession(session) }

        defer {
            pendingOperations.removeAll { $0 == operation }
            if let session = stpSession { setSession(session) }
        }
        try await operation.value
    }

    /// Sends a mutation to the Stripe API and updates the session from the response.
    ///
    /// - Parameter applyOverrides: Forwarded to ``updateSession(_:applyOverrides:)``.
    ///   Runs only after a successful API call — use this to set client-side overrides
    ///   on the updated session so local state stays in sync with the backend.
    func performAPIUpdate(
        _ update: SessionUpdate,
        applyOverrides: ((STPCheckoutSession) -> Void)? = nil
    ) async throws {
        do {
            let sessionId = Self.extractSessionId(from: clientSecret)
            let updatedSession = try await apiClient.updateCheckoutSession(
                checkoutSessionId: sessionId,
                parameters: update.parameters
            )
            updateSession(updatedSession, applyOverrides: applyOverrides)
        } catch {
            throw CheckoutError.apiError(message: error.nonGenericDescription)
        }
    }

    /// Fetches the latest Checkout Session from Stripe and publishes it to observers.
    func refreshSession(
        applyOverrides: ((STPCheckoutSession) -> Void)? = nil
    ) async throws {
        do {
            let sessionId = Self.extractSessionId(from: clientSecret)
            let refreshedCheckoutSession = try await apiClient.initCheckoutSession(
                checkoutSessionId: sessionId,
                adaptivePricingAllowed: configuration.adaptivePricing.allowed
            )
            updateSession(refreshedCheckoutSession, applyOverrides: applyOverrides)
        } catch {
            throw CheckoutError.apiError(message: error.nonGenericDescription)
        }
    }

    // MARK: - Validation

    /// Validates that the session is open (but allows the sheet to be presented).
    /// Used by mutations triggered from inside the presented sheet (e.g. currency selection).
    @discardableResult
    func requireOpenSessionForInSheetUpdate() throws -> STPCheckoutSession {
        guard let currentSession = stpSession else {
            stpAssertionFailure("Expected STPCheckoutSession, got \(type(of: state.session))")
            throw CheckoutError.apiError(message: "Unexpected session type: expected STPCheckoutSession")
        }
        guard currentSession.status?.type == .open else {
            throw CheckoutError.sessionNotOpen
        }
        return currentSession
    }

    /// Validates that the session is open and no sheet is presented.
    @discardableResult
    func requireOpenSession() throws -> STPCheckoutSession {
        guard let currentSession = stpSession else {
            stpAssertionFailure("Expected STPCheckoutSession, got \(type(of: state.session))")
            throw CheckoutError.apiError(message: "Unexpected session type: expected STPCheckoutSession")
        }
        guard currentSession.status?.type == .open else {
            throw CheckoutError.sessionNotOpen
        }
        guard integrationDelegate?.isSheetPresented != true else {
            throw CheckoutError.sheetCurrentlyPresented
        }
        return currentSession
    }

    // MARK: - Client Secrets

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
