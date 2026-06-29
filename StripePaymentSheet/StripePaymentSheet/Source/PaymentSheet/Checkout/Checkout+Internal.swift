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
        try await performUpdate(.setCurrency(currency))
    }

    // MARK: - Session Updates

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

        defer {
            pendingOperations.removeAll { $0 == operation }
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
    ///   - localMutation: A local state change to apply prior to the API call (or on its own).
    func performUpdate(
        _ update: SessionUpdate? = nil,
        skipSheetPresentedCheck: Bool = false,
        notifyIntegrationDelegate: Bool = true,
        applying localMutation: (@MainActor @Sendable () -> Void)? = nil
    ) async throws {
        try await enqueueSessionUpdate {
            if !skipSheetPresentedCheck {
                try self.requireSheetNotPresented()
            }
            // Transition to loading before the async work begins so observers show a loading state.
            self.state = .loading(self.state.session)

            do {
                let updatedSession: STPCheckoutSession
                if let update {
                    let sessionId = Checkout.extractSessionId(from: self.clientSecret)
                    updatedSession = try await self.apiClient.updateCheckoutSession(
                        checkoutSessionId: sessionId,
                        parameters: update.parameters
                    )
                } else {
                    guard let session = self.stpSession else { return }
                    updatedSession = session
                }

                localMutation?()
                try await self.commitSession(updatedSession, notifyIntegrationDelegate: notifyIntegrationDelegate)
            } catch {
                // Restore loaded state on failure so the UI doesn't stay stuck in loading.
                self.state = .loaded(self.state.session)
                // If a prior op skipped the delegate and we're failing before we
                // get to commitSession ourselves, still notify so the UI updates.
                if self.isLastPendingOperation && notifyIntegrationDelegate {
                    try? await self.integrationDelegate?.checkoutDidUpdate(self)
                }
                throw CheckoutError.apiError(message: error.nonGenericDescription)
            }
        }
    }

    // MARK: - Validation

    func requireSheetNotPresented() throws {
        guard integrationDelegate?.isSheetPresented != true else {
            throw CheckoutError.sheetCurrentlyPresented
        }
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
