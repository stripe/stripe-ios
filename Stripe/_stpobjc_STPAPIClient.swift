//
//  _stpobjc_STPAPIClient.swift
//  StripeiOS
//
//  Created by David Estes on 9/7/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

// This is a workaround for the lack of cross-Swift-module extension support in
// the iOS 11 and iOS 12 Objective-C runtime.

import Foundation
import PassKit
import UIKit
@_spi(STP) import StripeCore

/*
 NOTE: Because '@objc' is not supported in cross-module extensions below iOS 13, a separate
 Objective-C compatible wrapper of `STPAPIClient` is needed. When updating
 documentation comments, make sure to update the corresponding comments in
 `STPAPIClient` as well.
 */

/// An Objective-C bridge for STPAPIClient.
/// :nodoc:
@objc(STPAPIClient)
@available(swift, deprecated: 0.0.1, renamed: "STPAPIClient")
public class _stpobjc_STPAPIClient: NSObject {
    var _apiClient: STPAPIClient
    
    /// The current version of this library.
    @objc public static let STPSDKVersion = STPAPIClient.STPSDKVersion

    /// A shared singleton API client.
    /// By default, the SDK uses this instance to make API requests
    /// eg in STPPaymentHandler, STPPaymentContext, STPCustomerContext, etc.
    @objc(sharedClient)
    @available(swift, deprecated: 0.0.1)
    public static let shared: _stpobjc_STPAPIClient = {
        return _stpobjc_STPAPIClient(apiClient: .shared)
    }()

    /// The client's publishable key.
    /// The default value is `StripeAPI.defaultPublishableKey`.
    @objc public var publishableKey: String? {
        get {
            _apiClient.publishableKey
        }
        set {
            _apiClient.publishableKey = newValue
        }
    }
    
    /// The client's configuration.
    /// Defaults to `STPPaymentConfiguration.shared`.
    @objc public var configuration: STPPaymentConfiguration {
        get {
            _apiClient.configuration
        }
        set {
            _apiClient.configuration = newValue
        }
    }


    /// In order to perform API requests on behalf of a connected account, e.g. to
    /// create a Source or Payment Method on a connected account, set this property to the ID of the
    /// account for which this request is being made.
    /// - seealso: https://stripe.com/docs/connect/authentication#authentication-via-the-stripe-account-header
    @objc public var stripeAccount: String? {
        get {
            _apiClient.stripeAccount
        }
        set {
            _apiClient.stripeAccount = newValue
        }
    }
    
    /// Libraries wrapping the Stripe SDK should set this, so that Stripe can contact you about future issues or critical updates.
    /// - seealso: https://stripe.com/docs/building-plugins#setappinfo
    @objc public var appInfo: _stpobjc_STPAppInfo? {
        get {
            _stpobjc_STPAppInfo(appInfo: _apiClient.appInfo)
        }
        set {
            _apiClient.appInfo = newValue?._appInfo
        }
    }

    /// The API version used to communicate with Stripe.
    @objc public static let apiVersion = STPAPIClient.apiVersion
    
    init(apiClient: STPAPIClient) {
        STPAnalyticsClient.sharedClient.addClass(toProductUsageIfNecessary: _stpobjc_STPAPIClient.self)
        _apiClient = apiClient
        super.init()
    }
    
    /// Initializes an API client with the given publishable key.
    /// - Parameter publishableKey: The publishable key to use.
    /// - Returns: An instance of STPAPIClient.
    @objc
    public init(publishableKey: String) {
        STPAnalyticsClient.sharedClient.addClass(toProductUsageIfNecessary: _stpobjc_STPAPIClient.self)
        _apiClient = STPAPIClient(publishableKey: publishableKey)
        super.init()
    }
    
    /// Initializes an API client with the given configuration.
    /// - Parameter configuration: The configuration to use.
    /// - Returns: An instance of STPAPIClient.
    @available(
        *, deprecated,
        message:
            "This initializer previously configured publishableKey and stripeAccount via the STPPaymentConfiguration instance. This behavior is deprecated; set the STPAPIClient configuration, publishableKey, and stripeAccount properties directly on the STPAPIClient instead."
    )
    @objc
    public init(configuration: STPPaymentConfiguration) {
        _apiClient = STPAPIClient()
        super.init()
        publishableKey = configuration.publishableKey
        stripeAccount = configuration.stripeAccount
    }
    
