//
//  STPAPIClient+Payments.swift
//  StripePayments
//
//  Created by Jack Flintermann on 12/18/14.
//  Copyright (c) 2014 Stripe, Inc. All rights reserved.
//

import Foundation
import PassKit
@_spi(STP) import StripeCore
import UIKit

#if canImport(Stripe3DS2)
    import Stripe3DS2
#endif

extension STPAPIClient {
    // MARK: Tokens

    func createToken(
        withParameters parameters: [String: Any],
        completion: @escaping STPTokenCompletionBlock
    ) {
        let tokenType = STPAnalyticsClient.tokenType(fromParameters: parameters)
        STPAnalyticsClient.sharedClient.logTokenCreationAttempt(
            with: _stored_configuration,
            tokenType: tokenType
        )
        let preparedParameters = Self.paramsAddingPaymentUserAgent(parameters)
        APIRequest<STPToken>.post(
            with: self,
            endpoint: APIEndpointToken,
            parameters: preparedParameters
        ) { object, _, error in
            completion(object, error)
        }
    }
}

// MARK: Bank Accounts

/// STPAPIClient extensions to create Stripe tokens from bank accounts.
extension STPAPIClient {
    /// Converts an STPBankAccount object into a Stripe token using the Stripe API.
    /// - Parameters:
    ///   - bankAccount: The user's bank account details. Cannot be nil. - seealso: https://stripe.com/docs/api#create_bank_account_token
    ///   - completion:  The callback to run with the returned Stripe token (and any errors that may have occurred).
    @objc(createTokenWithBankAccount:completion:)
    public func createToken(
        withBankAccount bankAccount: STPBankAccountParams,
        completion: @escaping STPTokenCompletionBlock
    ) {
        var params = STPFormEncoder.dictionary(forObject: bankAccount)
        STPTelemetryClient.shared.addTelemetryFields(toParams: &params)
        createToken(withParameters: params, completion: completion)
        STPTelemetryClient.shared.sendTelemetryData()
    }
}

// MARK: Personally Identifiable Information

/// STPAPIClient extensions to create Stripe tokens from a personal identification number.
extension STPAPIClient {
    /// Converts a personal identification number into a Stripe token using the Stripe API.
    /// - Parameters:
    ///   - pii: The user's personal identification number. Cannot be nil. - seealso: https://stripe.com/docs/api#create_pii_token
    ///   - completion:  The callback to run with the returned Stripe token (and any errors that may have occurred).
    @objc(createTokenWithPersonalIDNumber:completion:)
    public func createToken(
        withPersonalIDNumber pii: String,
        completion: STPTokenCompletionBlock?
    ) {
        var params: [String: Any] = [
            "pii": [
                "personal_id_number": pii,
            ],
        ]
        STPTelemetryClient.shared.addTelemetryFields(toParams: &params)
        if let completion = completion {
            createToken(withParameters: params, completion: completion)
        }
        STPTelemetryClient.shared.sendTelemetryData()
    }

    /// Converts the last 4 SSN digits into a Stripe token using the Stripe API.
    /// - Parameters:
    ///   - ssnLast4: The last 4 digits of the user's SSN. Cannot be nil.
    ///   - completion:  The callback to run with the returned Stripe token (and any errors that may have occurred).
    @objc(createTokenWithSSNLast4:completion:)
    public func createToken(
        withSSNLast4 ssnLast4: String,
        completion: @escaping STPTokenCompletionBlock
    ) {
        var params: [String: Any] = [
            "pii": [
                "ssn_last_4": ssnLast4,
            ],
        ]
        STPTelemetryClient.shared.addTelemetryFields(toParams: &params)
        createToken(withParameters: params, completion: completion)
        STPTelemetryClient.shared.sendTelemetryData()
    }
}

// MARK: Connect Accounts

/// STPAPIClient extensions for working with Connect Accounts
extension STPAPIClient {
    /// Converts an `STPConnectAccountParams` object into a Stripe token using the Stripe API.
    /// This allows the connected account to accept the Terms of Service, and/or send Legal Entity information.
    /// - Parameters:
    ///   - account: The Connect Account parameters. Cannot be nil.
    ///   - completion: The callback to run with the returned Stripe token (and any errors that may have occurred).
    @objc(createTokenWithConnectAccount:completion:)
    public func createToken(
        withConnectAccount account: STPConnectAccountParams,
        completion: STPTokenCompletionBlock?
    ) {
        var params = STPFormEncoder.dictionary(forObject: account)
        STPTelemetryClient.shared.addTelemetryFields(toParams: &params)
        if let completion = completion {
            createToken(withParameters: params, completion: completion)
        }
        STPTelemetryClient.shared.sendTelemetryData()
    }
}

// MARK: Upload

/// STPAPIClient extensions to upload files.
extension STPAPIClient {

    /// Uses the Stripe file upload API to upload an image. This can be used for
    /// identity verification and evidence disputes.
    /// - Parameters:
    ///   - image: The image to be uploaded. The maximum allowed file size is 16MB
    /// for identity documents and 5MB for evidence disputes. Cannot be nil.
    /// Your image will be automatically resized down if you pass in one that
    /// is too large
    ///   - purpose: The purpose of this file. This can be either an identifying
    /// document or an evidence dispute.
    ///   - completion: The callback to run with the returned Stripe file
    /// (and any errors that may have occurred).
    /// - seealso: https://stripe.com/docs/file-upload
    @objc(uploadImage:purpose:completion:)
    public func uploadImage(
        _ image: UIImage,
        purpose: STPFilePurpose,
        completion: STPFileCompletionBlock?
    ) {
        uploadImage(image, purpose: StripeFile.Purpose(from: purpose).rawValue) { result in
            switch result {
            case .success(let file):
                completion?(file.toSTPFile, nil)
            case .failure(let error):
                completion?(nil, error)
            }
        }
    }
}

extension StripeFile.Purpose {
    // NOTE: Avoid adding `default` to these switch statements. Instead,
    // explicitly check each case. This helps compile-time enforce that we
    // don't leave any cases out when more are added.

    init(
        from purpose: STPFilePurpose
    ) {
        switch purpose {
        case .identityDocument:
            self = .identityDocument
        case .disputeEvidence:
            self = .disputeEvidence
        case .unknown:
            self = .unparsable
        }
    }

    var toSTPFilePurpose: STPFilePurpose {
        switch self {
        case .identityDocument:
            return .identityDocument
        case .disputeEvidence:
            return .disputeEvidence
        case .identityPrivate,
            .unparsable:
            return .unknown
        }
    }
}

extension StripeFile {
    var toSTPFile: STPFile {
        return STPFile(
            fileId: id,
            created: created,
            purpose: purpose.toSTPFilePurpose,
            size: NSNumber(value: size),
            type: type
        )
    }
}

// MARK: Credit Cards

