//
//  InvalidWalletOwnershipChallengeError.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 6/24/26.
//

import Foundation
@_spi(STP) import StripeCore

/// Details from an invalid wallet ownership challenge API error, enriched with SDK-local diagnostic context.
@_spi(CryptoOnrampAlpha)
public struct InvalidWalletOwnershipChallengeError: StripeCryptoOnrampAPIError, APIErrorContextProviding {

    /// Shared API error context used to expose diagnostics and build developer-facing messages.
    public let apiErrorContext: APIErrorContext

    /// Local SDK context used to expose diagnostics.
    let diagnosticContext: DiagnosticContext

    /// Creates an invalid wallet ownership challenge API error from shared API error and local diagnostic context.
    ///
    /// - Parameters:
    ///   - apiErrorContext: Shared API error context used to expose diagnostics.
    ///   - diagnosticContext: Local SDK context used to expose diagnostics.
    init(apiErrorContext: APIErrorContext, diagnosticContext: DiagnosticContext) {
        self.apiErrorContext = apiErrorContext
        self.diagnosticContext = diagnosticContext
    }

    // MARK: - StripeCryptoOnrampAPIError

    public var code: String {
        return apiErrorContext.code(fallback: "crypto_onramp_invalid_wallet_ownership_challenge")
    }

    // MARK: - InvalidWalletOwnershipChallengeError

    /// A localized message that can be shown to the app user.
    public var userMessage: String {
        return String.Localized.cryptoOnrampErrorInvalidWalletOwnershipChallenge
    }

    /// A developer-facing description with diagnostic details and suggested next steps.
    public var developerMessage: String {
        return StripeCryptoOnrampErrorRenderer.renderAPIErrorDeveloperMessage(
            apiErrorContext: apiErrorContext,
            diagnosticContext: diagnosticContext,
            summary: apiMessage ?? "Wallet ownership verification failed: the challenge does not exist, belongs to a different authenticated consumer, was already consumed, or is otherwise invalid.",
            code: code,
            nextStep: "Request a new challenge for the registered wallet and authenticated consumer, then submit that challenge ID with its signature."
        )
    }
}
