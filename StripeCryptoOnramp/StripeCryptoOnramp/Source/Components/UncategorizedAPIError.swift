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
public struct UncategorizedAPIError: StripeCryptoOnrampAPIError {

    /// Shared API error context used to expose diagnostics and build developer-facing messages.
    public let context: APIErrorContext

    /// Creates an uncategorized API error from shared API error context.
    ///
    /// - Parameter context: Shared API error context used to expose diagnostics.
    public init(context: APIErrorContext) {
        self.context = context
    }

    // MARK: - UncategorizedAPIError

    /// A localized message that can be shown to the app user.
    public var userMessage: String {
        return NSError.stp_unexpectedErrorMessage()
    }

    /// A developer-facing description with diagnostic details and suggested next steps.
    public var developerMessage: String {
        return context.developerDescription(
            summary: apiMessage ?? context.underlyingError.localizedDescription,
            nextStep: "Inspect the preserved Stripe API error for details and retry after correcting the issue."
        )
    }

    /// A stable code identifying this error.
    public var code: String {
        return apiErrorCode ?? "uncategorized_api_error"
    }
}