    // MARK: API Functions
    
    /// Converts an STPBankAccount object into a Stripe token using the Stripe API.
    /// - Parameters:
    ///   - bankAccount: The user's bank account details. Cannot be nil. - seealso: https://stripe.com/docs/api#create_bank_account_token
    ///   - completion:  The callback to run with the returned Stripe token (and any errors that may have occurred).
    @objc
    public func createToken(
        withBankAccount bankAccount: STPBankAccountParams,
        completion: @escaping STPTokenCompletionBlock
    ) {
        _apiClient.createToken(withBankAccount:bankAccount, completion: completion)
    }
    
    // MARK: PII
    
    /// Converts a personal identification number into a Stripe token using the Stripe API.
    /// - Parameters:
    ///   - pii: The user's personal identification number. Cannot be nil. - seealso: https://stripe.com/docs/api#create_pii_token
    ///   - completion:  The callback to run with the returned Stripe token (and any errors that may have occurred).
    @objc
    public func createToken(
        withPersonalIDNumber pii: String, completion: STPTokenCompletionBlock?
    ) {
        _apiClient.createToken(withPersonalIDNumber: pii, completion: completion)
    }

    /// Converts the last 4 SSN digits into a Stripe token using the Stripe API.
    /// - Parameters:
    ///   - ssnLast4: The last 4 digits of the user's SSN. Cannot be nil.
    ///   - completion:  The callback to run with the returned Stripe token (and any errors that may have occurred).
    @objc
    public func createToken(
        withSSNLast4 ssnLast4: String, completion: @escaping STPTokenCompletionBlock
    ) {
        _apiClient.createToken(withSSNLast4: ssnLast4, completion: completion)
    }
    
    
    // MARK: Connect Accounts
    
    /// Converts an `STPConnectAccountParams` object into a Stripe token using the Stripe API.
    /// This allows the connected account to accept the Terms of Service, and/or send Legal Entity information.
    /// - Parameters:
    ///   - account: The Connect Account parameters. Cannot be nil.
    ///   - completion: The callback to run with the returned Stripe token (and any errors that may have occurred).
    @objc
    public func createToken(
        withConnectAccount account: STPConnectAccountParams, completion: STPTokenCompletionBlock?
    ) {
        _apiClient.createToken(withConnectAccount: account, completion: completion)
    }
    
    // MARK: Upload
    
    /// Uses the Stripe file upload API to upload an image. This can be used for
    /// identity verification and evidence disputes.
    /// - Parameters:
    ///   - image: The image to be uploaded. The maximum allowed file size is 4MB
    /// for identity documents and 8MB for evidence disputes. Cannot be nil.
    /// Your image will be automatically resized down if you pass in one that
    /// is too large
    ///   - purpose: The purpose of this file. This can be either an identifing
    /// document or an evidence dispute.
    ///   - completion: The callback to run with the returned Stripe file
    /// (and any errors that may have occurred).
    /// - seealso: https://stripe.com/docs/file-upload
    @objc
    public func uploadImage(
        _ image: UIImage,
        purpose: STPFilePurpose,
        completion: STPFileCompletionBlock?
    ) {
        _apiClient.uploadImage(image, purpose: purpose, completion: completion)
    }
    
    // MARK: Credit Cards
    
    /// Converts an STPCardParams object into a Stripe token using the Stripe API.
    /// - Parameters:
    ///   - cardParams:  The user's card details. Cannot be nil. - seealso: https://stripe.com/docs/api#create_card_token
    ///   - completion:  The callback to run with the returned Stripe token (and any errors that may have occurred).
    @objc
    public func createToken(
        withCard cardParams: STPCardParams, completion: @escaping STPTokenCompletionBlock
    ) {
        _apiClient.createToken(withCard: cardParams, completion: completion)
    }

    /// Converts a CVC string into a Stripe token using the Stripe API.
    /// - Parameters:
    ///   - cvc:         The CVC/CVV number used to create the token. Cannot be nil.
    ///   - completion:  The callback to run with the returned Stripe token (and any errors that may have occurred).
    @objc
    public func createToken(forCVCUpdate cvc: String, completion: STPTokenCompletionBlock? = nil) {
        _apiClient.createToken(forCVCUpdate: cvc, completion: completion)
    }
    
