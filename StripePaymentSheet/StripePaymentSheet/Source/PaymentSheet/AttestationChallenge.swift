//
//  AttestationChallenge.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 10/24/25.
//

import Foundation
@_spi(STP) import StripeCore

actor AttestationChallenge {
    enum AttestationError: Error {
        case timeout
    }

    private let stripeAttest: StripeAttest
    private let canSyncState: Bool
    private var assertionHandle: StripeAttest.AssertionHandle?
    private let attestationTask: Task<Void, Error>
    private var assertionTask: Task<StripeAttest.Assertion?, Never>?

    var timeout: TimeInterval = STPAnalyticsClient.isUnitOrUITest ? 0 : 6 // same as web

    func setTimeout(timeout: TimeInterval) {
        self.timeout = timeout
    }

    public init(stripeAttest: StripeAttest, canSyncState: Bool) {
        self.stripeAttest = stripeAttest
        self.canSyncState = canSyncState
        STPAnalyticsClient.sharedClient.logAttestationConfirmationPrepare()
        let startTime = Date()
        self.attestationTask = Task { // Intentionally not blocking loading/initialization!
            try await withTaskCancellationHandler {
                try Task.checkCancellation()
                let didAttest = await stripeAttest.prepareAttestation()
                if didAttest {
                    STPAnalyticsClient.sharedClient.logAttestationConfirmationPrepareSucceeded(duration: Date().timeIntervalSince(startTime))
                } else {
                    STPAnalyticsClient.sharedClient.logAttestationConfirmationPrepareFailed(duration: Date().timeIntervalSince(startTime))
                }
                try Task.checkCancellation()
            } onCancel: {
                Task {
                    await stripeAttest.cancel()
                }
            }
        }
    }

    private func fetchAssertion() async -> StripeAttest.Assertion? {
        if let assertionTask {
            return await assertionTask.value
        }
        let assertionTask = Task<StripeAttest.Assertion?, Never> {
            // Wait for prewarm to complete first to avoid race conditions
            do {
                try await attestationTask.value
            } catch {
                return nil
            }
            STPAnalyticsClient.sharedClient.logAttestationConfirmationRequestToken()
            let startTime = Date()
            do {
                assertionHandle = try await withTaskCancellationHandler {
                    try await stripeAttest.assert(canSyncState: canSyncState)
                } onCancel: {
                    Task {
                        await stripeAttest.cancel()
                    }
                }
                STPAnalyticsClient.sharedClient.logAttestationConfirmationRequestTokenSucceeded(duration: Date().timeIntervalSince(startTime))
            } catch {
                assertionHandle = nil
                STPAnalyticsClient.sharedClient.logAttestationConfirmationRequestTokenFailed(duration: Date().timeIntervalSince(startTime))
            }
            return assertionHandle?.assertion
        }
        self.assertionTask = assertionTask
        return await assertionTask.value
    }

    public func fetchAssertionWithTimeout() async -> StripeAttest.Assertion? {
        let timeoutNs = UInt64(timeout) * 1_000_000_000
        return await withTaskGroup(of: StripeAttest.Assertion?.self) { group in
            // Add assertion task
            group.addTask {
                return await self.fetchAssertion()
            }
            // Add timeout task
            group.addTask {
                try? await Task.sleep(nanoseconds: timeoutNs)
                return nil
            }
            defer {
                // ⚠️ TaskGroups can't return until all child tasks have completed, so we need to cancel remaining tasks and handle cancellation to complete as quickly as possible
                cancel()
                group.cancelAll()
            }
            // Wait for first completion
            return await group.next()?.flatMap { $0 }
        }
    }

    // Must be called after signing request
    public func complete() {
        assertionHandle?.complete()
    }

    public func cancel() {
        attestationTask.cancel()
        assertionTask?.cancel()
    }
}

// All duration analytics are in milliseconds
extension STPAnalyticsClient {
    func logAttestationConfirmationPrepare() {
        log(
            analytic: GenericAnalytic(event: .attestationConfirmationPrepare, params: [:])
        )
    }

    func logAttestationConfirmationPrepareSucceeded(duration: TimeInterval) {
        log(
            analytic: GenericAnalytic(event: .attestationConfirmationPrepareSucceeded, params: ["duration": duration * 1000])
        )
    }

    func logAttestationConfirmationPrepareFailed(duration: TimeInterval) {
        log(
            analytic: GenericAnalytic(event: .attestationConfirmationPrepareFailed, params: ["duration": duration * 1000])
        )
    }

    func logAttestationConfirmationRequestToken() {
        log(
            analytic: GenericAnalytic(event: .attestationConfirmationRequestToken, params: [:])
        )
    }

    func logAttestationConfirmationRequestTokenSucceeded(duration: TimeInterval) {
        log(
            analytic: GenericAnalytic(event: .attestationConfirmationRequestTokenSucceeded, params: ["duration": duration * 1000])
        )
    }

    func logAttestationConfirmationRequestTokenFailed(duration: TimeInterval) {
        log(
            analytic: GenericAnalytic(event: .attestationConfirmationRequestTokenFailed, params: ["duration": duration * 1000])
        )
    }
}
