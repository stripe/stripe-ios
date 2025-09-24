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
    enum PassiveCaptchaError: Error {
        case unexpected
        case timeout
    }

    private let passiveCaptcha: PassiveCaptcha
    private var validationTask: Task<String, Error>?
    private var isValidationComplete = false

    var timeout: TimeInterval = STPAnalyticsClient.isUnitOrUITest ? 0 : 6 // same as web

    func setTimeout(timeout: TimeInterval) {
        self.timeout = timeout
    }

    public init?(passiveCaptcha: PassiveCaptcha) {
        self.passiveCaptcha = passiveCaptcha
        Task { try await fetchToken() } // Intentionally not blocking loading/initialization!
    }

    deinit {
        // Cancel any pending validation task
        validationTask?.cancel()
    }

    private func fetchToken() async throws -> String {
        if let validationTask {
            return try await validationTask.value
        }

        let validationTask = Task<String, Error> { [siteKey = passiveCaptcha.siteKey, rqdata = passiveCaptcha.rqdata, weak self] () -> String in
            STPAnalyticsClient.sharedClient.logPassiveCaptchaInit(siteKey: siteKey)
            do {
                let hcaptcha = try HCaptcha(apiKey: siteKey,
                                            passiveApiKey: true,
                                            rqdata: rqdata,
                                            host: "stripecdn.com")
                STPAnalyticsClient.sharedClient.logPassiveCaptchaExecute(siteKey: siteKey)
                let startTime = Date()
                let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
                    // Prevent Swift Task continuation misuse with atomic flag and safer handling
                    let lock = NSLock()
                    var nillableContinuation: CheckedContinuation<String, Error>? = continuation

                    // Weak reference to break retain cycles
                    hcaptcha.didFinishLoading { [weak hcaptcha] in
                        lock.lock()
                        defer { lock.unlock() }
                        hcaptcha?.validate { result in
                            do {
                                let token = try result.dematerialize()
                                nillableContinuation?.resume(returning: token)
                                nillableContinuation = nil
                            } catch {
                                nillableContinuation?.resume(throwing: error)
                                nillableContinuation = nil
                            }
                        }
                    }
                }

                // Check cancellation after continuation
                try Task.checkCancellation()
                // Mark as complete
                await self?.setValidationComplete()
                let duration = Date().timeIntervalSince(startTime)
                STPAnalyticsClient.sharedClient.logPassiveCaptchaSuccess(siteKey: siteKey, duration: duration)
                return result
            } catch {
                STPAnalyticsClient.sharedClient.logPassiveCaptchaError(error: error, siteKey: siteKey, duration: 0)
                throw error
            }
        }
        self.validationTask = validationTask
        return try await validationTask.value
    }

    private func setValidationComplete() {
        isValidationComplete = true
    }

    public func fetchTokenWithTimeout() async -> String? {
        let timeoutNs = UInt64(timeout) * 1_000_000_000
        let startTime = Date()
        let siteKey = passiveCaptcha.siteKey
        do {
            return try await withThrowingTaskGroup(of: String.self) { group in
                let isReady = isValidationComplete
                // Add hcaptcha task
                group.addTask { [weak self] in
                    guard let self else { throw PassiveCaptchaError.unexpected }
                    do {
                        return try await fetchToken()
                    } catch {
                        throw error
                    }
                }
                // Add timeout task
                group.addTask {
                    try? await Task.sleep(nanoseconds: timeoutNs)
                    throw PassiveCaptchaError.timeout
                }
                defer {
                    group.cancelAll()
                    validationTask?.cancel()
                }
                // Wait for first completion
                let result = try await group.next()
                STPAnalyticsClient.sharedClient.logPassiveCaptchaAttach(siteKey: siteKey, isReady: isReady, duration: Date().timeIntervalSince(startTime))
                return result
            }
        } catch {
            STPAnalyticsClient.sharedClient.logPassiveCaptchaError(error: error, siteKey: siteKey, duration: Date().timeIntervalSince(startTime))
            return nil
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
