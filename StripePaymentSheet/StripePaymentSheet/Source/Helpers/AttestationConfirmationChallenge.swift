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
        STPAnalyticsClient.sharedClient.logAttestationConfirmationInit()
        let startTime = Date()
        Task { // Intentionally not blocking loading/initialization!
            let didAttest = await stripeAttest.prepareAttestation()
            if didAttest {
                STPAnalyticsClient.sharedClient.logAttestationConfirmationInitSucceeded(duration: Date().timeIntervalSince(startTime))
            } else {
                STPAnalyticsClient.sharedClient.logAttestationConfirmationInitFailed(duration: Date().timeIntervalSince(startTime))
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
    func logAttestationConfirmationInit() {
        log(
            analytic: GenericAnalytic(event: .attestationConfirmationInit, params: [:])
        )
    }

    func logAttestationConfirmationInitSucceeded(duration: TimeInterval) {
        log(
            analytic: GenericAnalytic(event: .attestationConfirmationInitSucceeded, params: ["duration": duration * 1000])
        )
    }

    func logAttestationConfirmationInitFailed(duration: TimeInterval) {
        log(
            analytic: GenericAnalytic(event: .attestationConfirmationInitFailed, params: ["duration": duration * 1000])
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

    func logAttestationConfirmationAttach() {
        log(
            analytic: GenericAnalytic(event: .attestationConfirmationAttach, params: [:])
        )
    }
}