/// STPAPIClient extensions to create Stripe tokens from credit or debit cards.
extension STPAPIClient {
    /// Converts an STPCardParams object into a Stripe token using the Stripe API.
    /// - Parameters:
    ///   - cardParams:  The user's card details. Cannot be nil. - seealso: https://stripe.com/docs/api#create_card_token
    ///   - completion:  The callback to run with the returned Stripe token (and any errors that may have occurred).
    @objc(createTokenWithCard:completion:)
    public func createToken(
        withCard cardParams: STPCardParams,
        completion: @escaping STPTokenCompletionBlock
    ) {
        var params = STPFormEncoder.dictionary(forObject: cardParams)
        STPTelemetryClient.shared.addTelemetryFields(toParams: &params)
        createToken(withParameters: params, completion: completion)
        STPTelemetryClient.shared.sendTelemetryData()
    }

    /// Converts a CVC string into a Stripe token using the Stripe API.
    /// - Parameters:
    ///   - cvc:         The CVC/CVV number used to create the token. Cannot be nil.
    ///   - completion:  The callback to run with the returned Stripe token (and any errors that may have occurred).
    @objc(createTokenForCVCUpdate:completion:)
    public func createToken(forCVCUpdate cvc: String, completion: STPTokenCompletionBlock? = nil) {
        var params: [String: Any] = [
            "cvc_update": [
                "cvc": cvc,
            ],
        ]
        STPTelemetryClient.shared.addTelemetryFields(toParams: &params)
        if let completion = completion {
            createToken(withParameters: params, completion: completion)
        }
        STPTelemetryClient.shared.sendTelemetryData()
    }
}

// MARK: Sources

/// STPAPIClient extensions for working with Source objects
extension STPAPIClient {
    /// Creates a Source object using the provided details.
    /// Note: in order to create a source on a connected account, you can set your
    /// API client's `stripeAccount` property to the ID of the account.
    /// - seealso: https://stripe.com/docs/sources/connect#creating-direct-charges
    /// - Parameters:
    ///   - sourceParams: The details of the source to create. Cannot be nil. - seealso: https://stripe.com/docs/api#create_source
    ///   - completion:   The callback to run with the returned Source object, or an error.
    @objc(createSourceWithParams:completion:)
    public func createSource(
        with sourceParams: STPSourceParams,
        completion: @escaping STPSourceCompletionBlock
    ) {
        let sourceType = STPSource.string(from: sourceParams.type)
        STPAnalyticsClient.sharedClient.logSourceCreationAttempt(
            with: _stored_configuration,
            sourceType: sourceType
        )
        sourceParams.redirectMerchantName = Bundle.stp_applicationName() ?? ""
        var params = STPFormEncoder.dictionary(forObject: sourceParams)
        STPTelemetryClient.shared.addTelemetryFields(toParams: &params)
        params = Self.paramsAddingPaymentUserAgent(params)
        APIRequest<STPSource>.post(
            with: self,
            endpoint: APIEndpointSources,
            parameters: params
        ) { object, _, error in
            completion(object, error)
        }
        STPTelemetryClient.shared.sendTelemetryData()
    }

    /// Retrieves the Source object with the given ID. - seealso: https://stripe.com/docs/api#retrieve_source
    /// - Parameters:
    ///   - identifier:  The identifier of the source to be retrieved. Cannot be nil.
    ///   - secret:      The client secret of the source. Cannot be nil.
    ///   - completion:  The callback to run with the returned Source object, or an error.
    @objc(retrieveSourceWithId:clientSecret:completion:)
    public func retrieveSource(
        withId identifier: String,
        clientSecret secret: String,
        completion: @escaping STPSourceCompletionBlock
    ) {
        retrieveSource(
            withId: identifier,
            clientSecret: secret,
            responseCompletion: { object, _, error in
                completion(object, error)
            }
        )
    }

    func retrieveSource(
        withId identifier: String,
        clientSecret secret: String,
        responseCompletion completion: @escaping (STPSource?, HTTPURLResponse?, Error?) -> Void
    ) {
        let endpoint = "\(APIEndpointSources)/\(identifier)"
        let parameters = [
            "client_secret": secret,
        ]
        APIRequest<STPSource>.getWith(
            self,
            endpoint: endpoint,
            parameters: parameters,
            completion: completion
        )
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
    @objc(startPollingSourceWithId:clientSecret:timeout:completion:)
    public func startPollingSource(
        withId identifier: String,
        clientSecret secret: String,
        timeout: TimeInterval,
        completion: @escaping STPSourceCompletionBlock
    ) {
        stopPollingSource(withId: identifier)
        let poller = STPSourcePoller(
            apiClient: self,
            clientSecret: secret,
            sourceID: identifier,
            timeout: timeout,
            completion: completion
        )
        sourcePollersQueue?.async(execute: {
            self.sourcePollers?[identifier] = poller
        })
    }

    /// Stops polling the Source object with the given ID. Note that the completion block passed to
    /// `startPolling` will not be fired when `stopPolling` is called.
    /// - Parameter identifier:  The identifier of the source to be retrieved. Cannot be nil.
    @objc(stopPollingSourceWithId:)
    public func stopPollingSource(withId identifier: String) {
        sourcePollersQueue?.async(execute: {
            let poller = self.sourcePollers?[identifier] as? STPSourcePoller
            if let poller = poller {
                poller.stopPolling()
                self.sourcePollers?[identifier] = nil
            }
        })
    }
}

// MARK: Payment Intents

/// STPAPIClient extensions for working with PaymentIntent objects.
extension STPAPIClient {

    internal func paymentIntentEndpoint(from secret: String) -> String {
        if publishableKeyIsUserKey {
            assert(
                secret.hasPrefix("pi_"),
                "`secret` format does not match expected identifer formatting."
            )
            return "\(APIEndpointPaymentIntents)/\(secret)"
        } else {
            assert(
                STPPaymentIntentParams.isClientSecretValid(secret),
                "`secret` format does not match expected client secret formatting."
            )
            let identifier = STPPaymentIntent.id(fromClientSecret: secret) ?? ""
            return "\(APIEndpointPaymentIntents)/\(identifier)"
        }
    }

    /// Retrieves the PaymentIntent object using the given secret. - seealso: https://stripe.com/docs/api#retrieve_payment_intent
    /// - Parameters:
    ///   - secret:      The client secret of the payment intent to be retrieved. Cannot be nil.
    ///   - completion:  The callback to run with the returned PaymentIntent object, or an error.
    @objc(retrievePaymentIntentWithClientSecret:completion:)
    public func retrievePaymentIntent(
        withClientSecret secret: String,
        completion: @escaping STPPaymentIntentCompletionBlock
    ) {
        retrievePaymentIntent(
            withClientSecret: secret,
            expand: nil,
            completion: completion
        )
    }

