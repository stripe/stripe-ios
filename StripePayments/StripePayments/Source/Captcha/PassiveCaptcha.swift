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
    private let passiveCaptcha: PassiveCaptcha?
    private var validationTask: Task<String?, Never>?
    private let testTimeout: UInt64?

    public init(passiveCaptcha: PassiveCaptcha?, testTimeout: UInt64? = nil) {
        self.passiveCaptcha = passiveCaptcha
        self.testTimeout = testTimeout
    }

    @_spi(STP) public func start() {
        guard let passiveCaptcha, validationTask == nil else { return }
        let timeoutNs: UInt64 = {
            if let testTimeout {
                return testTimeout
            }
            return STPAnalyticsClient.isUnitOrUITest ? 0 : 6_000_000_000
        }()

        validationTask = Task<String?, Never> { [siteKey = passiveCaptcha.siteKey, rqdata = passiveCaptcha.rqdata, timeoutNs] () -> String? in
            do {
                let hcaptcha = try HCaptcha(apiKey: siteKey,
                                            passiveApiKey: true,
                                            rqdata: rqdata,
                                            host: "stripecdn.com")
                STPAnalyticsClient.sharedClient.logPassiveCaptchaInit(siteKey: siteKey)

                return await withCheckedContinuation { (continuation: CheckedContinuation<String?, Never>) in
                    var hasCompleted = false
                    let timeoutTask = Task { @MainActor in
                        try? await Task.sleep(nanoseconds: timeoutNs)
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
            } catch {
                STPAnalyticsClient.sharedClient.logPassiveCaptchaError(error: error, siteKey: siteKey)
                return nil
            }
        }
    }

    @_spi(STP) public func fetchToken() async -> String? {
        if validationTask == nil {
            start()
        }
        return await validationTask?.value
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
