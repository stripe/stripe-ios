//
//  STPPaymentHandlerActionParams.swift
//  StripePayments
//
//  Created by Yuki Tokuhiro on 6/28/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import AuthenticationServices
import Foundation
@_spi(STP) import StripeCore

#if canImport(Stripe3DS2)
    import Stripe3DS2
#endif

@_spi(STP) public protocol STPPaymentHandlerActionParams: NSObject, ASWebAuthenticationPresentationContextProviding {
    var threeDS2Service: STDSThreeDS2Service? { get }
    var threeDS2Transaction: STDSTransaction? { get set }
    var authenticationContext: STPAuthenticationContext { get }
    var apiClient: STPAPIClient { get }
    var threeDSCustomizationSettings: STPThreeDSCustomizationSettings { get }
    var returnURLString: String? { get }
    var intentStripeID: String { get }
    /// Returns the payment or setup intent's next action
    func nextAction() -> STPIntentAction?
    func complete(with status: STPPaymentHandlerActionStatus, error: NSError?)
}

@_spi(STP)
public class STPPaymentHandlerPaymentIntentActionParams: NSObject, STPPaymentHandlerActionParams {
    private var serviceInitialized = false

    @_spi(STP) public let authenticationContext: STPAuthenticationContext
    @_spi(STP) public let apiClient: STPAPIClient
    @_spi(STP) public let threeDSCustomizationSettings: STPThreeDSCustomizationSettings
    @_spi(STP) public let paymentIntentCompletion:
        STPPaymentHandlerActionPaymentIntentCompletionBlock
    @_spi(STP) public let returnURLString: String?
    @_spi(STP) public var paymentIntent: STPPaymentIntent
    @_spi(STP) public var threeDS2Transaction: STDSTransaction?

    @_spi(STP) public var intentStripeID: String {
        return paymentIntent.stripeId
    }

    private var _threeDS2Service: STDSThreeDS2Service?

    @_spi(STP) public var threeDS2Service: STDSThreeDS2Service? {
        if !serviceInitialized {
            serviceInitialized = true
            _threeDS2Service = STDSThreeDS2Service()

            STDSSwiftTryCatch.try(
                {
                    let configParams = STDSConfigParameters()
                    if !self.paymentIntent.livemode {
                        configParams.addParameterNamed(
                            "kInternalStripeTestingConfigParam",
                            withValue: "Y"
                        )
                    }
                    self._threeDS2Service?.initialize(
                        withConfig: configParams,
                        locale: Locale.autoupdatingCurrent,
                        uiSettings: self.threeDSCustomizationSettings.uiCustomization
                            .uiCustomization
                    )
                },
                catch: { _ in
                    self._threeDS2Service = nil
                },
                finallyBlock: {
                }
            )
        }

        return _threeDS2Service
    }

    init(
        apiClient: STPAPIClient,
        authenticationContext: STPAuthenticationContext,
        threeDSCustomizationSettings: STPThreeDSCustomizationSettings,
        paymentIntent: STPPaymentIntent,
        returnURL returnURLString: String?,
        completion: @escaping STPPaymentHandlerActionPaymentIntentCompletionBlock
    ) {
        self.apiClient = apiClient
        self.authenticationContext = authenticationContext
        self.threeDSCustomizationSettings = threeDSCustomizationSettings
        self.returnURLString = returnURLString
        self.paymentIntent = paymentIntent
        self.paymentIntentCompletion = completion
        super.init()
    }

    @_spi(STP) public func nextAction() -> STPIntentAction? {
        return paymentIntent.nextAction
    }

    @_spi(STP) public func complete(with status: STPPaymentHandlerActionStatus, error: NSError?) {
        paymentIntentCompletion(status, paymentIntent, error)
    }

    // Translate the STPAuthenticationContext to an ASPresentationAnchor if possible
    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return authenticationContext.authenticationPresentingViewController().view.window ?? ASPresentationAnchor()
    }
}

internal class STPPaymentHandlerSetupIntentActionParams: NSObject, STPPaymentHandlerActionParams {
    private var serviceInitialized = false

    let authenticationContext: STPAuthenticationContext
    let apiClient: STPAPIClient
    let threeDSCustomizationSettings: STPThreeDSCustomizationSettings
    let setupIntentCompletion: STPPaymentHandlerActionSetupIntentCompletionBlock
    let returnURLString: String?
    var setupIntent: STPSetupIntent
    var threeDS2Transaction: STDSTransaction?

    var intentStripeID: String {
        return setupIntent.stripeID
    }

    private var _threeDS2Service: STDSThreeDS2Service?

    var threeDS2Service: STDSThreeDS2Service? {
        if !serviceInitialized {
            serviceInitialized = true
            _threeDS2Service = STDSThreeDS2Service()

            STDSSwiftTryCatch.try(
                {
                    let configParams = STDSConfigParameters()
                    if !self.setupIntent.livemode {
                        configParams.addParameterNamed(
                            "kInternalStripeTestingConfigParam",
                            withValue: "Y"
                        )
                    }
                    self._threeDS2Service?.initialize(
                        withConfig: configParams,
                        locale: Locale.autoupdatingCurrent,
                        uiSettings: self.threeDSCustomizationSettings.uiCustomization
                            .uiCustomization
                    )
                },
                catch: { _ in
                    self._threeDS2Service = nil
                },
                finallyBlock: {
                }
            )
        }

        return _threeDS2Service
    }

    init(
        apiClient: STPAPIClient,
        authenticationContext: STPAuthenticationContext,
        threeDSCustomizationSettings: STPThreeDSCustomizationSettings,
        setupIntent: STPSetupIntent,
        returnURL returnURLString: String?,
        completion: @escaping STPPaymentHandlerActionSetupIntentCompletionBlock
    ) {
        self.apiClient = apiClient
        self.authenticationContext = authenticationContext
        self.threeDSCustomizationSettings = threeDSCustomizationSettings
        self.returnURLString = returnURLString
        self.setupIntent = setupIntent
        self.setupIntentCompletion = completion
        super.init()
    }

    func nextAction() -> STPIntentAction? {
        return setupIntent.nextAction
    }

    func complete(with status: STPPaymentHandlerActionStatus, error: NSError?) {
        setupIntentCompletion(status, setupIntent, error)
    }

    // Translate the STPAuthenticationContext to an ASPresentationAnchor if possible
    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return authenticationContext.authenticationPresentingViewController().view.window ?? ASPresentationAnchor()
    }
}