    /// Retrieves the PaymentIntent object using the given secret. - seealso: https://stripe.com/docs/api#retrieve_payment_intent
    /// - Parameters:
    ///   - secret:      The client secret of the payment intent to be retrieved. Cannot be nil.
    ///   - expand:  An array of string keys to expand on the returned PaymentIntent object. These strings should match one or more of the parameter names that are marked as expandable. - seealso: https://stripe.com/docs/api/payment_intents/object
    ///   - completion:  The callback to run with the returned PaymentIntent object, or an error.
    @objc(retrievePaymentIntentWithClientSecret:expand:completion:)
    public func retrievePaymentIntent(
        withClientSecret secret: String,
        expand: [String]?,
        completion: @escaping STPPaymentIntentCompletionBlock
    ) {
        let endpoint: String = paymentIntentEndpoint(from: secret)
        var parameters: [String: Any] = [:]

        if !publishableKeyIsUserKey {
            parameters["client_secret"] = secret
        }

        if (expand?.count ?? 0) > 0 {
            parameters["expand"] = expand
        }

        APIRequest<STPPaymentIntent>.getWith(
            self,
            endpoint: endpoint,
            parameters: parameters
        ) { paymentIntent, _, error in
            completion(paymentIntent, error)
        }
    }

    /// Async helper version of `retrievePaymentIntent`
    @_spi(STP) public func retrievePaymentIntent(
        clientSecret: String,
        expand: [String] = []
    ) async throws -> STPPaymentIntent {
        return try await withCheckedThrowingContinuation { continuation in
            retrievePaymentIntent(withClientSecret: clientSecret, expand: expand) { paymentIntent, error in
                guard let paymentIntent = paymentIntent else {
                    continuation.resume(throwing: error ?? NSError.stp_genericFailedToParseResponseError())
                    return
                }
                continuation.resume(returning: paymentIntent)
            }
        }
    }

    @_spi(STP) @objc public func refreshPaymentIntent(withClientSecret secret: String,
                                                      completion: @escaping STPPaymentIntentCompletionBlock) {
        let endpoint = "\(paymentIntentEndpoint(from: secret))/refresh"
        var parameters: [String: Any] = ["expand": ["payment_method"]]

        if !publishableKeyIsUserKey {
            parameters["client_secret"] = secret
        }

        STPAnalyticsClient.sharedClient.log(analytic: GenericAnalytic(event: .refreshPaymentIntentStarted, params: [:]))
        let startDate = Date()
        APIRequest<STPPaymentIntent>.post(
            with: self,
            endpoint: endpoint,
            parameters: parameters
        ) { paymentIntent, _, error in

            if let error = error {
                let errorAnalytic = ErrorAnalytic(event: .refreshPaymentIntentFailed,
                                                  error: error,
                                                  additionalNonPIIParams: ["duration": Date().timeIntervalSince(startDate)])
                STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic)
            } else {
                STPAnalyticsClient.sharedClient.log(analytic: GenericAnalytic(event: .refreshPaymentIntentSuccess,
                                                                              params: ["duration": Date().timeIntervalSince(startDate)]))
            }

            completion(paymentIntent, error)
        }
    }

    /// Confirms the PaymentIntent object with the provided params object.
    /// At a minimum, the params object must include the `clientSecret`.
    /// - seealso: https://stripe.com/docs/api#confirm_payment_intent
    /// @note Use the `confirmPayment:withAuthenticationContext:completion:` method on `STPPaymentHandler` instead
    /// of calling this method directly. It handles any authentication necessary for you. - seealso: https://stripe.com/docs/payments/3d-secure
    /// - Parameters:
    ///   - paymentIntentParams:  The `STPPaymentIntentParams` to pass to `/confirm`
    ///   - completion:           The callback to run with the returned PaymentIntent object, or an error.
    @objc(confirmPaymentIntentWithParams:completion:)
    public func confirmPaymentIntent(
        with paymentIntentParams: STPPaymentIntentParams,
        completion: @escaping STPPaymentIntentCompletionBlock
    ) {
        confirmPaymentIntent(
            with: paymentIntentParams,
            expand: nil,
            completion: completion
        )
    }

    /// Confirms the PaymentIntent object with the provided params object.
    /// At a minimum, the params object must include the `clientSecret`.
    /// - seealso: https://stripe.com/docs/api#confirm_payment_intent
    /// @note Use the `confirmPayment:withAuthenticationContext:completion:` method on `STPPaymentHandler` instead
    /// of calling this method directly. It handles any authentication necessary for you. - seealso: https://stripe.com/docs/payments/3d-secure
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
        assert(
            STPPaymentIntentParams.isClientSecretValid(paymentIntentParams.clientSecret),
            "`paymentIntentParams.clientSecret` format does not match expected client secret formatting."
        )

        let identifier = paymentIntentParams.stripeId ?? ""
        let type =
            paymentIntentParams.paymentMethodParams?.rawTypeString
            ?? paymentIntentParams.sourceParams?.rawTypeString
        STPAnalyticsClient.sharedClient.logPaymentIntentConfirmationAttempt(
            with: _stored_configuration,
            paymentMethodType: type,
            apiClient: self
        )

        let endpoint = "\(APIEndpointPaymentIntents)/\(identifier)/confirm"

        var params = STPFormEncoder.dictionary(forObject: paymentIntentParams)
        if var sourceParamsDict = params[SourceDataHash] as? [String: Any] {
            STPTelemetryClient.shared.addTelemetryFields(toParams: &sourceParamsDict)
            sourceParamsDict = Self.paramsAddingPaymentUserAgent(sourceParamsDict)
            params[SourceDataHash] = sourceParamsDict
        }
        if var paymentMethodParamsDict = params[PaymentMethodDataHash] as? [String: Any] {
            paymentMethodParamsDict = Self.paramsAddingPaymentUserAgent(paymentMethodParamsDict)
            params[PaymentMethodDataHash] = paymentMethodParamsDict
        }
        if (expand?.count ?? 0) > 0 {
            if let expand = expand {
                params["expand"] = expand
            }
        }
        if publishableKeyIsUserKey {
            params["client_secret"] = nil
        }

        APIRequest<STPPaymentIntent>.post(
            with: self,
            endpoint: endpoint,
            parameters: params
        ) { paymentIntent, _, error in
            completion(paymentIntent, error)
        }
    }

    /// Endpoint to call to indicate that the web-based challenge flow for 3DS authentication was canceled.
    func cancel3DSAuthentication(
        forPaymentIntent paymentIntentID: String,
        withSource sourceID: String,
        publishableKeyOverride: String?,
        completion: @escaping STPPaymentIntentCompletionBlock
    ) {
        APIRequest<STPPaymentIntent>.post(
            with: self,
            endpoint: "\(APIEndpointPaymentIntents)/\(paymentIntentID)/source_cancel",
            additionalHeaders: authorizationHeader(using: publishableKeyOverride),
            parameters: [
                "source": sourceID,
            ]
        ) { paymentIntent, _, responseError in
            completion(paymentIntent, responseError)
        }
    }
}

