//
//  AttestationConfirmationChallenge.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 10/24/25.
//

import Foundation
@_spi(STP) import StripeCore

actor AttestationConfirmationChallenge {
    private let stripeAttest: StripeAttest
    private var assertionHandle: StripeAttest.AssertionHandle?
    private var assertionTask: Task<StripeAttest.Assertion?, Never>?

    public init(stripeAttest: StripeAttest) {
        self.stripeAttest = stripeAttest
        STPAnalyticsClient.sharedClient.logAttestationConfirmationPrepare()
        let startTime = Date()
        Task { // Intentionally not blocking loading/initialization!
            let didAttest = await stripeAttest.prepareAttestation()
            if didAttest {
                STPAnalyticsClient.sharedClient.logAttestationConfirmationPrepareSucceeded(duration: Date().timeIntervalSince(startTime))
            } else {
                STPAnalyticsClient.sharedClient.logAttestationConfirmationPrepareFailed(duration: Date().timeIntervalSince(startTime))
            }
        }
    }

    public func fetchAssertion() async -> StripeAttest.Assertion? {
        if let assertionTask {
            return await assertionTask.value
        }
        let assertionTask = Task<StripeAttest.Assertion?, Never> {
            STPAnalyticsClient.sharedClient.logAttestationConfirmationRequestToken()
            let startTime = Date()
            do {
                assertionHandle = try await withTaskCancellationHandler {
                    try await stripeAttest.assert(canSyncState: false)
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

    public func complete() {
        assertionHandle?.complete()
    }

    public func cancel() {
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

    func logAttestationConfirmationError(error: Error, duration: TimeInterval) {
        log(
            analytic: ErrorAnalytic(event: .attestationConfirmationError, error: error, additionalNonPIIParams: ["duration": duration * 1000])
        )
    }
}
