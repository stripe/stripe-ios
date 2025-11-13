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
    private let hcaptchaFactory: HCaptchaFactory
    private var tokenTask: Task<String, Error>?
    var hasFetchedToken = false

    public init(passiveCaptchaData: PassiveCaptchaData) {
        self.init(passiveCaptchaData: passiveCaptchaData, hcaptchaFactory: PassiveHCaptchaFactory())
    }

    init(passiveCaptchaData: PassiveCaptchaData, hcaptchaFactory: HCaptchaFactory) {
        self.passiveCaptchaData = passiveCaptchaData
        self.hcaptchaFactory = hcaptchaFactory
        Task { try await fetchToken() } // Intentionally not blocking loading/initialization!
    }

    public func fetchToken() async throws -> String {
        if let tokenTask {
            return try await withTaskCancellationHandler {
                try await tokenTask.value
            } onCancel: {
                tokenTask.cancel()
            }
        }

        let tokenTask = Task<String, Error> { [siteKey = passiveCaptchaData.siteKey, rqdata = passiveCaptchaData.rqdata, hcaptchaFactory, weak self] () -> String in
            STPAnalyticsClient.sharedClient.logPassiveCaptchaInit(siteKey: siteKey)
            let startTime = Date()
            do {
                let hcaptcha = try hcaptchaFactory.create(siteKey: siteKey, rqdata: rqdata)
                STPAnalyticsClient.sharedClient.logPassiveCaptchaExecute(siteKey: siteKey)
                let result = try await withTaskCancellationHandler {
                    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
                        // Prevent Swift Task continuation misuse - the validate completion block can get called multiple times
                        var nillableContinuation: CheckedContinuation<String, Error>? = continuation

                        hcaptcha.validate { result in
                            Task { @MainActor in // MainActor to prevent continuation from different threads
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
                } onCancel: {
                    Task { @MainActor in
                        hcaptcha.stop()
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
                try Task.checkCancellation()
                let duration = Date().timeIntervalSince(startTime)
                STPAnalyticsClient.sharedClient.logPassiveCaptchaError(error: error, siteKey: siteKey, duration: duration)
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

    private func setValidationComplete() {
        hasFetchedToken = true
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