// MARK: Setup Intents

/// STPAPIClient extensions for working with SetupIntent objects.
extension STPAPIClient {

    func setupIntentEndpoint(from secret: String) -> String {
        if publishableKeyIsUserKey {
            assert(
                secret.hasPrefix("seti_"),
                "`secret` format does not match expected identifier formatting."
            )
            let identifier = STPSetupIntent.id(fromClientSecret: secret) ?? secret
            return "\(APIEndpointSetupIntents)/\(identifier)"
        } else {
            assert(
                STPSetupIntentConfirmParams.isClientSecretValid(secret),
                "`secret` format does not match expected client secret formatting."
            )
            let identifier = STPSetupIntent.id(fromClientSecret: secret) ?? ""
            return "\(APIEndpointSetupIntents)/\(identifier)"
        }
    }

    /// Retrieves the SetupIntent object using the given secret. - seealso: https://stripe.com/docs/api/setup_intents/retrieve
    /// - Parameters:
    ///   - secret:      The client secret of the SetupIntent to be retrieved. Cannot be nil.
    ///   - completion:  The callback to run with the returned SetupIntent object, or an error.
    @objc(retrieveSetupIntentWithClientSecret:completion:)
    public func retrieveSetupIntent(
        withClientSecret secret: String,
        completion: @escaping STPSetupIntentCompletionBlock
    ) {
        retrieveSetupIntent(
            withClientSecret: secret,
            expand: nil,
            completion: completion
        )
    }

    /// Retrieves the SetupIntent object using the given secret. - seealso: https://stripe.com/docs/api/setup_intents/retrieve
    /// - Parameters:
    ///   - secret:      The client secret of the SetupIntent to be retrieved. Cannot be nil.
    ///   - expand:  An array of string keys to expand on the returned SetupIntent object. These strings should match one or more of the parameter names that are marked as expandable. - seealso: https://stripe.com/docs/api/setup_intents/object
    ///   - completion:  The callback to run with the returned SetupIntent object, or an error.
    @objc(retrieveSetupIntentWithClientSecret:expand:completion:)
    public func retrieveSetupIntent(
        withClientSecret secret: String,
        expand: [String]?,
        completion: @escaping STPSetupIntentCompletionBlock
    ) {

        let endpoint = setupIntentEndpoint(from: secret)
        var parameters: [String: Any] = [:]
        if !publishableKeyIsUserKey {
            parameters["client_secret"] = secret
        }
        if let expand = expand,
            !expand.isEmpty
        {
            parameters["expand"] = expand
        }

        APIRequest<STPSetupIntent>.getWith(
            self,
            endpoint: endpoint,
            parameters: parameters
        ) { setupIntent, _, error in
            completion(setupIntent, error)
        }
    }

    /// Async helper version of `retrieveSetupIntent`
    @_spi(STP) public func retrieveSetupIntent(
        clientSecret: String,
        expand: [String] = []
    ) async throws -> STPSetupIntent {
        return try await withCheckedThrowingContinuation { continuation in
            retrieveSetupIntent(withClientSecret: clientSecret, expand: expand) { setupIntent, error in
                guard let setupIntent = setupIntent else {
                    continuation.resume(throwing: error ?? NSError.stp_genericFailedToParseResponseError())
                    return
                }
                continuation.resume(returning: setupIntent)
            }
        }
    }

    /// Confirms the SetupIntent object with the provided params object.
    /// At a minimum, the params object must include the `clientSecret`.
    /// - seealso: https://stripe.com/docs/api/setup_intents/confirm
    /// @note Use the `confirmSetupIntent:withAuthenticationContext:completion:` method on `STPPaymentHandler` instead
    /// of calling this method directly. It handles any authentication necessary for you. - seealso: https://stripe.com/docs/payments/3d-secure
    /// - Parameters:
    ///   - setupIntentParams:    The `STPSetupIntentConfirmParams` to pass to `/confirm`
    ///   - completion:           The callback to run with the returned PaymentIntent object, or an error.
    @objc(confirmSetupIntentWithParams:completion:)
    public func confirmSetupIntent(
        with setupIntentParams: STPSetupIntentConfirmParams,
        completion: @escaping STPSetupIntentCompletionBlock
    ) {
        confirmSetupIntent(
            with: setupIntentParams,
            expand: nil,
            completion: completion
        )
    }

    /// Confirms the SetupIntent object with the provided params object.
    /// At a minimum, the params object must include the `clientSecret`.
    /// - seealso: https://stripe.com/docs/api/setup_intents/confirm
    /// @note Use the `confirmSetupIntent:withAuthenticationContext:completion:` method on `STPPaymentHandler` instead
    /// of calling this method directly. It handles any authentication necessary for you. - seealso: https://stripe.com/docs/mobile/ios/authentication
    /// - Parameters:
    ///   - setupIntentParams:    The `STPSetupIntentConfirmParams` to pass to `/confirm`
    ///   - expand:  An array of string keys to expand on the returned SetupIntent object. These strings should match one or more of the parameter names that are marked as expandable. - seealso: https://stripe.com/docs/api/setup_intents/object
    ///   - completion:           The callback to run with the returned PaymentIntent object, or an error.
    @objc(confirmSetupIntentWithParams:expand:completion:)
    public func confirmSetupIntent(
        with setupIntentParams: STPSetupIntentConfirmParams,
        expand: [String]?,
        completion: @escaping STPSetupIntentCompletionBlock
    ) {
        assert(
            STPSetupIntentConfirmParams.isClientSecretValid(setupIntentParams.clientSecret),
            "`setupIntentParams.clientSecret` format does not match expected client secret formatting."
        )

        STPAnalyticsClient.sharedClient.logSetupIntentConfirmationAttempt(
            with: _stored_configuration,
            paymentMethodType: setupIntentParams.paymentMethodParams?.rawTypeString,
            apiClient: self
        )

        let endpoint = setupIntentEndpoint(from: setupIntentParams.clientSecret) + "/confirm"
        var params = STPFormEncoder.dictionary(forObject: setupIntentParams)
        if var sourceParamsDict = params[SourceDataHash] as? [String: Any] {
            STPTelemetryClient.shared.addTelemetryFields(toParams: &sourceParamsDict)
            sourceParamsDict = Self.paramsAddingPaymentUserAgent(sourceParamsDict)
            params[SourceDataHash] = sourceParamsDict
        }
        if var paymentMethodParamsDict = params[PaymentMethodDataHash] as? [String: Any] {
            paymentMethodParamsDict = Self.paramsAddingPaymentUserAgent(paymentMethodParamsDict)
            params[PaymentMethodDataHash] = paymentMethodParamsDict
        }
        if let expand = expand,
            !expand.isEmpty
        {
            params["expand"] = expand
        }
        if publishableKeyIsUserKey {
            params["client_secret"] = nil
        }

        APIRequest<STPSetupIntent>.post(
            with: self,
            endpoint: endpoint,
            parameters: params
        ) { setupIntent, _, error in
            completion(setupIntent, error)
        }
    }

