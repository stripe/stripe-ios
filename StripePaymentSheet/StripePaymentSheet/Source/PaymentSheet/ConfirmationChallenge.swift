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
        let startTime = Date()
        let isReady = await passiveCaptchaChallenge?.hasFetchedToken
        let passiveCaptchaOperation = AsyncOperation<String?>(
            operation: {
                guard let passiveCaptchaChallenge = self.passiveCaptchaChallenge else { return nil }
                return try await passiveCaptchaChallenge.fetchToken()
     },
            onCancel: { await self.passiveCaptchaChallenge?.cancel() }
        )
        let attestationOperation = AsyncOperation<StripeAttest.Assertion?>(
            operation: {
                guard let attestationConfirmationChallenge = self.attestationConfirmationChallenge else { return nil }
                return await attestationConfirmationChallenge.fetchAssertion()
            },
            onCancel: {
                await self.attestationConfirmationChallenge?.cancel()
            }
        )
        let (hcaptchaTokenResult, assertionResult) = await withTimeout(timeout: timeout, passiveCaptchaOperation, attestationOperation)
        let hcaptchaToken: String? = try? hcaptchaTokenResult.get()?.flatMap { $0 }
        let assertion: StripeAttest.Assertion? = try? assertionResult.get()?.flatMap { $0 }
        await logIfNecessary(token: hcaptchaToken, siteKey: passiveCaptchaChallenge?.passiveCaptchaData.siteKey, isReady: isReady, duration: Date().timeIntervalSince(startTime))
        return (hcaptchaToken, assertion)
    }

    // must be called after completing the signed request
    public func complete() async {
        await attestationConfirmationChallenge?.complete()
    }

    private func logIfNecessary(token: String?, siteKey: String?, isReady: Bool?, duration: TimeInterval) {
        if token != nil, let siteKey, let isReady {
            STPAnalyticsClient.sharedClient.logPassiveCaptchaAttach(siteKey: siteKey, isReady: isReady, duration: duration)
        }
    }

    func setTimeout(timeout: TimeInterval) {
        self.timeout = timeout
    }

}
