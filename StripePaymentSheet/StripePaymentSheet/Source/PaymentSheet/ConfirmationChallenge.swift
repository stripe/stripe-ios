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

    var timeout: TimeInterval = STPAnalyticsClient.isUnitOrUITest ? 0 : 6 // same as web

    func setTimeout(timeout: TimeInterval) {
        self.timeout = timeout
    }

    typealias ChallengeTokens = (hcaptchaToken: String?, assertion: StripeAttest.Assertion?)

    public init(enablePassiveCaptcha: Bool, enableAttestation: Bool, elementsSession: STPElementsSession, stripeAttest: StripeAttest) {
        if enablePassiveCaptcha, let passiveCaptchaData = elementsSession.passiveCaptchaData {
            self.passiveCaptchaChallenge = PassiveCaptchaChallenge(passiveCaptchaData: passiveCaptchaData)
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
        async let hcaptchaToken = passiveCaptchaChallenge?.fetchTokenWithTimeout(timeout)
        async let assertion =  attestationChallenge?.fetchAssertionWithTimeout(timeout)
        return await (hcaptchaToken, assertion)
    }

    // must be called after completing the signed request
    public func complete() async {
        await attestationChallenge?.complete()
    }

}