    func cancel3DSAuthentication(
        forSetupIntent setupIntentID: String,
        withSource sourceID: String,
        publishableKeyOverride: String?,
        completion: @escaping STPSetupIntentCompletionBlock
    ) {
        APIRequest<STPSetupIntent>.post(
            with: self,
            endpoint: "\(APIEndpointSetupIntents)/\(setupIntentID)/source_cancel",
            additionalHeaders: authorizationHeader(using: publishableKeyOverride),
            parameters: [
                "source": sourceID,
            ]
        ) { setupIntent, _, responseError in
            completion(setupIntent, responseError)
        }
    }

    @_spi(STP) @objc public func refreshSetupIntent(withClientSecret secret: String,
                                                    completion: @escaping STPSetupIntentCompletionBlock) {
        let endpoint = "\(setupIntentEndpoint(from: secret))/refresh"
        var parameters: [String: Any] = ["expand": ["payment_method"]]

        if !publishableKeyIsUserKey {
            parameters["client_secret"] = secret
        }

        STPAnalyticsClient.sharedClient.log(analytic: GenericAnalytic(event: .refreshSetupIntentStarted, params: [:]))
        let startDate = Date()
        APIRequest<STPSetupIntent>.post(
            with: self,
            endpoint: endpoint,
            parameters: parameters
        ) { setupIntent, _, error in
            if let error = error {
                let errorAnalytic = ErrorAnalytic(event: .refreshSetupIntentFailed,
                                                  error: error,
                                                  additionalNonPIIParams: ["duration": Date().timeIntervalSince(startDate)])
                STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic)
            } else {
                STPAnalyticsClient.sharedClient.log(analytic: GenericAnalytic(event: .refreshSetupIntentSuccess,
                                                                              params: ["duration": Date().timeIntervalSince(startDate)]))
            }

            completion(setupIntent, error)
        }
    }
}

// MARK: Payment Methods

/// STPAPIClient extensions for working with PaymentMethod objects.
extension STPAPIClient {
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
        createPaymentMethod(with: paymentMethodParams, additionalPaymentUserAgentValues: [], completion: completion)
    }

    /// - Parameter additionalPaymentUserAgentValues: A list of values to append to the `payment_user_agent` parameter sent in the request. e.g. `["deferred-intent", "autopm"]` will append "; deferred-intent; autopm" to the `payment_user_agent`.
    func createPaymentMethod(
        with paymentMethodParams: STPPaymentMethodParams,
        additionalPaymentUserAgentValues: [String] = [],
        completion: @escaping STPPaymentMethodCompletionBlock
    ) {
        STPAnalyticsClient.sharedClient.logPaymentMethodCreationAttempt(
            with: _stored_configuration,
            paymentMethodType: paymentMethodParams.rawTypeString,
            apiClient: self
        )
        var parameters = STPFormEncoder.dictionary(forObject: paymentMethodParams)
        parameters = Self.paramsAddingPaymentUserAgent(parameters, additionalValues: additionalPaymentUserAgentValues)
        APIRequest<STPPaymentMethod>.post(
            with: self,
            endpoint: APIEndpointPaymentMethods,
            parameters: parameters
        ) { paymentMethod, _, error in
            completion(paymentMethod, error)
        }
    }

    /// Creates a PaymentMethod object with the provided params object.
    /// - seealso: https://stripe.com/docs/api/payment_methods/create
    /// - Parameters:
    ///   - paymentMethodParams:  The `STPPaymentMethodParams` to pass to `/v1/payment_methods`.  Cannot be nil.
    ///   - additionalPaymentUserAgentValues:  A list of values to append to the `payment_user_agent` parameter sent in the request. e.g. `["deferred-intent", "autopm"]` will append "; deferred-intent; autopm" to the `payment_user_agent`.
    /// - Returns: the returned PaymentMethod object.
    public func createPaymentMethod(with paymentMethodParams: STPPaymentMethodParams, additionalPaymentUserAgentValues: [String]) async throws -> STPPaymentMethod {
        return try await withCheckedThrowingContinuation({ continuation in
            createPaymentMethod(with: paymentMethodParams, additionalPaymentUserAgentValues: additionalPaymentUserAgentValues) { paymentMethod, error in
                if let paymentMethod = paymentMethod {
                    continuation.resume(with: .success(paymentMethod))
                } else {
                    continuation.resume(with: .failure(error ?? NSError.stp_genericFailedToParseResponseError()))
                }
            }
        })
    }

    /// Updates a PaymentMethod object with the provided params object.
    /// - seealso: https://stripe.com/docs/api/payment_methods/update
    /// - Parameters:
    ///   - paymentMethodId: Identifier of the payment method to be updated
    ///   - paymentMethodUpdateParams: The `STPPaymentMethodUpdateParams` to pass to `/v1/payment_methods/update`.  Cannot be nil.
    ///   - ephemeralKeySecret: The Customer Ephemeral Key secret to be used
    ///   - completion: The callback to run with the returned `STPPaymentMethod` object, or an error.
    public func updatePaymentMethod(with paymentMethodId: String,
                                    paymentMethodUpdateParams: STPPaymentMethodUpdateParams,
                                    ephemeralKeySecret: String,
                                    completion: @escaping STPPaymentMethodCompletionBlock) {
        STPAnalyticsClient.sharedClient.logPaymentMethodUpdateAttempt(
            with: _stored_configuration
        )

        let parameters = STPFormEncoder.dictionary(forObject: paymentMethodUpdateParams)
        APIRequest<STPPaymentMethod>.post(
            with: self,
            endpoint: "\(APIEndpointPaymentMethods)/\(paymentMethodId)",
            additionalHeaders: authorizationHeader(using: ephemeralKeySecret),
            parameters: parameters
        ) { paymentMethod, _, error in
            completion(paymentMethod, error)
        }
    }

    /// Updates a PaymentMethod object with the provided params object.
    /// - seealso: https://stripe.com/docs/api/payment_methods/update
    /// - Parameters:
    ///   - paymentMethodId: Identifier of the payment method to be updated
    ///   - paymentMethodUpdateParams: The `STPPaymentMethodUpdateParams` to pass to `/v1/payment_methods/update`.  Cannot be nil.
    ///   - ephemeralKeySecret: The Customer Ephemeral Key secret to be used
    /// - Returns: Returns the updated `STPPaymentMethod` or throws an error if the operation failed.
    public func updatePaymentMethod(with paymentMethodId: String,
                                    paymentMethodUpdateParams: STPPaymentMethodUpdateParams,
                                    ephemeralKeySecret: String) async throws -> STPPaymentMethod {
        return try await withCheckedThrowingContinuation({ continuation in
            updatePaymentMethod(with: paymentMethodId, paymentMethodUpdateParams: paymentMethodUpdateParams, ephemeralKeySecret: ephemeralKeySecret) { paymentMethod, error in
                if let paymentMethod = paymentMethod {
                    continuation.resume(with: .success(paymentMethod))
                } else {
                    continuation.resume(with: .failure(error ?? NSError.stp_genericFailedToParseResponseError()))
                }
            }
        })
    }
}

