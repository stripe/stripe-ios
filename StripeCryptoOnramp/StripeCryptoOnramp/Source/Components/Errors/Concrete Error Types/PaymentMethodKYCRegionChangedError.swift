//
//  PaymentMethodKYCRegionChangedError.swift
//  StripeCryptoOnramp
//

import Foundation
@_spi(STP) import StripeCore

/// The selected Apple Pay payment method must be collected again because the customer's KYC region changed.
@_spi(CryptoOnrampAlpha)
public struct PaymentMethodKYCRegionChangedError: StripeCryptoOnrampError {
    let diagnosticContext: DiagnosticContext

    public var underlyingError: Swift.Error? { nil }

    public var code: String {
        return "payment_method_kyc_region_changed"
    }

    public var userMessage: String {
        return String.Localized.cryptoOnrampErrorPaymentMethodKYCRegionChanged
    }

    public var developerMessage: String {
        return StripeCryptoOnrampErrorRenderer.render(
            developerBody: """
            This Apple Pay payment method can no longer be used to create a crypto payment token because the customer's KYC region changed after it was collected.
            In the crypto onramp flow, a collected Apple Pay payment method is bound to the customer's region at collection time and can't be reused if that region changes.
            This happens when Apple Pay is collected before the customer's region is final: the region in effect came from your countryHint or a default, and the customer's authenticated KYC region (country of residence) turned out to be different.
            """,
            code: code,
            nextStep: """
            Collect Apple Pay again with collectPaymentMethod(type: .applePay(paymentRequest:), from:), then call createCryptoPaymentToken() only after it succeeds.
            To avoid this:
            Ensure your countryHint matches the customer's KYC region before collecting Apple Pay pre-authentication, or
            Authenticate the customer first - so their KYC region is final - and then collect Apple Pay.
            """,
            docURL: docURL,
            diagnosticContext: diagnosticContext
        )
    }

    public var docURL: URL? { nil }
}
