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

private enum CaptchaResult {
    case success(String)
    case error(Error)
}

@_spi(STP) public actor PassiveCaptchaChallenge {
    enum Error: Swift.Error {
        case timeout
    }

    /// Test configuration - can be set by tests to override default behavior
    static var testConfiguration: TestConfiguration?

    public struct TestConfiguration {
        var timeout: TimeInterval
        var delay: TimeInterval

        public init(timeout: TimeInterval? = nil, delay: TimeInterval? = nil) {
            self.timeout = timeout ?? 6
            self.delay = delay ?? 0
        }
    }

    private let passiveCaptcha: PassiveCaptcha?
    private var validationTask: Task<String?, Never>?
    private var isValidationComplete = false

    public init(passiveCaptcha: PassiveCaptcha?) {
        self.passiveCaptcha = passiveCaptcha
    }

    public func start() {
        guard let passiveCaptcha, validationTask == nil else { return }

        validationTask = Task<String?, Never> { [siteKey = passiveCaptcha.siteKey, weak self] () -> String? in
            STPAnalyticsClient.sharedClient.logPassiveCaptchaInit(siteKey: siteKey)
            do {
                let hcaptcha = try HCaptcha(apiKey: passiveCaptcha.siteKey,
                                        passiveApiKey: true,
                                         rqdata: passiveCaptcha.rqdata,
                                        host: "stripecdn.com")
                STPAnalyticsClient.sharedClient.logPassiveCaptchaExecute(siteKey: siteKey)
                let startTime = Date()
                let result = await withCheckedContinuation { (continuation: CheckedContinuation<CaptchaResult, Never>) in
                    hcaptcha.didFinishLoading {
                        hcaptcha.validate { result in
                            do {
                                let token = try result.dematerialize()
                                continuation.resume(returning: .success(token))
                            } catch {
                                continuation.resume(returning: .error(error))
                            }
                        }
                    }
                }
                if let testConfiguration = PassiveCaptchaChallenge.testConfiguration {
                    try? await Task.sleep(nanoseconds: UInt64(testConfiguration.delay) * 1_000_000_000)
                }
                // Mark as complete
                await self?.setValidationComplete()
                let duration = Date().timeIntervalSince(startTime) * 1000
                switch result {
                case .success(let token):
                    STPAnalyticsClient.sharedClient.logPassiveCaptchaSuccess(siteKey: siteKey, duration: duration)
                    return token
                case .error(let error):
                    STPAnalyticsClient.sharedClient.logPassiveCaptchaError(error: error, siteKey: siteKey, duration: duration)
                    return nil
                }
            } catch {
                STPAnalyticsClient.sharedClient.logPassiveCaptchaError(error: error, siteKey: siteKey, duration: 0)
                return nil
            }
        }
    }

    private func setValidationComplete() {
        isValidationComplete = true
    }

    public func fetchToken() async -> String? {
        guard let siteKey = passiveCaptcha?.siteKey else { return nil }
        let timeoutNs: UInt64 = {
            if let testTimeout = PassiveCaptchaChallenge.testConfiguration?.timeout {
                return UInt64(testTimeout) * 1_000_000_000
            }
            return STPAnalyticsClient.isUnitOrUITest ? 0 : 6_000_000_000
        }()
        let startTime = Date()
        var isReady = false
        return await withTaskGroup(of: String?.self) { group in
            // Add hcaptcha task
            group.addTask { [weak self] in
                guard let self else { return nil }
                if await validationTask == nil {
                    await self.start()
                } else {
                    isReady = await isValidationComplete
                }
                return await validationTask?.value
            }
            // Add timeout task
            group.addTask {
                try? await Task.sleep(nanoseconds: timeoutNs)
                return nil
            }
            // Wait for first completion and cancel remaining tasks
            let unwrappedToken: String? = await group.next() ?? nil
            group.cancelAll()
            if let unwrappedToken {
                STPAnalyticsClient.sharedClient.logPassiveCaptchaAttach(siteKey: siteKey, isReady: isReady, duration: Date().timeIntervalSince(startTime) * 1000)
                return unwrappedToken
            } else {
                STPAnalyticsClient.sharedClient.logPassiveCaptchaError(error: Error.timeout, siteKey: siteKey, duration: Date().timeIntervalSince(startTime) * 1000)
                return nil
            }
        }
    }
}

extension STPAnalyticsClient {
    func logPassiveCaptchaInit(siteKey: String) {
        log(
            analytic: GenericAnalytic(event: .passiveCaptchaInit, params: ["site_key": siteKey])
        )
    }

    func logPassiveCaptchaExecute(siteKey: String) {
        log(
            analytic: GenericAnalytic(event: .passiveCaptchaExecute, params: ["site_key": siteKey])
        )
    }

    func logPassiveCaptchaSuccess(siteKey: String, duration: TimeInterval) {
        log(
            analytic: GenericAnalytic(event: .passiveCaptchaSuccess, params: ["site_key": siteKey, "duration": duration])
        )
    }

    func logPassiveCaptchaError(error: Error, siteKey: String, duration: TimeInterval) {
        log(
            analytic: ErrorAnalytic(event: .passiveCaptchaError, error: error, additionalNonPIIParams: ["site_key": siteKey, "duration": duration])
        )
    }

    func logPassiveCaptchaAttach(siteKey: String, isReady: Bool, duration: TimeInterval) {
        log(
            analytic: GenericAnalytic(event: .passiveCaptchaAttach, params: ["site_key": siteKey, "is_ready": isReady, "duration": duration])
        )
    }
}
