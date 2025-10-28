//
//  AttestationConfirmationChallenge.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 10/24/25.
//

@_spi(STP) import StripeCore

actor AttestationConfirmationChallenge {
    private let stripeAttest: StripeAttest
    private var assertionHandle: StripeAttest.AssertionHandle?

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
        STPAnalyticsClient.sharedClient.logAttestationConfirmationRequestToken()
        let startTime = Date()
        do {
            assertionHandle = try await stripeAttest.assert(canSyncState: false)
            STPAnalyticsClient.sharedClient.logAttestationConfirmationRequestTokenSucceeded(duration: Date().timeIntervalSince(startTime))
        } catch {
            assertionHandle = nil
            STPAnalyticsClient.sharedClient.logAttestationConfirmationRequestTokenFailed(duration: Date().timeIntervalSince(startTime))
        }
        return assertionHandle?.assertion
    }

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
