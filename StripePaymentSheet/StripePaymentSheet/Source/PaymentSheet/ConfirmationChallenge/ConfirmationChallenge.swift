//
//  ConfirmationChallenge.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 10/29/25.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

actor ConfirmationChallenge {
    private var passiveCaptchaChallenge: PassiveCaptchaChallenge?
    private var attestationChallenge: AttestationChallenge?

    private var timeout: TimeInterval = 6 // same as web

    func setTimeout(timeout: TimeInterval) {
        self.timeout = timeout
    }

    typealias ChallengeTokens = (hcaptchaToken: String?, assertion: StripeAttest.Assertion?)

    // enablePassiveCaptcha and enableAttestation are determined by the playground switches and will be removed on release
    public init(enablePassiveCaptcha: Bool, enableAttestation: Bool, elementsSession: STPElementsSession, stripeAttest: StripeAttest) {
        self.init(enablePassiveCaptcha: enablePassiveCaptcha, enableAttestation: enableAttestation, elementsSession: elementsSession, stripeAttest: stripeAttest, hcaptchaFactory: PassiveHCaptchaFactory())
    }

    init(enablePassiveCaptcha: Bool, enableAttestation: Bool, elementsSession: STPElementsSession, stripeAttest: StripeAttest, hcaptchaFactory: HCaptchaFactory) {
        if enablePassiveCaptcha, let passiveCaptchaData = elementsSession.passiveCaptchaData {
            self.passiveCaptchaChallenge = PassiveCaptchaChallenge(passiveCaptchaData: passiveCaptchaData, hcaptchaFactory: hcaptchaFactory)
        }
        if enableAttestation, elementsSession.shouldAttestOnConfirmation {
            self.attestationChallenge = AttestationChallenge(stripeAttest: stripeAttest, canSyncState: elementsSession.linkSettings?.attestationStateSyncEnabled ?? false)
        }
    }

    public func makeRadarOptions() async -> STPRadarOptions {
        let (hcaptchaToken, assertion) = await fetchTokensWithTimeout()
        return STPRadarOptions(hcaptchaToken: hcaptchaToken, assertion: assertion)
    }

    func fetchTokensWithTimeout() async -> ChallengeTokens {
        let startTime = Date()
        let isReady = await passiveCaptchaChallenge?.hasFetchedToken ?? false
        let getPassiveCaptchaToken: () async throws -> String? = {
            guard let passiveCaptchaChallenge = self.passiveCaptchaChallenge else {
                return nil
            }
            return try await passiveCaptchaChallenge.fetchToken()
        }

        let getAttestationAssertion: () async throws -> StripeAttest.Assertion? = {
            guard let attestationChallenge = self.attestationChallenge else {
                return nil
            }
            return await attestationChallenge.fetchAssertion()
        }

        let (hcaptchaTokenResult, assertionResult) = await withTimeout(timeout, getPassiveCaptchaToken, getAttestationAssertion)
        if let passiveCaptchaChallenge {
            switch hcaptchaTokenResult {
            case .success:
                STPAnalyticsClient.sharedClient.logPassiveCaptchaAttach(siteKey: passiveCaptchaChallenge.passiveCaptchaData.siteKey, isReady: isReady, duration: Date().timeIntervalSince(startTime))
            case .failure(let error):
                if error is TimeoutError {
                    STPAnalyticsClient.sharedClient.logPassiveCaptchaError(error: error, siteKey: passiveCaptchaChallenge.passiveCaptchaData.siteKey, duration: Date().timeIntervalSince(startTime))
                }
            }
        }
        if case .failure(let error) = assertionResult, error is TimeoutError {
            STPAnalyticsClient.sharedClient.logAttestationConfirmationError(error: error, duration: Date().timeIntervalSince(startTime))
        }
        let hcaptchaToken: String? = try? hcaptchaTokenResult.get()
        let assertion: StripeAttest.Assertion? = try? assertionResult.get()
        return (hcaptchaToken: hcaptchaToken, assertion: assertion)
    }

    // must be called after completing the signed request
    public func complete() async {
        await attestationChallenge?.complete()
    }

}
