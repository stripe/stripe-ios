//
//  PassiveCaptcha.swift
//  StripePayments
//
//  Created by Joyce Qin on 8/3/25.
//

import Foundation
@_spi(STP) import StripeCore

/// PassiveCaptcha, delivered in the `v1/elements/sessions` response.
/// - Seealso: https://git.corp.stripe.com/stripe-internal/pay-server/blob/master/lib/elements/api/resources/elements_passive_captcha_resource.rb
@_spi(STP) public struct PassiveCaptcha: Equatable, Hashable {

    let siteKey: String
    let rqdata: String?

    /// Helper method to decode the `v1/elements/sessions` response's `passive_captcha` hash.
    /// - Parameter response: The value of the `passive_captcha` key in the `v1/elements/sessions` response.
    public static func decoded(
        fromAPIResponse response: [AnyHashable: Any]?
    ) -> PassiveCaptcha? {
        guard let response else {
            return nil
        }

        guard let siteKey = response["site_key"] as? String
        else {
            return nil
        }

        // Optional
        let rqdata = response["rqdata"] as? String
        return PassiveCaptcha(
            siteKey: siteKey,
            rqdata: rqdata
        )
    }

}

@_spi(STP) public actor PassiveCaptchaChallenge {
    private let passiveCaptcha: PassiveCaptcha
    private let hcaptcha: HCaptcha?
    private let testTimeout: UInt64?

    public init(passiveCaptcha: PassiveCaptcha, testTimeout: UInt64? = nil) {
        self.passiveCaptcha = passiveCaptcha
        do {
            self.hcaptcha = try HCaptcha(apiKey: passiveCaptcha.siteKey,
                                          passiveApiKey: true,
                                          rqdata: passiveCaptcha.rqdata,
                                          host: "stripecdn.com")
            STPAnalyticsClient.sharedClient.logPassiveCaptchaInit(siteKey: passiveCaptcha.siteKey)
        } catch {
            self.hcaptcha = nil
            STPAnalyticsClient.sharedClient.logPassiveCaptchaError(error: error, siteKey: passiveCaptcha.siteKey)
        }
        self.testTimeout = testTimeout
    }

    @_spi(STP) public func fetchToken() async -> String? {
        let validationTask: Task<String?, Never> = Task<String?, Never> { [weak self] in
            guard let self, let hcaptcha = await self.hcaptcha else { return nil }
            let siteKey = await self.passiveCaptcha.siteKey
            let timeoutNs: UInt64 = {
                if let testTimeout = self.testTimeout {
                    return testTimeout
                } else {
                    return STPAnalyticsClient.isSimulatorOrTest ? 1_000_000 : 6_000_000_000
                }
            }()
            return await withCheckedContinuation { continuation in
                var hasCompleted: Bool = false
                let timeoutTask = Task { @MainActor in
                    do {
                        try await Task.sleep(nanoseconds: timeoutNs)
                    } catch {
                        return
                    }
                    if hasCompleted { return }
                    hasCompleted = true
                    STPAnalyticsClient.sharedClient.logPassiveCaptchaTimeout(siteKey: siteKey)
                    continuation.resume(returning: nil)
                }
                hcaptcha.didFinishLoading {
                    hcaptcha.validate { result in
                        Task { @MainActor in
                            if hasCompleted { return }
                            do {
                                let token = try result.dematerialize()
                                hasCompleted = true
                                STPAnalyticsClient.sharedClient.logPassiveCaptchaSuccess(siteKey: siteKey)
                                timeoutTask.cancel()
                                continuation.resume(returning: token)
                            } catch {
                                hasCompleted = true
                                STPAnalyticsClient.sharedClient.logPassiveCaptchaError(error: error, siteKey: siteKey)
                                timeoutTask.cancel()
                                continuation.resume(returning: nil)
                            }
                        }
                    }
                }
            }

        }
        return await validationTask.value
    }
}

extension STPAnalyticsClient {
    func logPassiveCaptchaInit(siteKey: String) {
        log(
            analytic: GenericAnalytic(event: .passiveCaptchaInit, params: ["site_key": siteKey])
        )
    }

    func logPassiveCaptchaSuccess(siteKey: String) {
        log(
            analytic: GenericAnalytic(event: .passiveCaptchaSuccess, params: ["site_key": siteKey])
        )
    }

    func logPassiveCaptchaError(error: Error, siteKey: String) {
        log(
            analytic: ErrorAnalytic(event: .passiveCaptchaError, error: error, additionalNonPIIParams: ["site_key": siteKey])
        )
    }

    func logPassiveCaptchaTimeout(siteKey: String) {
        log(
            analytic: GenericAnalytic(event: .passiveCaptchaTimeout, params: ["site_key": siteKey])
        )
    }
}
