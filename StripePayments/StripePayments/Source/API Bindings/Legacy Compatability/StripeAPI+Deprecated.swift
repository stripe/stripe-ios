//
//  StripeAPI+Deprecated.swift
//  StripePayments
//
//  Created by David Estes on 10/15/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
import PassKit

extension StripeAPI {

    /// A convenience method to build a `PKPaymentRequest` with sane default values.
    /// You will still need to configure the `paymentSummaryItems` property to indicate
    /// what the user is purchasing, as well as the optional `requiredShippingAddressFields`,
    /// `requiredBillingAddressFields`, and `shippingMethods` properties to indicate
    /// what contact information your application requires.
    /// Note that this method sets the payment request's countryCode to "US" and its
    /// currencyCode to "USD".
    /// - Parameter merchantIdentifier: Your Apple Merchant ID.
    /// - Returns: a `PKPaymentRequest` with proper default values. Returns nil if running on < iOS8.
    /// @deprecated Use `paymentRequestWithMerchantIdentifier:country:currency:` instead.
    /// Apple Pay is available in many countries and currencies, and you should use
    /// the appropriate values for your business.
    @available(
        *,
        deprecated,
        message: "Use `paymentRequestWithMerchantIdentifier:country:currency:` instead."
    )
    @objc(paymentRequestWithMerchantIdentifier:)
    public class func paymentRequest(
        withMerchantIdentifier merchantIdentifier: String
    )
        -> PKPaymentRequest
    {
        return self.paymentRequest(
            withMerchantIdentifier: merchantIdentifier,
            country: "US",
            currency: "USD"
        )
    }

}

// MARK: Deprecated top-level Stripe functions.
// These are included so Xcode can offer guidance on how to replace top-level Stripe usage.

/// :nodoc:
@available(
    *,
    deprecated,
    message:
        "Use StripeAPI.defaultPublishableKey instead. (StripeAPI.defaultPublishableKey = \"pk_12345_xyzabc\")"
)
public func setDefaultPublishableKey(_ publishableKey: String) {
    StripeAPI.defaultPublishableKey = publishableKey
}

/// :nodoc:
@available(
    *,
    deprecated,
    message: "Use StripeAPI.advancedFraudSignalsEnabled instead."
)
public var advancedFraudSignalsEnabled: Bool {
    get {
        StripeAPI.advancedFraudSignalsEnabled
    }
    set {
        StripeAPI.advancedFraudSignalsEnabled = newValue
    }
}

/// :nodoc:
@available(
    *,
    deprecated,
    message: "Use StripeAPI.jcbPaymentNetworkSupported instead."
)
public var jcbPaymentNetworkSupported: Bool {
    get {
        StripeAPI.jcbPaymentNetworkSupported
    }
    set {
        StripeAPI.jcbPaymentNetworkSupported = newValue
    }
}

/// :nodoc:
@available(
    *,
    deprecated,
    message: "Use StripeAPI.additionalEnabledApplePayNetworks instead."
)
public var additionalEnabledApplePayNetworks: [PKPaymentNetwork] {
    get {
        StripeAPI.additionalEnabledApplePayNetworks
    }
    set {
        StripeAPI.additionalEnabledApplePayNetworks = newValue
    }
}

/// :nodoc:
@available(
    *,
    deprecated,
    message: "Use StripeAPI.canSubmitPaymentRequest(_:) instead."
)
public func canSubmitPaymentRequest(_ paymentRequest: PKPaymentRequest) -> Bool {
    return StripeAPI.canSubmitPaymentRequest(paymentRequest)
}

/// :nodoc:
@available(
    *,
    deprecated,
    message: "Use StripeAPI.deviceSupportsApplePay() instead."
)
public func deviceSupportsApplePay() -> Bool {
    return StripeAPI.deviceSupportsApplePay()
}

/// :nodoc:
@available(
    *,
    deprecated,
    message: "Use StripeAPI.paymentRequest(withMerchantIdentifier:country:currency:) instead."
)
public func paymentRequest(
    withMerchantIdentifier merchantIdentifier: String,
    country countryCode: String,
    currency currencyCode: String
) -> PKPaymentRequest {
    return StripeAPI.paymentRequest(
        withMerchantIdentifier: merchantIdentifier,
        country: countryCode,
        currency: currencyCode
    )
}

/// :nodoc:
@available(
    *,
    deprecated,
    message: "Use StripeAPI.paymentRequest(withMerchantIdentifier:country:currency:) instead."
)
func paymentRequest(
    withMerchantIdentifier merchantIdentifier: String
)
    -> PKPaymentRequest
{
    return StripeAPI.paymentRequest(
        withMerchantIdentifier: merchantIdentifier,
        country: "US",
        currency: "USD"
    )
}

/// :nodoc:
@available(
    *,
    deprecated,
    message: "Use StripeAPI.handleURLCallback(with:) instead."
)
public func handleURLCallback(with url: URL) -> Bool {
    return StripeAPI.handleURLCallback(with: url)
}