    // MARK: Sources
    
    /// Creates a Source object using the provided details.
    /// Note: in order to create a source on a connected account, you can set your
    /// API client's `stripeAccount` property to the ID of the account.
    /// - seealso: https://stripe.com/docs/sources/connect#creating-direct-charges
    /// - Parameters:
    ///   - sourceParams: The details of the source to create. Cannot be nil. - seealso: https://stripe.com/docs/api#create_source
    ///   - completion:   The callback to run with the returned Source object, or an error.
    @objc(createSourceWithParams:completion:)
    public func createSource(
        with sourceParams: STPSourceParams, completion: @escaping STPSourceCompletionBlock
    ) {
        _apiClient.createSource(with: sourceParams, completion: completion)
    }
    
    /// Retrieves the Source object with the given ID. - seealso: https://stripe.com/docs/api#retrieve_source
    /// - Parameters:
    ///   - identifier:  The identifier of the source to be retrieved. Cannot be nil.
    ///   - secret:      The client secret of the source. Cannot be nil.
    ///   - completion:  The callback to run with the returned Source object, or an error.
    @objc
    public func retrieveSource(
        withId identifier: String, clientSecret secret: String,
        completion: @escaping STPSourceCompletionBlock
    ) {
        _apiClient.retrieveSource(withId: identifier, clientSecret: secret, completion: completion)
    }

    /// Starts polling the Source object with the given ID. For payment methods that require
    /// additional customer action (e.g. authorizing a payment with their bank), polling
    /// allows you to determine if the action was successful. Polling will stop and the
    /// provided callback will be called once the source's status is no longer `pending`,
    /// or if the given timeout is reached and the source is still `pending`. If polling
    /// stops due to an error, the callback will be fired with the latest retrieved
    /// source and the error.
    /// Note that if a poll is already running for a source, subsequent calls to `startPolling`
    /// with the same source ID will do nothing.
    /// - Parameters:
    ///   - identifier:  The identifier of the source to be retrieved. Cannot be nil.
    ///   - secret:      The client secret of the source. Cannot be nil.
    ///   - timeout:     The timeout for the polling operation, in seconds. Timeouts are capped at 5 minutes.
    ///   - completion:  The callback to run with the returned Source object, or an error.
    @available(iOSApplicationExtension, unavailable)
    @available(macCatalystApplicationExtension, unavailable)
    @objc
    public func startPollingSource(
        withId identifier: String, clientSecret secret: String, timeout: TimeInterval,
        completion: @escaping STPSourceCompletionBlock
    ) {
        _apiClient.startPollingSource(withId: identifier, clientSecret: secret, timeout: timeout, completion: completion)
    }

    /// Stops polling the Source object with the given ID. Note that the completion block passed to
    /// `startPolling` will not be fired when `stopPolling` is called.
    /// - Parameter identifier:  The identifier of the source to be retrieved. Cannot be nil.
    @available(iOSApplicationExtension, unavailable)
    @available(macCatalystApplicationExtension, unavailable)
    @objc
    public func stopPollingSource(withId identifier: String) {
        _apiClient.stopPollingSource(withId: identifier)
    }
    
    // MARK: Payment Intents
    
    /// Retrieves the PaymentIntent object using the given secret. - seealso: https://stripe.com/docs/api#retrieve_payment_intent
    /// - Parameters:
    ///   - secret:      The client secret of the payment intent to be retrieved. Cannot be nil.
    ///   - completion:  The callback to run with the returned PaymentIntent object, or an error.
    @objc
    public func retrievePaymentIntent(
        withClientSecret secret: String,
        completion: @escaping STPPaymentIntentCompletionBlock
    ) {
        _apiClient.retrievePaymentIntent(withClientSecret: secret, completion: completion)
    }

