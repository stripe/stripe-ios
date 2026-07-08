//
//  UnsupportedNetworkAPIError.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 6/30/26.
//

import Foundation
@_spi(STP) import StripeCore

/// Details from an unsupported-network API error, enriched with SDK-local diagnostic context.
@_spi(CryptoOnrampAlpha)
public struct UnsupportedNetworkAPIError: StripeCryptoOnrampAPIError, APIErrorContextProviding {

    /// Shared API error context used to expose diagnostics and build developer-facing messages.
    public let apiErrorContext: APIErrorContext

    /// Local SDK context used to expose diagnostics.
    let diagnosticContext: DiagnosticContext

    /// Creates an unsupported-network API error from shared API error and local diagnostic context.
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
        return apiErrorContext.code(fallback: "crypto_onramp_unsupported_network")
    }

    // MARK: - UnsupportedNetworkAPIError

    /// A localized message that can be shown to the app user.
    public var userMessage: String {
        return String.Localized.cryptoOnrampErrorUnsupportedNetwork
    }

    /// A developer-facing description with diagnostic details and suggested next steps.
    public var developerMessage: String {
        return StripeCryptoOnrampErrorRenderer.renderAPIErrorDeveloperMessage(
            apiErrorContext: apiErrorContext,
            diagnosticContext: diagnosticContext,
            summary: apiMessage ?? "Crypto Onramp doesn't support this wallet network for the requested operation.",
            code: code,
            nextStep: "Use a network supported by Crypto Onramp for this operation, then retry the request."
        )
    }
}