// MARK: - ThreeDS2
extension STPAPIClient {
    /// Kicks off 3DS2 authentication.
    func authenticate3DS2(
        _ authRequestParams: STDSAuthenticationRequestParameters,
        sourceIdentifier sourceID: String,
        returnURL returnURLString: String?,
        maxTimeout: Int,
        publishableKeyOverride: String?,
        completion: @escaping STP3DS2AuthenticateCompletionBlock
    ) {
        let endpoint = "\(APIEndpoint3DS2)/authenticate"

        var appParams = STDSJSONEncoder.dictionary(forObject: authRequestParams)
        appParams["deviceRenderOptions"] = [
            "sdkInterface": "03",
            "sdkUiType": ["01", "02", "03", "04", "05"],
        ] as [String: Any]
        appParams["sdkMaxTimeout"] = String(format: "%02ld", maxTimeout)
        let appData = try? JSONSerialization.data(
            withJSONObject: appParams,
            options: .prettyPrinted
        )

        var params = [
            "app": String(decoding: appData ?? Data(), as: UTF8.self),
            "source": sourceID,
        ]
        if let returnURLString = returnURLString {
            params["fallback_return_url"] = returnURLString
        }

        APIRequest<STP3DS2AuthenticateResponse>.post(
            with: self,
            endpoint: endpoint,
            additionalHeaders: authorizationHeader(using: publishableKeyOverride),
            parameters: params
        ) { authenticateResponse, _, error in
            completion(authenticateResponse, error)
        }
    }

    /// Endpoint to call to indicate that the challenge flow for a 3DS2 authentication has finished.
    func complete3DS2Authentication(
        forSource sourceID: String,
        publishableKeyOverride: String?,
        completion: @escaping STPBooleanSuccessBlock
    ) {
        APIRequest<STPEmptyStripeResponse>.post(
            with: self,
            endpoint: "\(APIEndpoint3DS2)/challenge_complete",
            additionalHeaders: authorizationHeader(using: publishableKeyOverride),
            parameters: [
                "source": sourceID,
            ]
        ) { _, response, responseError in
            completion(response?.statusCode == 200, responseError)
        }
    }
}

// MARK: - US Bank Account
extension STPAPIClient {

    /// Verify a customer's bank account with micro-deposits
    /// This function should only be called when the PaymentIntent is in the `requires_action`
    /// state and `next_action.type` equals `verify_with_microdeposits`
    /// - Parameters:
    ///   - clientSecret: The client secret of the PaymentIntent.
    ///   - firstAmount: The amount, in cents of USD, equal to the value of the first micro-deposit sent to the bank account.
    ///   - secondAmount: The amount, in cents of USD, equal to the value of the second micro-deposit sent to the bank account.
    ///   - completion: The callback to run with the returned PaymentIntent object, or an error.
    public func verifyPaymentIntentWithMicrodeposits(
        clientSecret: String,
        firstAmount: Int,
        secondAmount: Int,
        completion: @escaping STPPaymentIntentCompletionBlock
    ) {
        verifyIntentWithMicrodeposits(
            clientSecret: clientSecret,
            firstAmount: firstAmount,
            secondAmount: secondAmount,
            completion: completion
        )
    }

    /// Verify a customer's bank account with micro-deposits
    /// This function should only be called when the PaymentIntent is in the `requires_action`
    /// state and `next_action.type` equals `verify_with_microdeposits`
    /// - Parameters:
    ///   - clientSecret: The client secret of the PaymentIntent.
    ///   - descriptorCode: a unique, 6-digit descriptor code that starts with SM that was sent as statement descriptor to the bank account.
    ///   - completion: The callback to run with the returned PaymentIntent object, or an error.
    public func verifyPaymentIntentWithMicrodeposits(
        clientSecret: String,
        descriptorCode: String,
        completion: @escaping STPPaymentIntentCompletionBlock
    ) {

        verifyIntentWithMicrodeposits(
            clientSecret: clientSecret,
            descriptorCode: descriptorCode,
            completion: completion
        )
    }

    /// Verify a customer's bank account with micro-deposits
    /// This function should only be called when the SetupIntent is in the `requires_action`
    /// state and `next_action.type` equals `verify_with_microdeposits`
    /// - Parameters:
    ///   - clientSecret: The client secret of the SetupIntent.
    ///   - firstAmount: The amount, in cents of USD, equal to the value of the first micro-deposit sent to the bank account.
    ///   - secondAmount: The amount, in cents of USD, equal to the value of the second micro-deposit sent to the bank account.
    ///   - completion: The callback to run with the returned SetupIntent object, or an error.
    public func verifySetupIntentWithMicrodeposits(
        clientSecret: String,
        firstAmount: Int,
        secondAmount: Int,
        completion: @escaping STPSetupIntentCompletionBlock
    ) {

        verifyIntentWithMicrodeposits(
            clientSecret: clientSecret,
            firstAmount: firstAmount,
            secondAmount: secondAmount,
            completion: completion
        )
    }

    /// Verify a customer's bank account with micro-deposits
    /// This function should only be called when the PaymentIntent is in the `requires_action`
    /// state and `next_action.type` equals `verify_with_microdeposits`
    /// - Parameters:
    ///   - clientSecret: The client secret of the SetupIntent.
    ///   - descriptorCode: a unique, 6-digit descriptor code that starts with SM that was sent as statement descriptor to the bank account.
    ///   - completion: The callback to run with the returned SetupIntent object, or an error.
    public func verifySetupIntentWithMicrodeposits(
        clientSecret: String,
        descriptorCode: String,
        completion: @escaping STPSetupIntentCompletionBlock
    ) {
        verifyIntentWithMicrodeposits(
            clientSecret: clientSecret,
            descriptorCode: descriptorCode,
            completion: completion
        )
    }

    // Internal helpers

    func verifyIntentWithMicrodeposits<T: STPAPIResponseDecodable>(
        clientSecret: String,
        firstAmount: Int,
        secondAmount: Int,
        completion: @escaping (T?, Error?) -> Void
    ) {
        verifyIntentWithMicrodeposits(
            clientSecret: clientSecret,
            verificationKey: "amounts",
            verificationData: [firstAmount, secondAmount],
            completion: completion
        )
    }