    /// Retrieves the PaymentIntent object using the given secret. - seealso: https://stripe.com/docs/api#retrieve_payment_intent
    /// - Parameters:
    ///   - secret:      The client secret of the payment intent to be retrieved. Cannot be nil.
    ///   - expand:  An array of string keys to expand on the returned PaymentIntent object. These strings should match one or more of the parameter names that are marked as expandable. - seealso: https://stripe.com/docs/api/payment_intents/object
    ///   - completion:  The callback to run with the returned PaymentIntent object, or an error.
    @objc
    public func retrievePaymentIntent(
        withClientSecret secret: String,
        expand: [String]?,
        completion: @escaping STPPaymentIntentCompletionBlock
    ) {
        _apiClient.retrievePaymentIntent(withClientSecret: secret, expand: expand, completion: completion)
    }
    
    /// Confirms the PaymentIntent object with the provided params object.
    /// At a minimum, the params object must include the `clientSecret`.
    /// - seealso: https://stripe.com/docs/api#confirm_payment_intent
    /// @note Use the `confirmPayment:withAuthenticationContext:completion:` method on `STPPaymentHandler` instead
    /// of calling this method directly. It handles any authentication necessary for you. - seealso: https://stripe.com/docs/mobile/ios/authentication
    /// - Parameters:
    ///   - paymentIntentParams:  The `STPPaymentIntentParams` to pass to `/confirm`
    ///   - completion:           The callback to run with the returned PaymentIntent object, or an error.
    @objc(confirmPaymentIntentWithParams:completion:) dynamic
    public func confirmPaymentIntent(
        with paymentIntentParams: STPPaymentIntentParams,
        completion: @escaping STPPaymentIntentCompletionBlock
    ) {
        _apiClient.confirmPaymentIntent(with: paymentIntentParams, completion: completion)
    }

    /// Confirms the PaymentIntent object with the provided params object.
    /// At a minimum, the params object must include the `clientSecret`.
    /// - seealso: https://stripe.com/docs/api#confirm_payment_intent
    /// @note Use the `confirmPayment:withAuthenticationContext:completion:` method on `STPPaymentHandler` instead
    /// of calling this method directly. It handles any authentication necessary for you. - seealso: https://stripe.com/docs/mobile/ios/authentication
    /// - Parameters:
    ///   - paymentIntentParams:  The `STPPaymentIntentParams` to pass to `/confirm`
    ///   - expand:  An array of string keys to expand on the returned PaymentIntent object. These strings should match one or more of the parameter names that are marked as expandable. - seealso: https://stripe.com/docs/api/payment_intents/object
    ///   - completion:           The callback to run with the returned PaymentIntent object, or an error.
    @objc(confirmPaymentIntentWithParams:expand:completion:)
    public func confirmPaymentIntent(
        with paymentIntentParams: STPPaymentIntentParams,
        expand: [String]?,
        completion: @escaping STPPaymentIntentCompletionBlock
    ) {
        _apiClient.confirmPaymentIntent(with: paymentIntentParams, expand: expand, completion: completion)
    }

    // MARK: Setup Intents
    
    /// Retrieves the SetupIntent object using the given secret. - seealso: https://stripe.com/docs/api/setup_intents/retrieve
    /// - Parameters:
    ///   - secret:      The client secret of the SetupIntent to be retrieved. Cannot be nil.
    ///   - completion:  The callback to run with the returned SetupIntent object, or an error.
    @objc
    public func retrieveSetupIntent(
        withClientSecret secret: String,
        completion: @escaping STPSetupIntentCompletionBlock
    ) {
        _apiClient.retrieveSetupIntent(withClientSecret: secret, completion: completion)
    }

    /// Confirms the SetupIntent object with the provided params object.
    /// At a minimum, the params object must include the `clientSecret`.
    /// - seealso: https://stripe.com/docs/api/setup_intents/confirm
    /// @note Use the `confirmSetupIntent:withAuthenticationContext:completion:` method on `STPPaymentHandler` instead
    /// of calling this method directly. It handles any authentication necessary for you. - seealso: https://stripe.com/docs/mobile/ios/authentication
    /// - Parameters:
    ///   - setupIntentParams:    The `STPSetupIntentConfirmParams` to pass to `/confirm`
    ///   - completion:           The callback to run with the returned PaymentIntent object, or an error.
    @objc(confirmSetupIntentWithParams:completion:) dynamic
    public func confirmSetupIntent(
        with setupIntentParams: STPSetupIntentConfirmParams,
        completion: @escaping STPSetupIntentCompletionBlock
    ) {
        _apiClient.confirmSetupIntent(with: setupIntentParams, completion: completion)
    }
    
