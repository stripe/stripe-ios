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

    // MARK: - Payment Option

    func setPaymentOption(_ paymentOption: Session.PaymentOptionDisplayData?) {
        dangerouslySetSessionDirectly(session.makeCopyOverriding(paymentOption: .newValue(paymentOption)))
    }

    // MARK: - Session Updates

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
    func enqueueSessionUpdate<T>(
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
    func enqueueSessionUpdate<T>(
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
    ///   - canUpdateWhileSheetPresented: Bypasses the sheet-presented guard (e.g. billing sync on dismiss).
    func performUpdate(
        _ update: SessionUpdate? = nil,
        applying localMutation: (@MainActor @Sendable (Session) -> Session)? = nil,
        canUpdateWhileSheetPresented: Bool = false
    ) async throws {
        try await enqueueSessionUpdate {
            if !canUpdateWhileSheetPresented {
                try self.requireSheetNotPresented()
            }
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
                throw CheckoutError.apiError(message: error.nonGenericDescription)
            }
        }
    }

    /// True if the session is still actionable (open or no status yet).
    var sessionIsOpen: Bool {
        session.status?.type == .open || session.status?.type == nil
    }

    // MARK: - Validation

    func requireSheetNotPresented() throws {
        guard paymentElement?.isPresentingPaymentUI != true else {
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
