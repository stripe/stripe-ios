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
        try await performUpdate(.setCurrency(currency))
    }

    // MARK: - Session Updates

    /// Replaces the current session, preserves client-side overrides, and notifies delegates.
    ///
    /// Client-side address overrides are copied from the current session to `newSession`
    /// automatically. To update an address, set it on `stpSession` before calling this method.
    func updateSession(_ newSession: STPCheckoutSession) async throws {
        // Preserve client-side address overrides on the new session.
        newSession.billingAddress = stpSession?.billingAddress
        newSession.shippingAddress = stpSession?.shippingAddress
        setSession(newSession)
        try await integrationDelegate?.checkoutDidUpdate(self)
        delegate?.checkout(self, didChangeState: state)
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

    /// Enqueues a serialized session update.
    ///
    /// - If `update` is non-nil, the side effect (if any) is applied first, then the
    ///   API mutation is performed and the session is updated from the response.
    /// - If `update` is nil, the side effect is applied locally and delegates are
    ///   notified without making a network request.
    ///
    /// - Parameters:
    ///   - update: The API mutation to perform, or nil for a local-only update.
    ///   - localMutation: A local state change to apply before the API call (or on its own).
    func performUpdate(
        _ update: SessionUpdate? = nil,
        applying localMutation: (@MainActor @Sendable () -> Void)? = nil
    ) async throws {
        try await enqueueSessionUpdate {
            localMutation?()
            if let update {
                let sessionId = Self.extractSessionId(from: self.clientSecret)
                let updatedSession: STPCheckoutSession
                do {
                    updatedSession = try await self.apiClient.updateCheckoutSession(
                        checkoutSessionId: sessionId,
                        parameters: update.parameters
                    )
                } catch {
                    throw CheckoutError.apiError(message: error.nonGenericDescription)
                }
                try await self.updateSession(updatedSession)
            } else {
                guard let session = self.stpSession else { return }
                try await self.updateSession(session)
            }
        }
    }

    /// Fetches the latest Checkout Session from Stripe and publishes it to observers.
    func refreshSession() async throws {
        let sessionId = Self.extractSessionId(from: clientSecret)
        let refreshedCheckoutSession: STPCheckoutSession
        do {
            refreshedCheckoutSession = try await apiClient.initCheckoutSession(
                checkoutSessionId: sessionId,
                adaptivePricingAllowed: configuration.adaptivePricing.allowed
            )
        } catch {
            throw CheckoutError.apiError(message: error.nonGenericDescription)
        }
        try await updateSession(refreshedCheckoutSession)
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
