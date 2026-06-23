//
//  UncategorizedAPIError.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 5/28/26.
//

import Foundation
@_spi(STP) import StripeCore

/// Details from an uncategorized backend API error, enriched with SDK-local diagnostic context.
@_spi(CryptoOnrampAlpha)
public struct UncategorizedAPIError: StripeCryptoOnrampAPIError, APIErrorContextProviding {

    /// Shared API error context used to expose diagnostics and build developer-facing messages.
    public let context: APIErrorContext

    /// Local SDK context used to expose diagnostics.
    let diagnosticContext: DiagnosticContext

    /// Creates an uncategorized API error from shared API error and local diagnostic context.
    ///
    /// - Parameters:
    ///   - context: Shared API error context used to expose diagnostics.
    ///   - diagnosticContext: Local SDK context used to expose diagnostics.
    init(context: APIErrorContext, diagnosticContext: DiagnosticContext) {
        self.context = context
        self.diagnosticContext = diagnosticContext
    }

    // MARK: - StripeCryptoOnrampAPIError

    public var code: String {
        return context.code(fallback: "uncategorized_api_error")
    }

    // MARK: - UncategorizedAPIError

    /// A localized message that can be shown to the app user.
    public var userMessage: String {
        return NSError.stp_unexpectedErrorMessage()
    }

    /// A developer-facing description with diagnostic details and suggested next steps.
    public var developerMessage: String {
        return StripeCryptoOnrampErrorRenderer.renderAPIErrorDeveloperMessage(
            context: context,
            diagnosticContext: diagnosticContext,
            summary: apiMessage ?? context.underlyingError.localizedDescription,
            code: code,
            nextStep: "Inspect the preserved Stripe API error for details and retry after correcting the request."
        )
    }
}
