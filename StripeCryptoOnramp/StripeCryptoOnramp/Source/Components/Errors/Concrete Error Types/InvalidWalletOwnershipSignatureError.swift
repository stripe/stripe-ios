//
//  InvalidWalletOwnershipSignatureError.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 6/24/26.
//

import Foundation
@_spi(STP) import StripeCore

/// Details from an invalid wallet ownership signature API error, enriched with SDK-local diagnostic context.
@_spi(CryptoOnrampAlpha)
public struct InvalidWalletOwnershipSignatureError: StripeCryptoOnrampAPIError, APIErrorContextProviding {

    /// Shared API error context used to expose diagnostics and build developer-facing messages.
    public let apiErrorContext: APIErrorContext

    /// Local SDK context used to expose diagnostics.
    let diagnosticContext: DiagnosticContext

    /// Creates an invalid wallet ownership signature API error from shared API error and local diagnostic context.
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
        return apiErrorContext.code(fallback: "crypto_onramp_invalid_wallet_ownership_signature")
    }

    // MARK: - InvalidWalletOwnershipSignatureError

    /// A localized message that can be shown to the app user.
    public var userMessage: String {
        return String.Localized.cryptoOnrampErrorInvalidWalletOwnershipSignature
    }

    /// A developer-facing description with diagnostic details and suggested next steps.
    public var developerMessage: String {
        return StripeCryptoOnrampErrorRenderer.renderAPIErrorDeveloperMessage(
            apiErrorContext: apiErrorContext,
            diagnosticContext: diagnosticContext,
            summary: apiMessage ?? "Wallet ownership verification failed: the submitted signature does not prove control of the wallet.",
            code: code,
            nextStep: "Sign the exact challenge message with the registered wallet address, then submit the resulting signature for the same challenge ID."
        )
    }
}
