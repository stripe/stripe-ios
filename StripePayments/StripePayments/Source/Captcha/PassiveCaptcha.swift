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

    private let passiveCaptcha: PassiveCaptcha
    private var validationTask: Task<CaptchaResult?, Never>?
    private var isValidationComplete = false

    var timeout: TimeInterval = STPAnalyticsClient.isUnitOrUITest ? 0 : 6 // same as web

    func setTimeout(timeout: TimeInterval) {
        self.timeout = timeout
    }

    public init(passiveCaptcha: PassiveCaptcha) {
        self.passiveCaptcha = passiveCaptcha
        Task { await start() } // Intentionally not blocking loading/initialization!
    }

    private func start() {
        guard validationTask == nil else { return }

        validationTask = Task<CaptchaResult?, Never> { [siteKey = passiveCaptcha.siteKey, rqdata = passiveCaptcha.rqdata, weak self] () -> CaptchaResult? in
            STPAnalyticsClient.sharedClient.logPassiveCaptchaInit(siteKey: siteKey)
            do {
                let hcaptcha = try HCaptcha(apiKey: siteKey,
                                            passiveApiKey: true,
                                            rqdata: rqdata,
                                            host: "stripecdn.com")
                STPAnalyticsClient.sharedClient.logPassiveCaptchaExecute(siteKey: siteKey)
                let startTime = Date()
                let result = await withCheckedContinuation { (continuation: CheckedContinuation<CaptchaResult, Never>) in
                    // Prevent Swift Task continuation misuse
                    var isResumed = false
                    let resumeOnce = { (result: CaptchaResult) in
                        guard !isResumed else { return }
                        isResumed = true
                        continuation.resume(returning: result)
                    }
                    hcaptcha.didFinishLoading {
                        hcaptcha.validate { result in
                            do {
                                let token = try result.dematerialize()
                                resumeOnce(.success(token))
                            } catch {
                                resumeOnce(.error(error))
                            }
                        }
                    }
                }
                guard !Task.isCancelled else { return nil }
                // Mark as complete
                await self?.setValidationComplete()
                let duration = Date().timeIntervalSince(startTime)
                switch result {
                case .success:
                    STPAnalyticsClient.sharedClient.logPassiveCaptchaSuccess(siteKey: siteKey, duration: duration)
                case .error(let error):
                    STPAnalyticsClient.sharedClient.logPassiveCaptchaError(error: error, siteKey: siteKey, duration: duration)
                }
                return result
            } catch {
                STPAnalyticsClient.sharedClient.logPassiveCaptchaError(error: error, siteKey: siteKey, duration: 0)
                return .error(error)
            }
        }
    }

    private func setValidationComplete() {
        isValidationComplete = true
    }

    public func fetchToken() async -> String? {
        let timeoutNs = UInt64(timeout) * 1_000_000_000
        let startTime = Date()
        return await withTaskGroup(of: CaptchaResult?.self) { group in
            let isReady = isValidationComplete
            // Add hcaptcha task
            group.addTask { [weak self] in
                guard let self else { return nil }
                return await validationTask?.value
            }
            // Add timeout task
            group.addTask {
                try? await Task.sleep(nanoseconds: timeoutNs)
                return .error(Error.timeout)
            }
            defer {
                group.cancelAll()
                validationTask?.cancel()
            }
            // Wait for first completion
            let result: CaptchaResult? = await group.next()?.flatMap(\.self)
            let siteKey = passiveCaptcha.siteKey
            switch result {
            case .success(let token):
                STPAnalyticsClient.sharedClient.logPassiveCaptchaAttach(siteKey: siteKey, isReady: isReady, duration: Date().timeIntervalSince(startTime))
                return token
            case .error(let error):
                STPAnalyticsClient.sharedClient.logPassiveCaptchaError(error: error, siteKey: siteKey, duration: Date().timeIntervalSince(startTime))
                return nil
            case .none:
                assertionFailure("No captcha result found!")
                return nil
            }
        }
    }

}

// All duration analytics are in milliseconds
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
            analytic: GenericAnalytic(event: .passiveCaptchaSuccess, params: ["site_key": siteKey, "duration": duration * 1000])
        )
    }

    func logPassiveCaptchaError(error: Error, siteKey: String, duration: TimeInterval) {
        log(
            analytic: ErrorAnalytic(event: .passiveCaptchaError, error: error, additionalNonPIIParams: ["site_key": siteKey, "duration": duration * 1000])
        )
    }

    func logPassiveCaptchaAttach(siteKey: String, isReady: Bool, duration: TimeInterval) {
        log(
            analytic: GenericAnalytic(event: .passiveCaptchaAttach, params: ["site_key": siteKey, "is_ready": isReady, "duration": duration * 1000])
        )
    }
}
