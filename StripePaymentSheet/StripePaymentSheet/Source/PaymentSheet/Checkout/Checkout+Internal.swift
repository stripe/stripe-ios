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
    /// `body` can be of any return type, including `Void`, and  `enqueueSessionUpdate`
    /// will return that value to the caller.
    ///
    /// Operations execute in strict FIFO order: each task waits for the previous
    /// task before running its body. While the queue is non-empty, ``isLoading``
    /// is `true`; once the queue drains it returns to `false.`
    /// - Throws: Any error thrown by `body`.
    /// - Returns: The value returned by `body`.
    internal func enqueueSessionUpdate<T>(
        _ body: @MainActor @escaping () async throws -> T
    ) async throws -> T {
        let predecessor = pendingOperations.last

        // The typed task does the actual work, preserving the return type T.
        let typedOperation = Task<T, Error> { @MainActor in
            // Wait for the previous operation, if one exists, to finish.
            // Use `try?` so that we still continue even if the predecessor throws an error.
            if let predecessor { _ = try? await predecessor.value }
            return try await body()
        }

        // The erased task discards T so it can be stored in the homogeneous
        // pendingOperations array. It forwards completion/errors so downstream
        // predecessors still serialize correctly.
        let erasedOperation = Task<Void, Error> { _ = try await typedOperation.value }
        pendingOperations.append(erasedOperation)

        defer {
            pendingOperations.removeAll { $0 == erasedOperation }
        }

        return try await typedOperation.value
    }

    /// Non-throwing variant of ``enqueueSessionUpdate(_:)-throws``.
    ///
    /// Use this when the enqueued work cannot fail. The operation is still
    /// serialized behind any in-flight ops in the same FIFO order.
    internal func enqueueSessionUpdate<T>(
        _ body: @MainActor @escaping () async -> T
    ) async -> T {
        // Cast body to `throws` so that we call the underlying throwing version
        // instead of recursing. The try! is safe because body cannot throw.
        // swiftlint:disable:next force_try
        return try! await enqueueSessionUpdate(body as (() async throws -> T))
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
    ///   - localMutation: A local change to the session to apply after the API call (or on its own).
    func performUpdate(
        _ update: SessionUpdate? = nil,
        applying localMutation: (@MainActor @Sendable (Session) -> Session)? = nil
    ) async throws {
        try await enqueueSessionUpdate {
            try self.requireSheetNotPresented()

            do {
                let updatedSessionAPIResponse: STPCheckoutSessionAPIResponse?
                if let update {
                    let sessionId = Checkout.extractSessionId(from: self.clientSecret)
                    updatedSessionAPIResponse = try await self.apiClient.updateCheckoutSession(
                        checkoutSessionId: sessionId,
                        parameters: update.parameters
                    )
                } else {
                    updatedSessionAPIResponse = nil
                }

                // Errors from here should still get wrapped in API errors since the only way
                //  the integration delegate throws is if the API returned a session state that
                //  the UI can't handle.
                try await self.commitSession(updatedSessionAPIResponse, applying: localMutation)
            } catch {
                // If a prior op skipped the delegate and we're failing before we
                // get to commitSession ourselves, still notify so the UI updates.
                if self.isLastPendingOperation {
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
