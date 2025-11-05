//
//  AttestationChallenge.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 10/24/25.
//

import Foundation
@_spi(STP) import StripeCore

actor AttestationChallenge {
    private let stripeAttest: StripeAttest
    private let canSyncState: Bool
    private var assertionHandle: StripeAttest.AssertionHandle?
    private let attestationTask: Task<Void, Error>
    private var assertionTask: Task<StripeAttest.Assertion?, Error>?

    public init(stripeAttest: StripeAttest, canSyncState: Bool = false) {
        self.stripeAttest = stripeAttest
        self.canSyncState = canSyncState
        STPAnalyticsClient.sharedClient.logAttestationConfirmationPrepare()
        let startTime = Date()
        self.attestationTask = Task { // Intentionally not blocking loading/initialization!
            try await withTaskCancellationHandler {
                try Task.checkCancellation()
                let didAttest = await stripeAttest.prepareAttestation()
                try Task.checkCancellation()
                if didAttest {
                    STPAnalyticsClient.sharedClient.logAttestationConfirmationPrepareSucceeded(duration: Date().timeIntervalSince(startTime))
                } else {
                    STPAnalyticsClient.sharedClient.logAttestationConfirmationPrepareFailed(duration: Date().timeIntervalSince(startTime))
                }
            } onCancel: {
                Task {
                    await stripeAttest.cancel()
                }
            }
        }
    }

    func fetchAssertion() async throws -> StripeAttest.Assertion? {
        if let assertionTask {
            return try await withTaskCancellationHandler {
                return try await assertionTask.value
            } onCancel: {
                assertionTask.cancel()
            }
        }
        let assertionTask = Task<StripeAttest.Assertion?, Error> {
            // Wait for prewarm to complete first to avoid race conditions
            do {
                try await withTaskCancellationHandler {
                    try await attestationTask.value
                } onCancel: {
                    attestationTask.cancel()
                }
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
                try Task.checkCancellation()
                STPAnalyticsClient.sharedClient.logAttestationConfirmationRequestTokenSucceeded(duration: Date().timeIntervalSince(startTime))
            } catch {
                assertionHandle = nil
                try Task.checkCancellation()
                STPAnalyticsClient.sharedClient.logAttestationConfirmationRequestTokenFailed(duration: Date().timeIntervalSince(startTime))
            }
            return assertionHandle?.assertion
        }
        self.assertionTask = assertionTask
        return try await withTaskCancellationHandler {
            return try await assertionTask.value
        } onCancel: {
            assertionTask.cancel()
        }
    }

    // Must be called after signing request
    public func complete() {
        assertionHandle?.complete()
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

    func logAttestationConfirmationError(error: Error, duration: TimeInterval) {
        log(
            analytic: ErrorAnalytic(event: .attestationConfirmationError, error: error, additionalNonPIIParams: ["duration": duration * 1000])
        )
    }
}
