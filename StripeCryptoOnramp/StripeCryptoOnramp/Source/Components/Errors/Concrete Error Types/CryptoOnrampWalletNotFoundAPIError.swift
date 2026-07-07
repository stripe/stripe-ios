//
//  CryptoOnrampWalletNotFoundAPIError.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 6/30/26.
//

import Foundation
@_spi(STP) import StripeCore

/// Details from a wallet-not-found API error, enriched with SDK-local diagnostic context.
@_spi(CryptoOnrampAlpha)
public struct CryptoOnrampWalletNotFoundAPIError: StripeCryptoOnrampAPIError, APIErrorContextProviding {

    /// Shared API error context used to expose diagnostics and build developer-facing messages.
    public let apiErrorContext: APIErrorContext

    /// Local SDK context used to expose diagnostics.
    let diagnosticContext: DiagnosticContext

    /// Creates a wallet-not-found API error from shared API error and local diagnostic context.
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
        return apiErrorContext.code(fallback: "crypto_onramp_wallet_not_found")
    }

    // MARK: - CryptoOnrampWalletNotFoundAPIError

    /// A localized message that can be shown to the app user.
    public var userMessage: String {
        return String.Localized.cryptoOnrampErrorWalletNotFound
    }

    /// A developer-facing description with diagnostic details and suggested next steps.
    public var developerMessage: String {
        return StripeCryptoOnrampErrorRenderer.renderAPIErrorDeveloperMessage(
            apiErrorContext: apiErrorContext,
            diagnosticContext: diagnosticContext,
            summary: apiMessage ?? "Crypto Onramp couldn't find the wallet for the authenticated consumer.",
            code: code,
            nextStep: "Use a wallet registered to the authenticated consumer, or register the wallet before retrying the request."
        )
    }
}
