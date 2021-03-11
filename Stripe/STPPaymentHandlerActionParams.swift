//
//  STPPaymentHandlerActionParams.swift
//  Stripe
//
//  Created by Yuki Tokuhiro on 6/28/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation

#if canImport(Stripe3DS2)
    import Stripe3DS2
#endif

@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
internal protocol STPPaymentHandlerActionParams: AnyObject {
    var threeDS2Service: STDSThreeDS2Service? { get }
    var threeDS2Transaction: STDSTransaction? { get set }
    var authenticationContext: STPAuthenticationContext { get }
    var apiClient: STPAPIClient { get }
    var threeDSCustomizationSettings: STPThreeDSCustomizationSettings { get }
    var returnURLString: String? { get }
    var intentStripeID: String? { get }
    /// Returns the payment or setup intent's next action
    func nextAction() -> STPIntentAction?
    func complete(with status: STPPaymentHandlerActionStatus, error: NSError?)
}

@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
internal class STPPaymentHandlerPaymentIntentActionParams: NSObject, STPPaymentHandlerActionParams {

    private var serviceInitialized = false

    let authenticationContext: STPAuthenticationContext
    let apiClient: STPAPIClient
    let threeDSCustomizationSettings: STPThreeDSCustomizationSettings
    let paymentIntentCompletion: STPPaymentHandlerActionPaymentIntentCompletionBlock
    let returnURLString: String?
    var paymentIntent: STPPaymentIntent?
    var threeDS2Transaction: STDSTransaction?

    var intentStripeID: String? {
        return paymentIntent?.stripeId
    }

    private var _threeDS2Service: STDSThreeDS2Service?

    var threeDS2Service: STDSThreeDS2Service? {
        if !serviceInitialized {
            serviceInitialized = true
            _threeDS2Service = STDSThreeDS2Service()

            STDSSwiftTryCatch.try(
                {
                    let configParams = STDSConfigParameters()
                    if !(self.paymentIntent?.livemode ?? true) {
                        configParams.addParameterNamed(
                            "kInternalStripeTestingConfigParam", withValue: "Y")
                    }
                    self._threeDS2Service?.initialize(
                        withConfig: configParams,
                        locale: Locale.autoupdatingCurrent,
                        uiSettings: self.threeDSCustomizationSettings.uiCustomization
                            .uiCustomization)
                },
                catch: { _ in
                    self._threeDS2Service = nil
                },
                finallyBlock: {
                })
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

    func nextAction() -> STPIntentAction? {
        return paymentIntent?.nextAction
    }

    func complete(with status: STPPaymentHandlerActionStatus, error: NSError?) {
        paymentIntentCompletion(status, paymentIntent, error)
    }
}

@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
internal class STPPaymentHandlerSetupIntentActionParams: NSObject, STPPaymentHandlerActionParams {
    private var serviceInitialized = false

    let authenticationContext: STPAuthenticationContext
    let apiClient: STPAPIClient
    let threeDSCustomizationSettings: STPThreeDSCustomizationSettings
    let setupIntentCompletion: STPPaymentHandlerActionSetupIntentCompletionBlock
    let returnURLString: String?
    var setupIntent: STPSetupIntent?
    var threeDS2Transaction: STDSTransaction?

    var intentStripeID: String? {
        return setupIntent?.stripeID
    }

    private var _threeDS2Service: STDSThreeDS2Service?

    var threeDS2Service: STDSThreeDS2Service? {
        if !serviceInitialized {
            serviceInitialized = true
            _threeDS2Service = STDSThreeDS2Service()

            STDSSwiftTryCatch.try(
                {
                    let configParams = STDSConfigParameters()
                    if !(self.setupIntent?.livemode ?? true) {
                        configParams.addParameterNamed(
                            "kInternalStripeTestingConfigParam", withValue: "Y")
                    }
                    self._threeDS2Service?.initialize(
                        withConfig: configParams,
                        locale: Locale.autoupdatingCurrent,
                        uiSettings: self.threeDSCustomizationSettings.uiCustomization
                            .uiCustomization)
                },
                catch: { _ in
                    self._threeDS2Service = nil
                },
                finallyBlock: {
                })
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
        return setupIntent?.nextAction
    }

    func complete(with status: STPPaymentHandlerActionStatus, error: NSError?) {
        setupIntentCompletion(status, setupIntent, error)
    }
}
