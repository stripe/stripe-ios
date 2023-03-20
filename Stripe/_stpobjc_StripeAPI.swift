//
//  StripeAPI_objc.swift
//  StripeiOS
//
//  Created by Mel Ludowise on 9/3/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import PassKit
@_spi(STP) import StripeCore

/*
 NOTE: Because '@objc' is not supported in extensions below iOS 13, a separate
 Objective-C compatible wrapper of `StripeAPI` is needed. When updating
 documentation comments, make sure to update the corresponding comments in
 `StripeAPI` as well.
 */

/**
 A top-level class that imports the rest of the Stripe SDK.

 :nodoc:
 */
@available(swift, obsoleted: 0.0.1, message: "Use 'StripeAPI' instead.")
@objc(StripeAPI)
public class _stpobjc_StripeAPI: NSObject {
    /// Set this to your Stripe publishable API key, obtained from https://dashboard.stripe.com/apikeys.
    /// Set this as early as possible in your application's lifecycle, preferably in your AppDelegate or SceneDelegate.
    /// New instances of STPAPIClient will be initialized with this value.
    /// @warning Make sure not to ship your test API keys to the App Store! This will log a warning if you use your test key in a release build.
    @objc public static var defaultPublishableKey: String? {
        get {
            return StripeAPI.defaultPublishableKey
        } set {
            StripeAPI.defaultPublishableKey = newValue
        }
    }

    /// A Boolean value that determines whether additional device data is sent to Stripe for fraud prevention.
    /// If YES, additional device signals will be sent to Stripe.
    /// For more details on the information we collect, visit https://stripe.com/docs/disputes/prevention/advanced-fraud-detection
    /// Disabling this setting will reduce Stripe's ability to protect your business from fraudulent payments.
    /// The default value is YES.
    @objc public static var advancedFraudSignalsEnabled: Bool {
        get {
            return StripeAPI.advancedFraudSignalsEnabled
        } set {
            StripeAPI.advancedFraudSignalsEnabled = newValue
        }
    }

    /// If the SDK receives a "Too Many Requests" (429) status code from Stripe,
    /// it will automatically retry the request.
    /// The default value is 3.
    /// See https://stripe.com/docs/rate-limits for more information.
    @objc public static var maxRetries: Int {
        get {
            return StripeAPI.maxRetries
        } set {
            StripeAPI.maxRetries = newValue
        }
    }

    /// Call this method in your app delegate whenever you receive an URL in your
    /// app delegate for a Stripe callback.
    /// For convenience, you can pass all URL's you receive in your app delegate
    /// to this method first, and check the return value
    /// to easily determine whether it is a callback URL that Stripe will handle
    /// or if your app should process it normally.
    /// If you are using a universal link URL, you will receive the callback in `application:continueUserActivity:restorationHandler:`
    /// To learn more about universal links, see https://developer.apple.com/library/content/documentation/General/Conceptual/AppSearch/UniversalLinks.html
    /// If you are using a native scheme URL, you will receive the callback in `application:openURL:options:`
    /// To learn more about native url schemes, see https://developer.apple.com/library/content/documentation/iPhone/Conceptual/iPhoneOSProgrammingGuide/Inter-AppCommunication/Inter-AppCommunication.html#//apple_ref/doc/uid/TP40007072-CH6-SW10
    /// - Parameter url: The URL that you received in your app delegate
    /// - Returns: YES if the URL is expected and will be handled by Stripe. NO otherwise.
    @objc(handleStripeURLCallbackWithURL:) @discardableResult public static func handleURLCallback(
        with url: URL
    ) -> Bool {
        return StripeAPI.handleURLCallback(with: url)
    }

    /// Japanese users can enable JCB for Apple Pay by setting this to `YES`, after they have been approved by JCB.
    /// The default value is NO.
    /// @note JCB is only supported on iOS 10.1+
    @objc public class var jcbPaymentNetworkSupported: Bool {
        get {
            return StripeAPI.jcbPaymentNetworkSupported
        } set {
            StripeAPI.jcbPaymentNetworkSupported = newValue
        }
    }

    /// The SDK accepts Amex, Mastercard, Visa, and Discover for Apple Pay.
    /// Set this property to enable other card networks in addition to these.
    /// For example, `additionalEnabledApplePayNetworks = [.JCB]` enables JCB (note this requires onboarding from JCB and Stripe).
    @objc public static var additionalEnabledApplePayNetworks: [PKPaymentNetwork] {
        get {
            return StripeAPI.additionalEnabledApplePayNetworks
        } set {
            StripeAPI.additionalEnabledApplePayNetworks = newValue
        }
    }

    /// Whether or not this device is capable of using Apple Pay. This checks both
    /// whether the device supports Apple Pay, as well as whether or not they have
    /// stored Apple Pay cards on their device.
    /// - Parameter paymentRequest: The return value of this method depends on the
    /// `supportedNetworks` property of this payment request, which by default should be
    /// `[.amex, .masterCard, .visa, .discover]`.
    /// - Returns: whether or not the user is currently able to pay with Apple Pay.
    @objc
    public class func canSubmitPaymentRequest(_ paymentRequest: PKPaymentRequest) -> Bool {
        return StripeAPI.canSubmitPaymentRequest(paymentRequest)
    }

    /// Whether or not this can make Apple Pay payments via a card network supported
    /// by Stripe.
    /// The Stripe supported Apple Pay card networks are:
    /// American Express, Visa, Mastercard, Discover, Maestro.
    /// Japanese users can enable JCB by setting `JCBPaymentNetworkSupported` to YES,
    /// after they have been approved by JCB.
    /// - Returns: YES if the device is currently able to make Apple Pay payments via one
    /// of the supported networks. NO if the user does not have a saved card of a
    /// supported type, or other restrictions prevent payment (such as parental controls).
    @objc dynamic public class func deviceSupportsApplePay() -> Bool {
        return StripeAPI.deviceSupportsApplePay()
    }

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
        *, deprecated,
        message: "Use `paymentRequestWithMerchantIdentifier:country:currency:` instead."
    )
    @objc public class func paymentRequest(withMerchantIdentifier merchantIdentifier: String)
        -> PKPaymentRequest
    {
        return StripeAPI.paymentRequest(withMerchantIdentifier: merchantIdentifier)
    }

    /// A convenience method to build a `PKPaymentRequest` with sane default values.
    /// You will still need to configure the `paymentSummaryItems` property to indicate
    /// what the user is purchasing, as well as the optional `requiredShippingContactFields`,
    /// `requiredBillingContactFields`, and `shippingMethods` properties to indicate
    /// what additional contact information your application requires.
    /// - Parameters:
    ///   - merchantIdentifier: Your Apple Merchant ID.
    ///   - countryCode:        The two-letter code for the country where the payment
    /// will be processed. This should be the country of your Stripe account.
    ///   - currencyCode:       The three-letter code for the currency used by this
    /// payment request. Apple Pay interprets the amounts provided by the summary items
    /// attached to this request as amounts in this currency.
    /// - Returns: a `PKPaymentRequest` with proper default values.
    @objc public class func paymentRequest(
        withMerchantIdentifier merchantIdentifier: String,
        country countryCode: String,
        currency currencyCode: String
    ) -> PKPaymentRequest {
        return StripeAPI.paymentRequest(withMerchantIdentifier: merchantIdentifier, country: countryCode, currency: currencyCode)
    }
}
