//
//  ConfirmationChallenge.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 10/27/25.
//
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

actor ConfirmationChallenge {
    private var passiveCaptchaChallenge: PassiveCaptchaChallenge?
    private var hcaptchaToken: String?
    private var attestationConfirmationChallenge: AttestationConfirmationChallenge?
    private var assertion: StripeAttest.Assertion?

    private var timeout: TimeInterval = STPAnalyticsClient.isUnitOrUITest ? 0 : 6 // same as web

    enum Error: Swift.Error {
        case timeout
    }

    public init(enablePassiveCaptcha: Bool, elementsSession: STPElementsSession, stripeAttest: StripeAttest) {
        if enablePassiveCaptcha, let passiveCaptchaData = elementsSession.passiveCaptchaData {
           self.passiveCaptchaChallenge = PassiveCaptchaChallenge(passiveCaptchaData: passiveCaptchaData)
        }
        if elementsSession.shouldAttestOnConfirmation {
            self.attestationConfirmationChallenge = AttestationConfirmationChallenge(stripeAttest: stripeAttest)
        }
    }

    func setTimeout(timeout: TimeInterval) {
        self.timeout = timeout
    }

    public func fetchTokensWithTimeout() async -> (String?, StripeAttest.Assertion?) {
        let timeoutNs = UInt64(timeout) * 1_000_000_000
        let startTime = Date()
        let siteKey = await passiveCaptchaChallenge?.passiveCaptchaData.siteKey
        do {
            return try await withThrowingTaskGroup(of: (String?, StripeAttest.Assertion?).self) { group in
                let isReady = await passiveCaptchaChallenge?.hasFetchedToken
                // Add hcaptcha task
                group.addTask {
                    guard let passiveCaptchaChallenge = await self.passiveCaptchaChallenge else {
                        return (nil, nil)
                    }
                    return try await (passiveCaptchaChallenge.fetchToken(), nil)
                }
                // Add attestation task
                group.addTask {
                    guard let attestationConfirmationChallenge = await self.attestationConfirmationChallenge else {
                        return (nil, nil)
                    }
                    return await (nil, attestationConfirmationChallenge.fetchAssertion())
                }
                // Add timeout task
                group.addTask {
                    try await Task.sleep(nanoseconds: timeoutNs)
                    throw Error.timeout
                }
                defer {
                    // ⚠️ TaskGroups can't return until all child tasks have completed, so we need to cancel remaining tasks and handle cancellation to complete as quickly as possible
                    Task {
                        await passiveCaptchaChallenge?.tokenTask?.cancel()
                    }
                    group.cancelAll()
                }
                // Wait for first two completions
                let token1 = try await group.next()
                logAttach(result: token1, isReady: isReady, duration: Date().timeIntervalSince(startTime))
                let token2 = try await group.next()
                logAttach(result: token2, isReady: isReady, duration: Date().timeIntervalSince(startTime))
                return makeResult(token1: token1, token2: token2)
            }
        } catch {
            if hcaptchaToken == nil, let siteKey {
                STPAnalyticsClient.sharedClient.logPassiveCaptchaError(error: error, siteKey: siteKey, duration: Date().timeIntervalSince(startTime))
            }
            if assertion == nil {
                STPAnalyticsClient.sharedClient.logAttestationConfirmationError(error: error, duration: Date().timeIntervalSince(startTime))
            }
            return (hcaptchaToken, assertion)
        }
    }

    public func complete() {
        Task {
            await attestationConfirmationChallenge?.complete()
        }
    }

    func makeResult(token1: (String?, StripeAttest.Assertion?)?, token2: (String?, StripeAttest.Assertion?)?) -> (String?, StripeAttest.Assertion?) {
        return (token1?.0 ?? token2?.0, token1?.1 ?? token2?.1)
    }

    func logAttach(result: (String?, StripeAttest.Assertion?)?, isReady: Bool?, duration: TimeInterval) {
        guard let result else { return }
        if let hcaptchaToken = result.0 {
            self.hcaptchaToken = hcaptchaToken
            Task {
                let siteKey = await passiveCaptchaChallenge?.passiveCaptchaData.siteKey
                guard let siteKey, let isReady else { return }
                STPAnalyticsClient.sharedClient.logPassiveCaptchaAttach(siteKey: siteKey, isReady: isReady, duration: duration)
            }
        }
        if let assertion = result.1 {
            self.assertion = assertion
            STPAnalyticsClient.sharedClient.logAttestationConfirmationAttach()
        }
    }
}
