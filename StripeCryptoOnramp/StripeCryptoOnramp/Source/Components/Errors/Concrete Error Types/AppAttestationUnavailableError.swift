//
//  AppAttestationUnavailableError.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 6/15/26.
//

import Foundation
@_spi(STP) import StripeCore

/// Details from a local app attestation availability failure.
@_spi(CryptoOnrampAlpha)
public struct AppAttestationUnavailableError: StripeCryptoOnrampError {

    /// The original error that was mapped to this error.
    public let underlyingError: Swift.Error?

    /// Local SDK context used to expose diagnostics.
    let diagnosticContext: DiagnosticContext

    /// Creates an app attestation availability error.
    ///
    /// - Parameters:
    ///   - underlyingError: The original error that was mapped to this error.
    ///   - diagnosticContext: Local SDK context used to expose diagnostics.
    init(underlyingError: Swift.Error, diagnosticContext: DiagnosticContext) {
        self.underlyingError = underlyingError
        self.diagnosticContext = diagnosticContext
    }

    // MARK: - StripeCryptoOnrampError

    public var code: String {
        return "app_attestation_unavailable"
    }

    public var userMessage: String {
        return String.Localized.cryptoOnrampErrorAppAttestationUnavailable
    }

    public var developerMessage: String {
        return StripeCryptoOnrampErrorRenderer.render(
            developerBody: """
            App attestation unavailable: this app isn't configured to use Stripe Crypto Onramp.

            This usually means app attestation isn't enabled for this Stripe account, or this app isn't registered as a trusted application. Use your iOS bundle ID and contact Stripe to enable app attestation or register the app for this account.
            """,
            code: code,
            nextStep: "Confirm app attestation is enabled for this Stripe account and that the app identifier is registered as trusted, then call configure again.",
            docURL: docURL,
            diagnosticContext: diagnosticContext
        )
    }

    public var docURL: URL? {
        return nil
    }
}
