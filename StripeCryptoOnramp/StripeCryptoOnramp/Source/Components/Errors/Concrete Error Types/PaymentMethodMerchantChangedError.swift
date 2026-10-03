//
//  PaymentMethodMerchantChangedError.swift
//  StripeCryptoOnramp
//

import Foundation
@_spi(STP) import StripeCore

/// The selected Apple Pay payment method must be collected again under the current platform key.
@_spi(CryptoOnrampAlpha)
public struct PaymentMethodMerchantChangedError: StripeCryptoOnrampError {
    let diagnosticContext: DiagnosticContext

    public var underlyingError: Swift.Error? { nil }

    public var code: String {
        return "payment_method_merchant_changed"
    }

    public var userMessage: String {
        return String.Localized.cryptoOnrampErrorPaymentMethodMerchantChanged
    }

    public var developerMessage: String {
        return StripeCryptoOnrampErrorRenderer.render(
            developerBody: "The selected Apple Pay payment method was created under a different platform key than the one currently resolved for this customer.",
            code: code,
            nextStep: "Call collectPaymentMethod(type: .applePay(paymentRequest:), from:) again and retry createCryptoPaymentToken() only after successful collection.",
            docURL: docURL,
            diagnosticContext: diagnosticContext
        )
    }

    public var docURL: URL? { nil }
}
