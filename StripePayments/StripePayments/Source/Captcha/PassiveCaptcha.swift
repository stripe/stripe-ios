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

    public init(siteKey: String, rqdata: String?) {
        self.siteKey = siteKey
        self.rqdata = rqdata
    }

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

    private let passiveCaptcha: PassiveCaptcha?
    private var hcaptcha: HCaptcha?
    private var validationTask: Task<String?, Never>?
    private let testTimeout: UInt64?
    private var isValidationComplete = false
    private var cachedResult: String?

    public init(passiveCaptcha: PassiveCaptcha?, testTimeout: UInt64? = nil) {
        self.passiveCaptcha = passiveCaptcha
        self.testTimeout = testTimeout
        guard let passiveCaptcha else { return }
        STPAnalyticsClient.sharedClient.logPassiveCaptchaInit(siteKey: passiveCaptcha.siteKey)
        let startTime = Date()
        do {
            self.hcaptcha = try HCaptcha(apiKey: passiveCaptcha.siteKey,
                                    passiveApiKey: true,
                                     rqdata: passiveCaptcha.rqdata,
                                    host: "stripecdn.com")

        } catch {
            let duration = Date().timeIntervalSince(startTime)
            STPAnalyticsClient.sharedClient.logPassiveCaptchaError(error: error, siteKey: passiveCaptcha.siteKey, duration: duration)
        }
    }

    @_spi(STP) public func start() {
        guard let passiveCaptcha, let hcaptcha, validationTask == nil else { return }
        let timeoutNs: UInt64 = {
            if let testTimeout {
                return testTimeout
            }
            return STPAnalyticsClient.isUnitOrUITest ? 0 : 8_000_000_000
        }()

        validationTask = Task<String?, Never> { [hcaptcha, siteKey = passiveCaptcha.siteKey, timeoutNs, weak self] () -> String? in
            STPAnalyticsClient.sharedClient.logPassiveCaptchaExecute(siteKey: siteKey)
            let startTime = Date()
            let result = await withTaskGroup(of: CaptchaResult.self) { group in
                // Add hcaptcha task
                group.addTask {
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
                    return result
                }
                // Add timeout task
                group.addTask {
                    try? await Task.sleep(nanoseconds: timeoutNs)
                    return .error(Error.timeout)
                }
                // Wait for first completion and cancel remaining tasks
                let result = await group.next()
                group.cancelAll()
                return result
            }
            // Cache result and mark as complete
            await self?.setValidationComplete()
            let duration = Date().timeIntervalSince(startTime)
            switch result {
            case .success(let token):
                STPAnalyticsClient.sharedClient.logPassiveCaptchaSuccess(siteKey: siteKey, duration: duration)
                return token
            case .error(let error):
                STPAnalyticsClient.sharedClient.logPassiveCaptchaError(error: error, siteKey: siteKey, duration: duration)
                return nil
            default:
                stpAssertionFailure("Unexpected result: \(String(describing: result))")
            }
            return nil
        }
    }

    private func setValidationComplete() {
        isValidationComplete = true
    }

    @_spi(STP) public func fetchToken() async -> String? {
        guard let siteKey = passiveCaptcha?.siteKey else { return nil }
        var isReady: Bool
        if validationTask == nil {
            start()
            isReady = false
        } else {
            isReady = isValidationComplete
        }
        STPAnalyticsClient.sharedClient.logPassiveCaptchaAttach(siteKey: siteKey, isReady: isReady)
        return await validationTask?.value
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

    func logPassiveCaptchaAttach(siteKey: String, isReady: Bool) {
        log(
            analytic: GenericAnalytic(event: .passiveCaptchaAttach, params: ["site_key": siteKey, "is_ready": isReady])
        )
    }
}
