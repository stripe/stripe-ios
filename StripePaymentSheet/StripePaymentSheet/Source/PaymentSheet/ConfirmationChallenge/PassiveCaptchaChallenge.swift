//
//  PassiveCaptchaChallenge.swift
//  StripePayments
//
//  Created by Joyce Qin on 8/3/25.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

/// PassiveCaptcha, delivered in the `v1/elements/sessions` response.
/// - Seealso: https://git.corp.stripe.com/stripe-internal/pay-server/blob/master/lib/elements/api/resources/elements_passive_captcha_resource.rb
struct PassiveCaptchaData: Equatable, Hashable {

    let siteKey: String
    let rqdata: String?

    /// Helper method to decode the `v1/elements/sessions` response's `passive_captcha` hash.
    /// - Parameter response: The value of the `passive_captcha` key in the `v1/elements/sessions` response.
    public static func decoded(
        fromAPIResponse response: [AnyHashable: Any]?
    ) -> PassiveCaptchaData? {
        guard let response else {
            return nil
        }

        guard let siteKey = response["site_key"] as? String
        else {
            return nil
        }

        // Optional
        let rqdata = response["rqdata"] as? String
        return PassiveCaptchaData(
            siteKey: siteKey,
            rqdata: rqdata
        )
    }

}

actor PassiveCaptchaChallenge {
    let passiveCaptchaData: PassiveCaptchaData
    var isTokenReady: Bool { // Fetched for the attach analytic. If session is expired, reset before the next fetch.
        let isSessionExpired = isSessionExpired()
        if isSessionExpired {
            self.tokenTask = nil
            self._hasToken = false
            self.hcaptcha?.reset()
        }
        return _hasToken
    }
    private let hcaptchaFactory: HCaptchaFactory
    private var hcaptcha: HCaptcha?
    private var tokenTask: Task<String, Error>?
    private var _hasToken: Bool = false
    private var sessionStartTime: Date?

    private static let sessionExpiration: TimeInterval = 29 * 60

    public init(passiveCaptchaData: PassiveCaptchaData) {
        self.init(passiveCaptchaData: passiveCaptchaData, hcaptchaFactory: PassiveHCaptchaFactory())
    }

    init(passiveCaptchaData: PassiveCaptchaData, hcaptchaFactory: HCaptchaFactory) {
        self.passiveCaptchaData = passiveCaptchaData
        self.hcaptchaFactory = hcaptchaFactory
        Task { [weak self] in // Intentionally not blocking loading/initialization!
            try await self?.createHCaptcha()
            _ = try await self?.fetchToken()
        }
    }

    private func createHCaptcha() throws {
        STPAnalyticsClient.sharedClient.logPassiveCaptchaInit(siteKey: passiveCaptchaData.siteKey)
        let startTime = Date()
        do {
            self.hcaptcha = try hcaptchaFactory.create(siteKey: passiveCaptchaData.siteKey, rqdata: passiveCaptchaData.rqdata)
        } catch {
            STPAnalyticsClient.sharedClient.logPassiveCaptchaError(error: error, siteKey: passiveCaptchaData.siteKey, duration: Date().timeIntervalSince(startTime))
            throw error
        }
    }

    private func isSessionExpired() -> Bool {
        // The session starts when we get our first token
        guard let sessionStartTime else { return false } // If sessionStartTime is nil, then we haven't gotten our first token back yet
        return Date().timeIntervalSince(sessionStartTime) >= Self.sessionExpiration
    }

    public func fetchToken() async throws -> String {
        if let tokenTask {
            return try await withTaskCancellationHandler {
                try await tokenTask.value
            } onCancel: {
                tokenTask.cancel()
            }
        }

        let tokenTask = Task<String, Error> { [siteKey = passiveCaptchaData.siteKey, hcaptcha, weak self] () -> String in
            STPAnalyticsClient.sharedClient.logPassiveCaptchaExecute(siteKey: siteKey)
            let startTime = Date()
            do {
                let result = try await withTaskCancellationHandler {
                    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
                        // Prevent Swift Task continuation misuse - the validate completion block can get called multiple times
                        var nillableContinuation: CheckedContinuation<String, Error>? = continuation

                        hcaptcha?.validate { result in
                            Task { @MainActor in // MainActor to prevent continuation from different threads
                                do {
                                    let token = try result.dematerialize()
                                    await self?.setSessionStartTime(Date())
                                    nillableContinuation?.resume(returning: token)
                                    nillableContinuation = nil
                                } catch {
                                    nillableContinuation?.resume(throwing: error)
                                    nillableContinuation = nil
                                }
                            }
                        }
                    }
                } onCancel: {
                    Task { @MainActor in
                        hcaptcha?.stop()
                    }
                }
                // Check cancellation after continuation
                try Task.checkCancellation()
                // Mark as complete
                await self?.setValidationComplete()
                STPAnalyticsClient.sharedClient.logPassiveCaptchaSuccess(siteKey: siteKey, duration: Date().timeIntervalSince(startTime))
                return result
            } catch {
                try Task.checkCancellation()
                STPAnalyticsClient.sharedClient.logPassiveCaptchaError(error: error, siteKey: siteKey, duration: Date().timeIntervalSince(startTime))
                throw error
            }
        }
        self.tokenTask = tokenTask
        return try await withTaskCancellationHandler {
            try await tokenTask.value
        } onCancel: {
            tokenTask.cancel()
        }
    }

    private func setSessionStartTime(_ sessionStartTime: Date) {
        self.sessionStartTime = sessionStartTime
    }

    private func setValidationComplete() {
        self._hasToken = true
    }

}

// Protocol for creating HCaptcha instances
protocol HCaptchaFactory {
    func create(siteKey: String, rqdata: String?) throws -> HCaptcha
}

struct PassiveHCaptchaFactory: HCaptchaFactory {
    func create(siteKey: String, rqdata: String?) throws -> HCaptcha {
        return try HCaptcha(apiKey: siteKey,
                            passiveApiKey: true,
                            rqdata: rqdata,
                            host: "stripecdn.com")
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
