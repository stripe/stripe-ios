//
//  ConfirmationChallenge.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 10/29/25.
//

import Foundation
@_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripePayments

actor ConfirmationChallenge {
    private var passiveCaptchaChallenge: PassiveCaptchaChallenge?
    private var attestationChallenge: AttestationChallenge?
    private var requestInProgress = false
    private var requestWaiters: [(id: UUID, continuation: CheckedContinuation<Void, Error>)] = []

    private var timeout: TimeInterval = 6 // same as web

    func setTimeout(timeout: TimeInterval) {
        self.timeout = timeout
    }

    typealias ChallengeTokens = (hcaptchaToken: String?, assertion: StripeAttest.Assertion?)

    public init(elementsSession: STPElementsSession, stripeAttest: StripeAttest) {
        self.init(elementsSession: elementsSession, stripeAttest: stripeAttest, hcaptchaFactory: PassiveHCaptchaFactory())
    }

    init(elementsSession: STPElementsSession, stripeAttest: StripeAttest, hcaptchaFactory: HCaptchaFactory) {
        if let passiveCaptchaData = elementsSession.passiveCaptchaData {
            self.passiveCaptchaChallenge = PassiveCaptchaChallenge(passiveCaptchaData: passiveCaptchaData, hcaptchaFactory: hcaptchaFactory)
        }
        if elementsSession.shouldAttestOnConfirmation {
            self.attestationChallenge = AttestationChallenge(stripeAttest: stripeAttest, canSyncState: elementsSession.linkSettings?.attestationStateSyncEnabled ?? false)
        }
    }

    public func makeRadarOptions(for paymentMethodType: STPPaymentMethodType) async -> STPRadarOptions? {
        // for card testing prevention, we only care to create and attach radar options for card payment methods
        // Link in payment method mode has no means of distinguishing if it's a card or otherwise, so we always include it to be safe
        guard paymentMethodType == .card || paymentMethodType == .link else {
            return nil
        }
        let (hcaptchaToken, assertion) = await fetchTokensWithTimeout()
        return STPRadarOptions(hcaptchaToken: hcaptchaToken, assertion: assertion)
    }

    /// Owns the challenge until the request carrying its radar options has finished.
    /// Cleanup is awaited on success, failure, and cancellation before another scoped request begins.
    func withRadarOptions<Result>(
        for paymentMethodType: STPPaymentMethodType,
        operation: (STPRadarOptions?) async throws -> Result
    ) async throws -> Result {
        try await acquireSlot()
        defer {
            releaseSlot()
        }

        do {
            try Task.checkCancellation()
            let options = await makeRadarOptions(for: paymentMethodType)
            try Task.checkCancellation()
            let result = try await operation(options)
            await complete()
            return result
        } catch {
            await complete()
            throw error
        }
    }

    /// Grants the slot immediately if free, otherwise queues until released.
    /// Queued waiters are cancellation-aware: canceling a queued caller resumes only that caller,
    /// without disturbing whoever currently holds the slot.
    private func acquireSlot() async throws {
        guard requestInProgress else {
            requestInProgress = true
            return
        }
        let id = UUID()
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                requestWaiters.append((id: id, continuation: continuation))
            }
        } onCancel: {
            Task { await self.cancelWaiter(id) }
        }
    }

    private func cancelWaiter(_ id: UUID) {
        guard let index = requestWaiters.firstIndex(where: { $0.id == id }) else { return }
        let continuation = requestWaiters.remove(at: index).continuation
        continuation.resume(throwing: CancellationError())
    }

    private func releaseSlot() {
        guard !requestWaiters.isEmpty else {
            requestInProgress = false
            return
        }
        let next = requestWaiters.removeFirst()
        next.continuation.resume()
    }

    /// Convenience for optional challenges: runs `operation` directly (with no radar options) when `challenge` is nil.
    @MainActor
    static func withRadarOptions<Result>(
        for paymentMethodType: STPPaymentMethodType,
        challenge: (any CheckoutConfirmationChallenge)?,
        operation: (STPRadarOptions?) async throws -> Result
    ) async throws -> Result {
        guard let challenge else { return try await operation(nil) }
        return try await challenge.withRadarOptions(for: paymentMethodType, operation: operation)
    }

    func fetchTokensWithTimeout() async -> ChallengeTokens {
        let startTime = Date()
        let getPassiveCaptchaToken: () async throws -> PassiveCaptchaChallenge.ConsumedToken? = {
            guard let passiveCaptchaChallenge = self.passiveCaptchaChallenge else {
                return nil
            }
            return try await passiveCaptchaChallenge.consumeToken()
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
            case .success(let consumedToken):
                STPAnalyticsClient.sharedClient.logPassiveCaptchaAttach(siteKey: passiveCaptchaChallenge.passiveCaptchaData.siteKey, isReady: consumedToken?.wasReady ?? false, duration: Date().timeIntervalSince(startTime))
            case .failure(let error):
                if error is TimeoutError {
                    STPAnalyticsClient.sharedClient.logPassiveCaptchaError(error: error, siteKey: passiveCaptchaChallenge.passiveCaptchaData.siteKey, duration: Date().timeIntervalSince(startTime))
                }
            }
        }
        if case .failure(let error) = assertionResult, error is TimeoutError {
            STPAnalyticsClient.sharedClient.logAttestationConfirmationError(error: error, duration: Date().timeIntervalSince(startTime))
        }
        let hcaptchaToken: String? = try? hcaptchaTokenResult.get()?.value
        let assertion: StripeAttest.Assertion? = try? assertionResult.get()
        return (hcaptchaToken: hcaptchaToken, assertion: assertion)
    }

    // must be called after completing the signed request
    public func complete() async {
        await attestationChallenge?.complete()
    }

}