    func verifyIntentWithMicrodeposits<T: STPAPIResponseDecodable>(
        clientSecret: String,
        descriptorCode: String,
        completion: @escaping (T?, Error?) -> Void
    ) {
        verifyIntentWithMicrodeposits(
            clientSecret: clientSecret,
            verificationKey: "descriptor_code",
            verificationData: descriptorCode,
            completion: completion
        )
    }

    func verifyIntentWithMicrodeposits<T: STPAPIResponseDecodable>(
        clientSecret: String,
        verificationKey: String,
        verificationData: Any,
        completion: @escaping (T?, Error?) -> Void
    ) {
        var endpoint: String
        if T.self is STPPaymentIntent.Type {
            endpoint = paymentIntentEndpoint(from: clientSecret)
        } else if T.self is STPSetupIntent.Type {
            endpoint = setupIntentEndpoint(from: clientSecret)
        } else {
            assertionFailure("Don't call verifyIntentWithMicrodeposits for a non Intent object")
            return
        }

        endpoint += "/verify_microdeposits"

        let parameters: [String: Any] = [
            "client_secret": clientSecret,
            verificationKey: verificationData,
        ]

        APIRequest<T>.post(
            with: self,
            endpoint: endpoint,
            parameters: parameters
        ) { intent, _, error in
            completion(intent, error)
        }
    }
}

extension STPAPIClient {
    @_spi(STP) public func listPaymentMethods(
        forCustomer customerID: String,
        using ephemeralKeySecret: String,
        types: [STPPaymentMethodType] = [.card],
        limit: Int? = nil,
        completion: @escaping STPPaymentMethodsCompletionBlock
    ) {
        let header = authorizationHeader(using: ephemeralKeySecret)
        // Unfortunately, this API only supports fetching saved pms for one type at a time
        // Update 05/04/23: The API *does* now support fetching all PM types at once,
        // but we're not using it because of pagination limitations.
        // As an example, some unsupported PMs (such as SEPA) are saved once per payment,
        // so a user with hundreds of SEPA payment methods would be stuck waiting for
        // tens of requests.
        var shared_allPaymentMethods = [STPPaymentMethod]()
        var shared_lastError: Error?
        let group = DispatchGroup()

        for type in types {
            group.enter()
            var params: [String: Any?] = [
                "customer": customerID,
                "type": STPPaymentMethod.string(from: type),
            ]
            if let limit {
                params["limit"] = limit
            }
            APIRequest<STPPaymentMethodListDeserializer>.getWith(
                self,
                endpoint: APIEndpointPaymentMethods,
                additionalHeaders: header,
                parameters: params as [String: Any]
            ) { deserializer, _, error in
                DispatchQueue.global(qos: .userInteractive).async(flags: .barrier) {
                    // .barrier ensures we're the only thing writing to shared_ vars
                    if let error = error {
                        shared_lastError = error
                    }
                    if let paymentMethods = deserializer?.paymentMethods {
                        // For unknown reasons, `append(contentsOf:` here sometimes causes an EXC_BAD_INSTRUCTION if you repeatedly run tests
                        paymentMethods.forEach { shared_allPaymentMethods.append($0) }
                    }
                    group.leave()
                }
            }
        }

        group.notify(queue: DispatchQueue.main) {
            // Once all parallel requests are finished, sort the array w/ newest first
            shared_allPaymentMethods.sort { a, b in
                guard let aCreated = a.created, let bCreated = b.created else { return true }
                return aCreated > bCreated
            }
            completion(shared_allPaymentMethods, shared_lastError)
        }
    }

    // TODO: Remove this logic when we stand up an endpoint to do this
    @_spi(STP) public func detachPaymentMethodRemoveDuplicates(
        _ paymentMethodID: String,
        customerId: String,
        fromCustomerUsing ephemeralKeySecret: String,
        withCustomerSessionClientSecret customerSessionClientSecret: String,
        completion: @escaping STPErrorBlock
    ) {
        let fetchPaymentMethods: (String) async throws -> [STPPaymentMethod] = { customerId in
            try await withCheckedThrowingContinuation { continuation in
                self.listPaymentMethods(forCustomer: customerId,
                                        using: ephemeralKeySecret,
                                        types: [.card]) { paymentMethods, error in
                    guard let paymentMethods, error == nil else {
                        let error = error ?? NSError.stp_genericFailedToParseResponseError()
                        continuation.resume(throwing: error)
                        return
                    }
                    continuation.resume(returning: paymentMethods)
                }
            }
        }
        let detachPaymentMethod: (String) async throws -> Void = { paymentMethodID in
            try await withCheckedThrowingContinuation { continuation in
                let endpoint = "\(APIEndpointElementsPaymentMethods)/\(paymentMethodID)/detach"
                APIRequest<STPPaymentMethod>.post(
                    with: self,
                    endpoint: endpoint,
                    additionalHeaders: self.authorizationHeader(using: ephemeralKeySecret),
                    parameters: ["customer_session_client_secret": customerSessionClientSecret]
                ) { _, _, error in
                    if let error {
                        continuation.resume(throwing: error)
                        return
                    }
                    continuation.resume()
                }
            }
        }
        let detachMultiplePaymentMethods: ([STPPaymentMethod]) async -> Error? = { allPaymentMethodsToDelete in
            var errors: [Error] = []
            await withTaskGroup(of: (Error?).self) { group in
                for paymentMethod in allPaymentMethodsToDelete {
                    group.addTask {
                        do {
                            try await detachPaymentMethod(paymentMethod.stripeId)
                        } catch {
                            return error
                        }
                        return nil
                    }
                }
                for await error in group {
                    if let error {
                        errors.append(error)
                    }
                }
            }
            if errors.isEmpty {
                return nil
            } else {
                // There could be more than on errors. For simplicity, throw the first one encoutered
                return errors.first
            }
        }

        Task {
            do {
                let allCardPaymentMethods = try await fetchPaymentMethods(customerId)
                let requestedPMToDelete = allCardPaymentMethods.filter({ $0.stripeId == paymentMethodID }).first
                guard let requestedPMToDelete else {
                    // Payment method doesnt exist anymore, nothing to do
                    completion(nil)
                    return
                }
                let allPaymentMethodsToDelete: [STPPaymentMethod] = allCardPaymentMethods
                    .filter({ $0.type == .card })
                    .filter({ $0.card?.fingerprint == requestedPMToDelete.card?.fingerprint })
                let error = await detachMultiplePaymentMethods(allPaymentMethodsToDelete)
                completion(error)
            } catch {
                completion(error)
            }
        }
    }

