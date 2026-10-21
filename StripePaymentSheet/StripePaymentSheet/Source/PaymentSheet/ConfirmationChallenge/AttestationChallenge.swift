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
    private var assertionTask: Task<StripeAttest.Assertion?, Never>?

    public init(stripeAttest: StripeAttest, canSyncState: Bool = false) {
        self.stripeAttest = stripeAttest
        self.canSyncState = canSyncState
        STPAnalyticsClient.sharedClient.logAttestationConfirmationPrepare()
        let startTime = Date()
        Task { // Intentionally not blocking loading/initialization!
            let didAttest = await withTaskCancellationHandler {
                await stripeAttest.prepareAttestation()
            } onCancel: {
                Task {
                    await stripeAttest.cancel()
                }
            }
            if didAttest {
                STPAnalyticsClient.sharedClient.logAttestationConfirmationPrepareSucceeded(duration: Date().timeIntervalSince(startTime))
            } else {
                STPAnalyticsClient.sharedClient.logAttestationConfirmationPrepareFailed(duration: Date().timeIntervalSince(startTime))
            }
        }
    }

    public func fetchAssertion() async -> StripeAttest.Assertion? {
        if let assertionTask {
            return await withTaskCancellationHandler {
                return await assertionTask.value
            } onCancel: {
                assertionTask.cancel()
            }
        }
        let assertionTask = Task<StripeAttest.Assertion?, Never> {
            STPAnalyticsClient.sharedClient.logAttestationConfirmationRequestToken()
            let startTime = Date()
            do {
                let assertionHandle = try await stripeAttest.assert(canSyncState: canSyncState)
                if Task.isCancelled {
                    // Release assertions that arrive after cancellation or completion.
                    await assertionHandle.complete()
                    return nil
                }
                STPAnalyticsClient.sharedClient.logAttestationConfirmationRequestTokenSucceeded(duration: Date().timeIntervalSince(startTime))
                self.assertionHandle = assertionHandle
                return assertionHandle.assertion
            } catch {
                if Task.isCancelled { return nil }
                STPAnalyticsClient.sharedClient.logAttestationConfirmationRequestTokenFailed(duration: Date().timeIntervalSince(startTime))
            }
            return nil
        }
        self.assertionTask = assertionTask
        return await withTaskCancellationHandler {
            return await assertionTask.value
        } onCancel: {
            assertionTask.cancel()
        }
    }

    // Must be called after signing request
    public func complete() async {
        let handle = assertionHandle
        assertionHandle = nil
        // A pending canceled fetch releases its own handle when it finishes.
        assertionTask?.cancel()
        assertionTask = nil
        await handle?.complete()
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
