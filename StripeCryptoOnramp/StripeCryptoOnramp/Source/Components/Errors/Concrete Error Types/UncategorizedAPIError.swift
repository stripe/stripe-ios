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

    /// Creates an uncategorized API error from shared API error context.
    ///
    /// - Parameter context: Shared API error context used to expose diagnostics.
    public init(context: APIErrorContext) {
        self.context = context
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
            summary: apiMessage ?? context.underlyingError.localizedDescription,
            code: code,
            sdkVersions: sdkVersions,
            nextStep: "Inspect the preserved Stripe API error for details and retry after correcting the request."
        )
    }
}
