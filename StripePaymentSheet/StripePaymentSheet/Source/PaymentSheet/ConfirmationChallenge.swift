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
    private var attestationConfirmationChallenge: AttestationConfirmationChallenge?
    private var challengeTokens: ChallengeTokens = (nil, nil)

    private var timeout: TimeInterval = STPAnalyticsClient.isUnitOrUITest ? 0 : 6 // same as web

    enum Error: Swift.Error {
        case timeout
    }

    typealias ChallengeTokens = (hcaptchaToken: String?, assertion: StripeAttest.Assertion?)

    public init(enablePassiveCaptcha: Bool, enableAttestation: Bool, elementsSession: STPElementsSession, stripeAttest: StripeAttest) {
        if enablePassiveCaptcha, let passiveCaptchaData = elementsSession.passiveCaptchaData {
           self.passiveCaptchaChallenge = PassiveCaptchaChallenge(passiveCaptchaData: passiveCaptchaData)
        }
        if enableAttestation, elementsSession.shouldAttestOnConfirmation {
            self.attestationConfirmationChallenge = AttestationConfirmationChallenge(stripeAttest: stripeAttest)
        }
    }

    public func makeRadarOptions() async -> STPRadarOptions {
        if challengeTokens.hcaptchaToken != nil || challengeTokens.assertion != nil {
            return STPRadarOptions(hcaptchaToken: challengeTokens.hcaptchaToken, assertion: challengeTokens.assertion)
        }
        let (hcaptchaToken, assertion) = await fetchTokensWithTimeout()
        return STPRadarOptions(hcaptchaToken: hcaptchaToken, assertion: assertion)
    }

    func fetchTokensWithTimeout() async -> ChallengeTokens {
        let timeoutNs = UInt64(timeout) * 1_000_000_000
        let startTime = Date()
        let siteKey = await passiveCaptchaChallenge?.passiveCaptchaData.siteKey
        do {
            return try await withThrowingTaskGroup(of: ChallengeTokens.self) { group in
                let isReady = await passiveCaptchaChallenge?.hasFetchedToken
                var numberOfChallenges = 0
                // Add hcaptcha task
                if let passiveCaptchaChallenge {
                    numberOfChallenges += 1
                    group.addTask {
                        let hcaptchaToken = try await passiveCaptchaChallenge.fetchToken()
                        return await (hcaptchaToken, self.challengeTokens.assertion)
                    }
                }
                // Add attestation task
                if let attestationConfirmationChallenge {
                    numberOfChallenges += 1
                    group.addTask {
                        let assertion = await attestationConfirmationChallenge.fetchAssertion()
                        return await (self.challengeTokens.hcaptchaToken, assertion)
                    }
                }
                // Add timeout task
                group.addTask {
                    try await Task.sleep(nanoseconds: timeoutNs)
                    throw Error.timeout
                }
                defer {
                    // ⚠️ TaskGroups can't return until all child tasks have completed, so we need to cancel remaining tasks and handle cancellation to complete as quickly as possible
                    Task {
                        await passiveCaptchaChallenge?.cancel()
                        await attestationConfirmationChallenge?.cancel()
                    }
                    group.cancelAll()
                }
                // Wait for challenge completions
                for _ in 0..<numberOfChallenges {
                    let token = try await group.next()
                    self.challengeTokens.hcaptchaToken = token?.hcaptchaToken ?? self.challengeTokens.hcaptchaToken
                    self.challengeTokens.assertion = token?.assertion ?? self.challengeTokens.assertion
                    logIfNecessary(result: token, siteKey: siteKey, isReady: isReady, duration: Date().timeIntervalSince(startTime))
                }
                return challengeTokens
            }
        } catch {
            if passiveCaptchaChallenge != nil, challengeTokens.hcaptchaToken == nil, let siteKey {
                STPAnalyticsClient.sharedClient.logPassiveCaptchaError(error: error, siteKey: siteKey, duration: Date().timeIntervalSince(startTime))
            }
            if attestationConfirmationChallenge != nil, challengeTokens.assertion == nil {
                STPAnalyticsClient.sharedClient.logAttestationConfirmationError(error: error, duration: Date().timeIntervalSince(startTime))
            }
            return challengeTokens
        }
    }

    // must be called after completing the signed request
    public func complete() async {
        await attestationConfirmationChallenge?.complete()
    }

    private func logIfNecessary(result: ChallengeTokens?, siteKey: String?, isReady: Bool?, duration: TimeInterval) {
        if result?.hcaptchaToken != nil, result?.assertion == nil, let siteKey, let isReady {
            STPAnalyticsClient.sharedClient.logPassiveCaptchaAttach(siteKey: siteKey, isReady: isReady, duration: duration)
        }
    }

    func setTimeout(timeout: TimeInterval) {
        self.timeout = timeout
    }

}