    // TODO: Remove this logic when we stand up an endpoint to do this
    @_spi(STP) public func detachPaymentMethodRemoveDuplicates(
        _ paymentMethodID: String,
        customerId: String,
        fromCustomerUsing ephemeralKeySecret: String,
        withCustomerSessionClientSecret customerSessionClientSecret: String
    ) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            detachPaymentMethodRemoveDuplicates(paymentMethodID,
                                                customerId: customerId,
                                                fromCustomerUsing: ephemeralKeySecret,
                                                withCustomerSessionClientSecret: customerSessionClientSecret) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    @_spi(STP) public func detachPaymentMethod(
        _ paymentMethodID: String,
        fromCustomerUsing ephemeralKeySecret: String,
        withCustomerSessionClientSecret customerSessionClientSecret: String,
        completion: @escaping STPErrorBlock
    ) {
        let endpoint = "\(APIEndpointElementsPaymentMethods)/\(paymentMethodID)/detach"
        APIRequest<STPPaymentMethod>.post(
            with: self,
            endpoint: endpoint,
            additionalHeaders: authorizationHeader(using: ephemeralKeySecret),
            parameters: ["customer_session_client_secret": customerSessionClientSecret]
        ) { _, _, error in
            completion(error)
        }
    }
    @_spi(STP) public func detachPaymentMethod(
        _ paymentMethodID: String,
        fromCustomerUsing ephemeralKeySecret: String,
        withCustomerSessionClientSecret customerSessionClientSecret: String
    ) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            detachPaymentMethod(paymentMethodID, fromCustomerUsing: ephemeralKeySecret, withCustomerSessionClientSecret: customerSessionClientSecret) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    @_spi(STP) public func detachPaymentMethod(
        _ paymentMethodID: String,
        fromCustomerUsing ephemeralKeySecret: String,
        completion: @escaping STPErrorBlock
    ) {
        let endpoint = "\(APIEndpointPaymentMethods)/\(paymentMethodID)/detach"
        APIRequest<STPPaymentMethod>.post(
            with: self,
            endpoint: endpoint,
            additionalHeaders: authorizationHeader(using: ephemeralKeySecret),
            parameters: [:]
        ) { _, _, error in
            completion(error)
        }
    }

    @_spi(STP) public func detachPaymentMethod(
        _ paymentMethodID: String,
        fromCustomerUsing ephemeralKeySecret: String
    ) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            detachPaymentMethod(paymentMethodID, fromCustomerUsing: ephemeralKeySecret) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    @_spi(STP) public func attachPaymentMethod(
        _ paymentMethodID: String,
        customerID: String,
        ephemeralKeySecret: String,
        completion: @escaping STPErrorBlock
    ) {
        let endpoint = "\(APIEndpointPaymentMethods)/\(paymentMethodID)/attach"
        APIRequest<STPPaymentMethod>.post(
            with: self,
            endpoint: endpoint,
            additionalHeaders: authorizationHeader(using: ephemeralKeySecret),
            parameters: [
                "customer": customerID,
            ]
        ) { _, _, error in
            completion(error)
        }
    }

    @_spi(STP) public func attachPaymentMethod(
        _ paymentMethodID: String,
        customerID: String,
        ephemeralKeySecret: String) async throws {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                attachPaymentMethod(paymentMethodID, customerID: customerID, ephemeralKeySecret: ephemeralKeySecret) { error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }
    }

    /// Retrieve a customer
    /// - seealso: https://stripe.com/docs/api#retrieve_customer
    @_spi(STP) public func retrieveCustomer(
        _ customerID: String,
        using ephemeralKey: String,
        completion: @escaping STPCustomerCompletionBlock
    ) {
        let endpoint = "\(APIEndpointCustomers)/\(customerID)"
        APIRequest<STPCustomer>.getWith(
            self,
            endpoint: endpoint,
            additionalHeaders: authorizationHeader(using: ephemeralKey),
            parameters: [:]
        ) { object, _, error in
            completion(object, error)
        }
    }

    /// Retrieve a customer
    /// - seealso: https://stripe.com/docs/api#retrieve_customer
    @_spi(STP) public func retrieveCustomer(
        _ customerID: String,
        using ephemeralKey: String
    ) async throws -> STPCustomer {
        try await withCheckedThrowingContinuation({ continuation in
            self.retrieveCustomer(customerID, using: ephemeralKey) { customer, error in
                guard let customer = customer else {
                    continuation.resume(throwing: error ?? NSError.stp_genericConnectionError())
                    return
                }
                continuation.resume(returning: customer)
            }
        })
    }

    /// Sets a payment method as the default payment method for a customer.
    /// - Parameters:
    ///   - paymentMethodID: Identifier of the payment method to be set as default
    ///   - customerID: Identifier of the customer whose default payment method is being set
    ///   - ephemeralKey: The Customer Ephemeral Key secret to be used
    ///   - completion: The callback to run with the returned `STPCustomer` object, or an error.
    @_spi(STP) public func setAsDefaultPaymentMethod(
        _ paymentMethodID: String,
        for customerID: String,
        using ephemeralKey: String,
        completion: @escaping STPCustomerCompletionBlock
    ) {
        APIRequest<STPCustomer>.post(
            with: self,
            endpoint: "\(APIEndpointElementsCustomers)/\(customerID)/set_default_payment_method",
            additionalHeaders: authorizationHeader(using: ephemeralKey),
            parameters: [
                "payment_method": paymentMethodID
            ]
        ) { customer, _, error in
            completion(customer, error)
        }
    }

    /// Sets a payment method as the default payment method for a customer.
    /// - Parameters:
    ///   - paymentMethodID: Identifier of the payment method to be set as default
    ///   - customerID: Identifier of the customer whose default payment method is being set
    ///   - ephemeralKey: The Customer Ephemeral Key secret to be used
    /// - Returns: Returns the updated `STPCustomer` or throws an error if the operation failed.
    @_spi(STP) public func setAsDefaultPaymentMethod(
        _ paymentMethodID: String,
        for customerID: String,
        using ephemeralKey: String
    ) async throws -> STPCustomer {
        try await withCheckedThrowingContinuation({ continuation in
            self.setAsDefaultPaymentMethod(paymentMethodID, for: customerID, using: ephemeralKey) { customer, error in
                guard let customer = customer else {
                    continuation.resume(throwing: error ?? NSError.stp_defaultPaymentMethodNotUpdatedError())
                    return
                }
                continuation.resume(returning: customer)
            }
        })
    }
}

private let APIEndpointToken = "tokens"
private let APIEndpointSources = "sources"
@_spi(STP) public let APIEndpointCustomers = "customers"
private let APIEndpointPaymentIntents = "payment_intents"
private let APIEndpointSetupIntents = "setup_intents"
@_spi(STP) public let APIEndpointPaymentMethods = "payment_methods"
private let APIEndpointElementsCustomers = "elements/customers"
private let APIEndpointElementsPaymentMethods = "elements/payment_methods"
private let APIEndpoint3DS2 = "3ds2"
private let PaymentMethodDataHash = "payment_method_data"
private let SourceDataHash = "source_data"