    // MARK: Payment Methods
    
    /// Creates a PaymentMethod object with the provided params object.
    /// - seealso: https://stripe.com/docs/api/payment_methods/create
    /// - Parameters:
    ///   - paymentMethodParams:  The `STPPaymentMethodParams` to pass to `/v1/payment_methods`.  Cannot be nil.
    ///   - completion:           The callback to run with the returned PaymentMethod object, or an error.
    @objc(createPaymentMethodWithParams:completion:)
    public func createPaymentMethod(
        with paymentMethodParams: STPPaymentMethodParams,
        completion: @escaping STPPaymentMethodCompletionBlock
    ) {
        _apiClient.createPaymentMethod(with: paymentMethodParams, completion: completion)
    }
    
    // MARK: Radar
    
    /**
     Creates a Radar Session.

     - Note: See https://stripe.com/docs/radar/radar-session
     - Note: This API and the guide linked above require special permissions to use. Contact support@stripe.com.
     - Note: `StripeAPI.advancedFraudSignalsEnabled` must be `true` to use this method.
     - Note: See `STPRadarSession`

     - Parameters:
        - completion: The callback to run with the returned `STPRadarSession` (and any errors that may have occurred).
     */
    @objc public func createRadarSession(
        completion: @escaping STPRadarSessionCompletionBlock
    ) {
        _apiClient.createRadarSession(completion: completion)
    }
    
    // MARK: Apple Pay
    
    /// Converts a PKPayment object into a Stripe token using the Stripe API.
    /// - Parameters:
    ///   - payment:     The user's encrypted payment information as returned from a PKPaymentAuthorizationController. Cannot be nil.
    ///   - completion:  The callback to run with the returned Stripe token (and any errors that may have occurred).
    @objc(createTokenWithPayment:completion:)
    public func createToken(with payment: PKPayment, completion: @escaping STPTokenCompletionBlock)
    {
        _apiClient.createToken(with: payment, completion: completion)
    }

    /// Converts a PKPayment object into a Stripe source using the Stripe API.
    /// - Parameters:
    ///   - payment:     The user's encrypted payment information as returned from a PKPaymentAuthorizationController. Cannot be nil.
    ///   - completion:  The callback to run with the returned Stripe source (and any errors that may have occurred).
    @objc(createSourceWithPayment:completion:)
    public func createSource(
        with payment: PKPayment, completion: @escaping STPSourceCompletionBlock
    ) {
        _apiClient.createSource(with: payment, completion: completion)
    }

    /// Converts a PKPayment object into a Stripe Payment Method using the Stripe API.
    /// - Parameters:
    ///   - payment:     The user's encrypted payment information as returned from a PKPaymentAuthorizationController. Cannot be nil.
    ///   - completion:  The callback to run with the returned Stripe source (and any errors that may have occurred).
    @objc(createPaymentMethodWithPayment:completion:)
    public func createPaymentMethod(
        with payment: PKPayment, completion: @escaping STPPaymentMethodCompletionBlock
    ) {
        _apiClient.createPaymentMethod(with: payment, completion: completion)

    }

    /// Converts Stripe errors into the appropriate Apple Pay error, for use in `PKPaymentAuthorizationResult`.
    /// If the error can be fixed by the customer within the Apple Pay sheet, we return an NSError that can be displayed in the Apple Pay sheet.
    /// Otherwise, the original error is returned, resulting in the Apple Pay sheet being dismissed. You should display the error message to the customer afterwards.
    /// Currently, we convert billing address related errors into a PKPaymentError that helpfully points to the billing address field in the Apple Pay sheet.
    /// Note that Apple Pay should prevent most card errors (e.g. invalid CVC, expired cards) when you add a card to the wallet.
    /// - Parameter stripeError:   An error from the Stripe SDK.
    @objc public class func pkPaymentError(forStripeError stripeError: Error?) -> Error? {
        STPAPIClient.pkPaymentError(forStripeError: stripeError)
    }
}

@available(swift, deprecated: 0.0.1, renamed: "STPAPIClient")
/// :nodoc:
@_spi(STP) extension _stpobjc_STPAPIClient: STPAnalyticsProtocol {
    @_spi(STP) public static var stp_analyticsIdentifier = "objc_STPAPIClient"
}
