//
//  PaymentSheet+API.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 12/10/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeApplePay
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore
import SwiftUI
import UIKit

extension PaymentSheet {
    static var _preconfirmShim: ((UIViewController) -> Void)?

    enum IntegrationShape {
        case complete
        case flowController
        case embedded

        var requiresInterstitialForCVC: Bool {
            switch self {
            case .complete:
                return false
            case .flowController, .embedded:
                return true
            }
        }
    }

    /// Confirms a PaymentIntent with the given PaymentOption and returns a PaymentResult
    static func confirm(
        configuration: PaymentElementConfiguration,
        authenticationContext: STPAuthenticationContext,
        intent: Intent,
        elementsSession: STPElementsSession,
        paymentOption: PaymentOption,
        paymentHandler: STPPaymentHandler,
        integrationShape: IntegrationShape = .complete,
        paymentMethodID: String? = nil,
        analyticsHelper: PaymentSheetAnalyticsHelper,
        completion: @escaping (PaymentSheetResult, STPAnalyticsClient.DeferredIntentConfirmationType?) -> Void
    ) {
        // Perform PaymentSheet-specific local actions before confirming.
        // These actions are not represented in the PaymentIntent state and are specific to
        // Payment Element (not the API bindings), so we need to handle them here.
        // First, handle any client-side required actions:
        if case let .new(confirmParams) = paymentOption,
           confirmParams.paymentMethodType == .stripe(.bacsDebit) {
            // MARK: - Bacs Debit
            // Display the Bacs Debit mandate view
            let mandateView = BacsDDMandateView(email: confirmParams.paymentMethodParams.billingDetails?.email ?? "",
                                                name: confirmParams.paymentMethodParams.billingDetails?.name ?? "",
                                                sortCode: confirmParams.paymentMethodParams.bacsDebit?.sortCode ?? "",
                                                accountNumber: confirmParams.paymentMethodParams.bacsDebit?.accountNumber ?? "",
                                                confirmAction: {
                // If confirmed, dismiss the MandateView and complete the transaction:
                authenticationContext.authenticationPresentingViewController().dismiss(animated: true)
                confirmAfterHandlingLocalActions(configuration: configuration, authenticationContext: authenticationContext, intent: intent, elementsSession: elementsSession, paymentOption: paymentOption, intentConfirmParamsForDeferredIntent: nil, paymentHandler: paymentHandler, analyticsHelper: analyticsHelper, completion: completion)
            }, cancelAction: {
                // Dismiss the MandateView and return to PaymentSheet
                authenticationContext.authenticationPresentingViewController().dismiss(animated: true)
                completion(.canceled, nil)
            })

            let hostingController = UIHostingController(rootView: mandateView)
            hostingController.isModalInPresentation = true
            authenticationContext.authenticationPresentingViewController().present(hostingController, animated: true)
            _preconfirmShim?(hostingController)
        } else if case let .saved(paymentMethod, _) = paymentOption,
                  paymentMethod.type == .card,
                  integrationShape.requiresInterstitialForCVC,
                  intent.cvcRecollectionEnabled {
            // MARK: - CVC Recollection
            let presentingViewController = authenticationContext.authenticationPresentingViewController()

            guard presentingViewController.presentedViewController == nil else {
                assertionFailure("presentingViewController is already presenting a view controller")
                completion(.failed(error: PaymentSheetError.alreadyPresented), nil)
                return
            }
            let preConfirmationViewController = CVCReconfirmationViewController(
                paymentMethod: paymentMethod,
                intent: intent,
                configuration: configuration,
                onCompletion: { vc, intentConfirmParams in
                    vc.dismiss(animated: true)
                    confirmAfterHandlingLocalActions(configuration: configuration, authenticationContext: authenticationContext, intent: intent, elementsSession: elementsSession, paymentOption: paymentOption, intentConfirmParamsForDeferredIntent: intentConfirmParams, paymentHandler: paymentHandler, analyticsHelper: analyticsHelper, completion: completion)
                },
                onCancel: { vc in
                    vc.dismiss(animated: true)
                    completion(.canceled, nil)
                }
            )

            // Present CVC VC
            let bottomSheetVC = FlowController.makeBottomSheetViewController(
                preConfirmationViewController,
                configuration: configuration,
                didCancelNative3DS2: {
                    paymentHandler.cancel3DS2ChallengeFlow()
                }
            )
            presentingViewController.presentAsBottomSheet(bottomSheetVC, appearance: configuration.appearance)
        } else {
            // MARK: - No local actions
            confirmAfterHandlingLocalActions(configuration: configuration, authenticationContext: authenticationContext, intent: intent, elementsSession: elementsSession, paymentOption: paymentOption, intentConfirmParamsForDeferredIntent: nil, paymentHandler: paymentHandler, analyticsHelper: analyticsHelper, completion: completion)
        }
    }

    static func confirm(
        configuration: PaymentElementConfiguration,
        authenticationContext: STPAuthenticationContext,
        intent: Intent,
        elementsSession: STPElementsSession,
        paymentOption: PaymentOption,
        paymentHandler: STPPaymentHandler,
        integrationShape: IntegrationShape = .complete,
        analyticsHelper: PaymentSheetAnalyticsHelper,
        paymentMethodID: String? = nil
    ) async -> (PaymentSheetResult, STPAnalyticsClient.DeferredIntentConfirmationType?) {
        await withCheckedContinuation { continuation in
            Task { @MainActor in
                confirm(
                    configuration: configuration,
                    authenticationContext: authenticationContext,
                    intent: intent,
                    elementsSession: elementsSession,
                    paymentOption: paymentOption,
                    paymentHandler: paymentHandler,
                    integrationShape: integrationShape,
                    paymentMethodID: paymentMethodID,
                    analyticsHelper: analyticsHelper
                ) { result, deferredType in
                    continuation.resume(returning: (result, deferredType))
                }
            }
        }
    }

    static fileprivate func confirmAfterHandlingLocalActions(
        configuration: PaymentElementConfiguration,
        authenticationContext: STPAuthenticationContext,
        intent: Intent,
        elementsSession: STPElementsSession,
        paymentOption: PaymentOption,
        intentConfirmParamsForDeferredIntent: IntentConfirmParams?,
        paymentHandler: STPPaymentHandler,
        isFlowController: Bool = false,
        paymentMethodID: String? = nil,
        analyticsHelper: PaymentSheetAnalyticsHelper,
        completion: @escaping (PaymentSheetResult, STPAnalyticsClient.DeferredIntentConfirmationType?) -> Void
    ) {
        // Translates a STPPaymentHandler result to a PaymentResult
        let paymentHandlerCompletion: (STPPaymentHandlerActionStatus, NSError?) -> Void = { status, error in
            completion(makePaymentSheetResult(for: status, error: error), nil)
        }

        let clientAttributionMetadata: STPClientAttributionMetadata = {
            switch intent {
            case .paymentIntent(let paymentIntent):
                return .init(elementsSessionConfigId: elementsSession.sessionID,
                             paymentIntentCreationFlow: .standard,
                             paymentMethodSelectionFlow: paymentIntent.automaticPaymentMethods?.enabled ?? false ? .automatic : .merchantSpecified)
            case .setupIntent(let setupIntent):
                return .init(elementsSessionConfigId: elementsSession.sessionID,
                             paymentIntentCreationFlow: .standard,
                             paymentMethodSelectionFlow: setupIntent.automaticPaymentMethods?.enabled ?? false ? .automatic : .merchantSpecified)
            case .deferredIntent(let intentConfig):
                return .init(elementsSessionConfigId: elementsSession.sessionID,
                             paymentIntentCreationFlow: .deferred,
                             paymentMethodSelectionFlow: intentConfig.paymentMethodTypes?.isEmpty ?? true ? .automatic : .merchantSpecified)
            }
        }()
        switch paymentOption {
        // MARK: - Apple Pay
        case .applePay:
            guard
                let applePayContext = STPApplePayContext.create(
                    intent: intent,
                    configuration: configuration,
                    completion: completion
                )
            else {
                assertionFailure(PaymentSheetError.applePayNotSupportedOrMisconfigured.debugDescription)
                completion(.failed(error: PaymentSheetError.applePayNotSupportedOrMisconfigured), nil)
                return
            }
            applePayContext.presentApplePay()

        // MARK: - New Payment Method
        case let .new(confirmParams):
            let paymentMethodType: STPPaymentMethodType = {
                switch paymentOption.paymentMethodType {
                case .stripe(let paymentMethodType):
                    return paymentMethodType
                default:
                    return .unknown
                }
            }()
            // Set allow_redisplay on params
            confirmParams.setAllowRedisplay(
                mobilePaymentElementFeatures: elementsSession.customerSessionMobilePaymentElementFeatures,
                isSettingUp: intent.isSetupFutureUsageSet(for: paymentMethodType)
            )
            confirmParams.setClientAttributionMetadata(clientAttributionMetadata: clientAttributionMetadata)
            switch intent {
            // MARK: ↪ PaymentIntent
            case .paymentIntent(let paymentIntent):
                let params = makePaymentIntentParams(
                    confirmPaymentMethodType: .new(
                        params: confirmParams.paymentMethodParams,
                        paymentOptions: confirmParams.confirmPaymentMethodOptions,
                        shouldSave: confirmParams.saveForFutureUseCheckboxState == .selected,
                        shouldSetAsDefaultPM: confirmParams.setAsDefaultPM
                    ),
                    paymentIntent: paymentIntent,
                    configuration: configuration
                )
                paymentHandler.confirmPayment(
                    params,
                    with: authenticationContext,
                    completion: { actionStatus, paymentIntent, error in
                        if let paymentIntent {
                            setDefaultPaymentMethodIfNecessary(actionStatus: actionStatus, intent: .paymentIntent(paymentIntent), configuration: configuration, paymentMethodSetAsDefault: elementsSession.paymentMethodSetAsDefaultForPaymentSheet)
                        }
                        paymentHandlerCompletion(actionStatus, error)
                    }
                )
            // MARK: ↪ SetupIntent
            case .setupIntent(let setupIntent):
                let setupIntentParams = makeSetupIntentParams(
                    confirmPaymentMethodType: .new(
                        params: confirmParams.paymentMethodParams,
                        paymentOptions: confirmParams.confirmPaymentMethodOptions,
                        shouldSave: false,
                        shouldSetAsDefaultPM: confirmParams.setAsDefaultPM
                    ),
                    setupIntent: setupIntent,
                    configuration: configuration
                )
                paymentHandler.confirmSetupIntent(
                    setupIntentParams,
                    with: authenticationContext,
                    completion: { actionStatus, setupIntent, error in
                        if let setupIntent {
                            setDefaultPaymentMethodIfNecessary(actionStatus: actionStatus, intent: .setupIntent(setupIntent), configuration: configuration, paymentMethodSetAsDefault: elementsSession.paymentMethodSetAsDefaultForPaymentSheet)
                        }
                        paymentHandlerCompletion(actionStatus, error)
                    }
                )
            // MARK: ↪ Deferred Intent
            case .deferredIntent(let intentConfig):
                handleDeferredIntentConfirmation(
                    confirmType: .new(
                        params: confirmParams.paymentMethodParams,
                        paymentOptions: confirmParams.confirmPaymentMethodOptions,
                        shouldSave: confirmParams.saveForFutureUseCheckboxState == .selected,
                        shouldSetAsDefaultPM: confirmParams.setAsDefaultPM
                    ),
                    configuration: configuration,
                    intentConfig: intentConfig,
                    authenticationContext: authenticationContext,
                    paymentHandler: paymentHandler,
                    isFlowController: isFlowController,
                    allowsSetAsDefaultPM: elementsSession.paymentMethodSetAsDefaultForPaymentSheet,
                    completion: completion
                )
            }

        // MARK: - Saved Payment Method
        case let .saved(paymentMethod, intentConfirmParamsFromSavedPaymentMethod):
            switch intent {
            // MARK: ↪ PaymentIntent
            case .paymentIntent(let paymentIntent):
                let paymentOptions = intentConfirmParamsForDeferredIntent?.confirmPaymentMethodOptions != nil
                    // Flow controller collects CVC using interstitial:
                    ? intentConfirmParamsForDeferredIntent?.confirmPaymentMethodOptions
                    // PaymentSheet collects CVC in sheet:
                    : intentConfirmParamsFromSavedPaymentMethod?.confirmPaymentMethodOptions

                let paymentIntentParams = makePaymentIntentParams(confirmPaymentMethodType: .saved(paymentMethod, paymentOptions: paymentOptions), paymentIntent: paymentIntent, configuration: configuration)

                paymentHandler.confirmPayment(
                    paymentIntentParams,
                    with: authenticationContext,
                    completion: { actionStatus, _, error in
                        paymentHandlerCompletion(actionStatus, error)
                    }
                )
            // MARK: ↪ SetupIntent
            case .setupIntent(let setupIntent):
                let setupIntentParams = makeSetupIntentParams(
                    confirmPaymentMethodType: .saved(paymentMethod, paymentOptions: nil),
                    setupIntent: setupIntent,
                    configuration: configuration
                )
                paymentHandler.confirmSetupIntent(
                    setupIntentParams,
                    with: authenticationContext,
                    completion: { actionStatus, _, error in
                        paymentHandlerCompletion(actionStatus, error)
                    }
                )
            // MARK: ↪ Deferred Intent
            case .deferredIntent(let intentConfig):
                let paymentOptions = intentConfirmParamsForDeferredIntent?.confirmPaymentMethodOptions != nil
                    // Flow controller and embedded collects CVC using interstitial:
                    ? intentConfirmParamsForDeferredIntent?.confirmPaymentMethodOptions
                    // PaymentSheet collects CVC in sheet:
                    : intentConfirmParamsFromSavedPaymentMethod?.confirmPaymentMethodOptions
                handleDeferredIntentConfirmation(
                    confirmType: .saved(paymentMethod, paymentOptions: paymentOptions),
                    configuration: configuration,
                    intentConfig: intentConfig,
                    authenticationContext: authenticationContext,
                    paymentHandler: paymentHandler,
                    isFlowController: isFlowController,
                    completion: completion
                )
            }
        // MARK: - Link
        case .link(let confirmOption):
            // This is called when the customer pays in the sheet (as opposed to the Link webview) and agreed to sign up for Link
            // Parameters:
            // - paymentMethodParams: The params to use for the payment.
            // - linkAccount: The Link account used for payment. Will be logged out if present after payment completes, whether it was successful or not.
            let confirmWithPaymentMethodParams: (STPPaymentMethodParams, PaymentSheetLinkAccount?, Bool) -> Void = { paymentMethodParams, linkAccount, shouldSave in
                switch intent {
                case .paymentIntent(let paymentIntent):
                    let paymentIntentParams = STPPaymentIntentParams(clientSecret: paymentIntent.clientSecret)
                    paymentIntentParams.paymentMethodParams = paymentMethodParams
                    paymentIntentParams.returnURL = configuration.returnURL
                    let paymentOptions = paymentIntentParams.paymentMethodOptions ?? STPConfirmPaymentMethodOptions()
                    let paymentMethodType = paymentMethodParams.type
                    let currentSetupFutureUsage = paymentIntent.paymentMethodOptions?.setupFutureUsage(for: paymentMethodType)
                    paymentOptions.setSetupFutureUsageIfNecessary(shouldSave, currentSetupFutureUsage: currentSetupFutureUsage, paymentMethodType: paymentMethodType, customer: configuration.customer)
                    paymentIntentParams.paymentMethodOptions = paymentOptions
                    paymentIntentParams.shipping = makeShippingParams(for: paymentIntent, configuration: configuration)
                    paymentHandler.confirmPayment(
                        paymentIntentParams,
                        with: authenticationContext,
                        completion: { actionStatus, _, error in
                            paymentHandlerCompletion(actionStatus, error)
                            if actionStatus == .succeeded {
                                linkAccount?.logout()
                            }
                        }
                    )
                case .setupIntent(let setupIntent):
                    let setupIntentParams = STPSetupIntentConfirmParams(clientSecret: setupIntent.clientSecret)
                    setupIntentParams.paymentMethodParams = paymentMethodParams
                    setupIntentParams.returnURL = configuration.returnURL
                    paymentHandler.confirmSetupIntent(
                        setupIntentParams,
                        with: authenticationContext,
                        completion: { actionStatus, _, error in
                            paymentHandlerCompletion(actionStatus, error)
                            if actionStatus == .succeeded {
                                linkAccount?.logout()
                            }
                        }
                    )
                case .deferredIntent(let intentConfig):
                    handleDeferredIntentConfirmation(
                        confirmType: .new(
                            params: paymentMethodParams,
                            paymentOptions: STPConfirmPaymentMethodOptions(),
                            shouldSave: shouldSave
                        ),
                        configuration: configuration,
                        intentConfig: intentConfig,
                        authenticationContext: authenticationContext,
                        paymentHandler: paymentHandler,
                        isFlowController: isFlowController,
                        completion: { psResult, confirmationType in
                            if case .completed = psResult {
                                linkAccount?.logout()
                            }
                            completion(psResult, confirmationType)
                        }
                    )
                }
            }
            let confirmWithPaymentMethod: (STPPaymentMethod, PaymentSheetLinkAccount?, Bool) -> Void = { paymentMethod, linkAccount, shouldSave in
                let mandateCustomerAcceptanceParams = STPMandateCustomerAcceptanceParams()
                let onlineParams = STPMandateOnlineParams(ipAddress: "", userAgent: "")
                // Tell Stripe to infer mandate info from client
                onlineParams.inferFromClient = true
                mandateCustomerAcceptanceParams.onlineParams = onlineParams
                mandateCustomerAcceptanceParams.type = .online
                let mandateData = STPMandateDataParams(customerAcceptance: mandateCustomerAcceptanceParams)
                switch intent {
                case .paymentIntent(let paymentIntent):
                    let paymentIntentParams = STPPaymentIntentParams(clientSecret: paymentIntent.clientSecret)
                    paymentIntentParams.paymentMethodId = paymentMethod.stripeId
                    paymentIntentParams.returnURL = configuration.returnURL
                    paymentIntentParams.shipping = makeShippingParams(for: paymentIntent, configuration: configuration)
                    let paymentOptions = paymentIntentParams.paymentMethodOptions ?? STPConfirmPaymentMethodOptions()
                    let paymentMethodType = paymentMethod.type
                    let currentSetupFutureUsage = paymentIntent.paymentMethodOptions?.setupFutureUsage(for: paymentMethodType)
                    paymentOptions.setSetupFutureUsageIfNecessary(shouldSave, currentSetupFutureUsage: currentSetupFutureUsage, paymentMethodType: paymentMethodType, customer: configuration.customer)
                    paymentIntentParams.paymentMethodOptions = paymentOptions
                    paymentIntentParams.mandateData = mandateData
                    paymentHandler.confirmPayment(
                        paymentIntentParams,
                        with: authenticationContext,
                        completion: { actionStatus, _, error in
                            if actionStatus == .succeeded {
                                linkAccount?.logout()
                            }
                            paymentHandlerCompletion(actionStatus, error)
                        }
                    )
                case .setupIntent(let setupIntent):
                    let setupIntentParams = STPSetupIntentConfirmParams(clientSecret: setupIntent.clientSecret)
                    setupIntentParams.paymentMethodID = paymentMethod.stripeId
                    setupIntentParams.returnURL = configuration.returnURL
                    setupIntentParams.mandateData = mandateData
                    paymentHandler.confirmSetupIntent(
                        setupIntentParams,
                        with: authenticationContext,
                        completion: { actionStatus, _, error in
                            if actionStatus == .succeeded {
                                linkAccount?.logout()
                            }
                            paymentHandlerCompletion(actionStatus, error)
                        }
                    )
                case .deferredIntent(let intentConfig):
                    handleDeferredIntentConfirmation(
                        confirmType: .saved(paymentMethod, paymentOptions: nil),
                        configuration: configuration,
                        intentConfig: intentConfig,
                        authenticationContext: authenticationContext,
                        paymentHandler: paymentHandler,
                        isFlowController: isFlowController,
                        completion: { psResult, confirmationType in
                            if case .completed = psResult {
                                linkAccount?.logout()
                            }
                            completion(psResult, confirmationType)
                        }
                    )
                }
            }

            let confirmWithPaymentDetails:
                (
                    PaymentSheetLinkAccount,
                    ConsumerPaymentDetails,
                    String?, // cvc
                    String?, // phone number
                    Bool,
                    STPPaymentMethodAllowRedisplay?
                ) -> Void = { linkAccount, paymentDetails, cvc, billingPhoneNumber, shouldSave, allowRedisplay in
                    guard let paymentMethodParams = linkAccount.makePaymentMethodParams(
                        from: paymentDetails,
                        cvc: cvc,
                        billingPhoneNumber: billingPhoneNumber,
                        allowRedisplay: allowRedisplay
                    ) else {
                        let error = PaymentSheetError.payingWithoutValidLinkSession
                        completion(.failed(error: error), nil)
                        return
                    }

                    confirmWithPaymentMethodParams(paymentMethodParams, linkAccount, shouldSave)
                }

            let createPaymentDetailsAndConfirm:
                (
                    PaymentSheetLinkAccount,
                    STPPaymentMethodParams,
                    Bool
                ) -> Void = { linkAccount, paymentMethodParams, shouldSave in
                    guard linkAccount.sessionState == .verified else {
                        // We don't support 2FA in the native mobile Link flow, so if 2FA is required then this is a no-op.
                        // Just fall through and don't save the card details to Link.
                        STPAnalyticsClient.sharedClient.logLinkPopupSkipped()

                        // Attempt to confirm directly with params
                        confirmWithPaymentMethodParams(paymentMethodParams, linkAccount, shouldSave)
                        return
                    }

                    linkAccount.createPaymentDetails(with: paymentMethodParams, isDefault: false) { result in
                        switch result {
                        case .success(let paymentDetails):
                            // We need to explicitly pass the billing phone number to the share and payment method endpoints,
                            // since it's not part of the consumer payment details.
                            let billingPhoneNumber = paymentMethodParams.billingDetails?.phone

                            if elementsSession.linkPassthroughModeEnabled {
                                // If passthrough mode, share payment details
                                linkAccount.sharePaymentDetails(
                                    id: paymentDetails.stripeID,
                                    cvc: paymentMethodParams.card?.cvc,
                                    allowRedisplay: paymentMethodParams.allowRedisplay,
                                    expectedPaymentMethodType: paymentDetails.expectedPaymentMethodTypeForPassthroughMode(elementsSession),
                                    billingPhoneNumber: billingPhoneNumber
                                ) { result in
                                    switch result {
                                    case .success(let paymentDetailsShareResponse):
                                        confirmWithPaymentMethod(paymentDetailsShareResponse.paymentMethod, linkAccount, shouldSave)
                                    case .failure(let error):
                                        STPAnalyticsClient.sharedClient.logLinkSharePaymentDetailsFailure(error: error)
                                        // If this fails, confirm directly
                                        confirmWithPaymentMethodParams(paymentMethodParams, linkAccount, shouldSave)
                                    }
                                }
                            } else {
                                // If not passthrough mode, confirm details directly
                                confirmWithPaymentDetails(linkAccount, paymentDetails, paymentMethodParams.card?.cvc, billingPhoneNumber, shouldSave, paymentMethodParams.allowRedisplay)
                            }
                        case .failure(let error):
                            STPAnalyticsClient.sharedClient.logLinkCreatePaymentDetailsFailure(error: error)
                            // Attempt to confirm directly with params
                            confirmWithPaymentMethodParams(paymentMethodParams, linkAccount, shouldSave)
                        }
                    }
                }

            switch confirmOption {
            case .wallet:
                let useNativeLink = deviceCanUseNativeLink(elementsSession: elementsSession, configuration: configuration)
                if useNativeLink {
                    let linkController = PayWithNativeLinkController(mode: .full, intent: intent, elementsSession: elementsSession, configuration: configuration, logPayment: true, analyticsHelper: analyticsHelper)
                    linkController.presentAsBottomSheet(from: authenticationContext.authenticationPresentingViewController(), shouldOfferApplePay: false, shouldFinishOnClose: false, completion: { result, confirmationType, _ in
                        completion(result, confirmationType)
                    })
                } else {
                    let linkController = PayWithLinkController(intent: intent, elementsSession: elementsSession, configuration: configuration, analyticsHelper: analyticsHelper)
                    linkController.present(from: authenticationContext.authenticationPresentingViewController(),
                                           completion: completion)
                }
            case .signUp(let linkAccount, let phoneNumberFromSignup, let consentAction, let legalName, let intentConfirmParams):
                let billingDetails = intentConfirmParams.paymentMethodParams.billingDetails
                let countryCode = billingDetails?.address?.country ?? elementsSession.countryCode

                let phoneNumber = if elementsSession.linkSignupOptInFeatureEnabled {
                    billingDetails?.phone.flatMap { PhoneNumber.fromE164($0) }
                } else {
                    phoneNumberFromSignup
                }

                linkAccount.signUp(
                    with: phoneNumber,
                    legalName: legalName,
                    countryCode: countryCode,
                    consentAction: consentAction
                ) { result in
                    UserDefaults.standard.markLinkAsUsed()
                    switch result {
                    case .success:
                        STPAnalyticsClient.sharedClient.logLinkSignupComplete()
                        let linkPaymentMethodType: STPPaymentMethodType = elementsSession.linkPassthroughModeEnabled ? intentConfirmParams.paymentMethodParams.type : .link
                        // Set allow_redisplay on params
                        intentConfirmParams.setAllowRedisplay(
                            mobilePaymentElementFeatures: elementsSession.customerSessionMobilePaymentElementFeatures,
                            isSettingUp: intent.isSetupFutureUsageSet(for: linkPaymentMethodType)
                        )
                        createPaymentDetailsAndConfirm(linkAccount, intentConfirmParams.paymentMethodParams, intentConfirmParams.saveForFutureUseCheckboxState == .selected)
                    case .failure(let error as NSError):
                        STPAnalyticsClient.sharedClient.logLinkSignupFailure(error: error)
                        // Attempt to confirm directly with params as a fallback.
                        intentConfirmParams.setAllowRedisplay(
                            mobilePaymentElementFeatures: elementsSession.customerSessionMobilePaymentElementFeatures,
                            isSettingUp: intent.isSetupFutureUsageSet(for: intentConfirmParams.paymentMethodParams.type)
                        )
                        confirmWithPaymentMethodParams(intentConfirmParams.paymentMethodParams, linkAccount, intentConfirmParams.saveForFutureUseCheckboxState == .selected)
                    }
                }
            case .withPaymentMethod(let paymentMethod):
                confirmWithPaymentMethod(paymentMethod, nil, false)
            case .withPaymentDetails(let linkAccount, let paymentDetails, let confirmationExtras, _):
                let shouldSave = false // always false, as we don't show a save-to-merchant checkbox in Link VC

                if elementsSession.linkPassthroughModeEnabled {
                    // allowRedisplay is nil since we are not saving a payment method.
                    linkAccount.sharePaymentDetails(
                        id: paymentDetails.stripeID,
                        cvc: paymentDetails.cvc,
                        allowRedisplay: nil,
                        expectedPaymentMethodType: paymentDetails.expectedPaymentMethodTypeForPassthroughMode(elementsSession),
                        billingPhoneNumber: confirmationExtras?.billingPhoneNumber
                    ) { result in
                        switch result {
                        case .success(let paymentDetailsShareResponse):
                            confirmWithPaymentMethod(paymentDetailsShareResponse.paymentMethod, linkAccount, shouldSave)
                        case .failure(let error):
                            STPAnalyticsClient.sharedClient.logLinkSharePaymentDetailsFailure(error: error)
                            paymentHandlerCompletion(.failed, error as NSError)
                        }
                    }
                } else {
                    confirmWithPaymentDetails(linkAccount, paymentDetails, paymentDetails.cvc, confirmationExtras?.billingPhoneNumber, shouldSave, nil)
                }
            }
        case let .external(externalPaymentOption, billingDetails):
            DispatchQueue.main.async {
                // Call confirmHandler so that the merchant completes the payment
                externalPaymentOption.confirm(billingDetails: billingDetails) { result in
                    // This closure is invoked by the merchant when payment is finished
                    completion(result, nil)
                }
            }
        }
    }

    // MARK: - Helper methods

    enum PaymentOrSetupIntent {
        case paymentIntent(STPPaymentIntent)
        case setupIntent(STPSetupIntent)

        func isSetupFutureUsageSet(paymentMethodType: STPPaymentMethodType) -> Bool {
            switch self {
            case .paymentIntent(let paymentIntent):
                return paymentIntent.isSetupFutureUsageSet(for: paymentMethodType)
            case .setupIntent:
                return true
            }
        }

        var paymentMethod: STPPaymentMethod? {
            switch self {
            case .paymentIntent(let paymentIntent):
                return paymentIntent.paymentMethod
            case .setupIntent(let setupIntent):
                return setupIntent.paymentMethod
            }
        }
    }

    /// A helper method that sets the Customer's default payment method if necessary.
    /// - Parameter actionStatus: The final status returned by `STPPaymentHandler`'s completion block.
    static func setDefaultPaymentMethodIfNecessary(actionStatus: STPPaymentHandlerActionStatus, intent: PaymentOrSetupIntent, configuration: PaymentElementConfiguration, paymentMethodSetAsDefault: Bool) {

        guard
            // Did we successfully save this payment method?
            actionStatus == .succeeded,
            let customer = configuration.customer?.id,
            let paymentMethod = intent.paymentMethod,
            intent.isSetupFutureUsageSet(paymentMethodType: paymentMethod.type),
            // Can it appear in the list of saved PMs?
            PaymentSheet.supportedSavedPaymentMethods.contains(paymentMethod.type),
            // Should it write to local storage?
            !paymentMethodSetAsDefault
        else {
            return
        }
        CustomerPaymentOption.setDefaultPaymentMethod(.stripeId(paymentMethod.stripeId), forCustomer: customer)
    }

    static func makeShippingParams(for paymentIntent: STPPaymentIntent, configuration: PaymentElementConfiguration)
        -> STPPaymentIntentShippingDetailsParams?
    {
        let params = STPPaymentIntentShippingDetailsParams(paymentSheetConfiguration: configuration)
        // If a merchant attaches shipping to the PI on their server, the /confirm endpoint will error if we update shipping with a “requires secret key” error message.
        // To accommodate this, don't attach if our shipping is the same as the PI's shipping
        guard !isEqual(paymentIntent.shipping, params) else {
            return nil
        }
        return params
    }

    enum ConfirmPaymentMethodType {
        case saved(STPPaymentMethod, paymentOptions: STPConfirmPaymentMethodOptions?)
        /// - paymentMethod: Pass this if you created a PaymentMethod already (e.g. for the deferred flow).
        case new(params: STPPaymentMethodParams, paymentOptions: STPConfirmPaymentMethodOptions, paymentMethod: STPPaymentMethod? = nil, shouldSave: Bool, shouldSetAsDefaultPM: Bool? = nil)
        var shouldSave: Bool {
            switch self {
            case .saved:
                return false
            case .new(_, _, _, let shouldSave, _):
                return shouldSave
            }
        }
    }

    static func makePaymentIntentParams(
        confirmPaymentMethodType: ConfirmPaymentMethodType,
        paymentIntent: STPPaymentIntent,
        configuration: PaymentElementConfiguration,
        mandateData: STPMandateDataParams? = nil
    ) -> STPPaymentIntentParams {
        let params: STPPaymentIntentParams
        let shouldSave: Bool
        let paymentMethodType: STPPaymentMethodType
        switch confirmPaymentMethodType {
        case .saved(let paymentMethod, let paymentMethodOptions):
            shouldSave = false
            paymentMethodType = paymentMethod.type
            params = STPPaymentIntentParams(clientSecret: paymentIntent.clientSecret, paymentMethodType: paymentMethod.type)
            params.paymentMethodOptions = paymentMethodOptions
            params.paymentMethodId = paymentMethod.stripeId
        case let .new(paymentMethodParams, paymentMethodoptions, paymentMethod, _shouldSave, shouldSetAsDefaultPM):
            shouldSave = _shouldSave
            if let paymentMethod = paymentMethod {
                paymentMethodType = paymentMethod.type
                params = STPPaymentIntentParams(clientSecret: paymentIntent.clientSecret, paymentMethodType: paymentMethod.type)
                params.paymentMethodId = paymentMethod.stripeId
                params.paymentMethodOptions = paymentMethodoptions
            } else {
                params = STPPaymentIntentParams(clientSecret: paymentIntent.clientSecret)
                params.paymentMethodParams = paymentMethodParams
                params.paymentMethodOptions = paymentMethodoptions
                paymentMethodType = paymentMethodParams.type
            }
            if let shouldSetAsDefaultPM {
                params.setAsDefaultPM = NSNumber(value: shouldSetAsDefaultPM)
            }
            let requiresMandateData: [STPPaymentMethodType] = [.payPal, .cashApp, .revolutPay, .amazonPay, .klarna, .satispay]
            let isSetupFutureUsageOffSession = paymentIntent.setupFutureUsage(for: paymentMethodType) == "off_session"
            if requiresMandateData.contains(paymentMethodType) && isSetupFutureUsageOffSession
            {
                params.mandateData = .makeWithInferredValues()
            }
        }

        let paymentOptions = params.paymentMethodOptions ?? STPConfirmPaymentMethodOptions()
        let currentSetupFutureUsage = paymentIntent.paymentMethodOptions?.setupFutureUsage(for: paymentMethodType)
        paymentOptions.setSetupFutureUsageIfNecessary(shouldSave, currentSetupFutureUsage: currentSetupFutureUsage, paymentMethodType: paymentMethodType, customer: configuration.customer)
        if let mandateData = mandateData {
            params.mandateData = mandateData
        }
        // Set moto (mail order and telephone orders) for Dashboard b/c merchants key in cards on behalf of customers
        if configuration.apiClient.publishableKeyIsUserKey {
            paymentOptions.setMoto()
        }
        params.paymentMethodOptions = paymentOptions
        params.returnURL = configuration.returnURL
        params.shipping = makeShippingParams(for: paymentIntent, configuration: configuration)
        return params
    }

    static func makeSetupIntentParams(
        confirmPaymentMethodType: ConfirmPaymentMethodType,
        setupIntent: STPSetupIntent,
        configuration: PaymentElementConfiguration,
        mandateData: STPMandateDataParams? = nil
    ) -> STPSetupIntentConfirmParams {
        let params: STPSetupIntentConfirmParams
        switch confirmPaymentMethodType {
        case let .saved(paymentMethod, _):
            params = STPSetupIntentConfirmParams(
                clientSecret: setupIntent.clientSecret,
                paymentMethodType: paymentMethod.type
            )
            params.paymentMethodID = paymentMethod.stripeId

        case let .new(paymentMethodParams, _, paymentMethod, _, shouldSetAsDefaultPM):
            if let paymentMethod {
                params = STPSetupIntentConfirmParams(
                    clientSecret: setupIntent.clientSecret,
                    paymentMethodType: paymentMethod.type
                )
                params.paymentMethodID = paymentMethod.stripeId
            } else {
                params = STPSetupIntentConfirmParams(clientSecret: setupIntent.clientSecret)
                params.paymentMethodParams = paymentMethodParams
            }
            if let shouldSetAsDefaultPM {
                params.setAsDefaultPM = NSNumber(value: shouldSetAsDefaultPM)
            }
            // Paypal & revolut & satispay requires mandate_data if setting up
            if params.paymentMethodType == .payPal || params.paymentMethodType == .revolutPay || params.paymentMethodType == .satispay {
                params.mandateData = .makeWithInferredValues()
            }
        }
        if let mandateData = mandateData {
            params.mandateData = mandateData
        }
        // Set moto (mail order and telephone orders) for Dashboard b/c merchants key in cards on behalf of customers
        if configuration.apiClient.publishableKeyIsUserKey {
            params.additionalAPIParameters["payment_method_options"] = ["card": ["moto": true]]
        }
        params.returnURL = configuration.returnURL
        return params
    }
}

/// A helper method to compare shipping details
private func isEqual(_ lhs: STPPaymentIntentShippingDetails?, _ rhs: STPPaymentIntentShippingDetailsParams?) -> Bool {
    guard let lhs = lhs, let rhs = rhs else {
        // One or both are nil, so they're only equal if they're both nil
        return lhs == nil && rhs == nil
    }
    // Convert lhs to a STPPaymentIntentShippingDetailsAddressParams for ease of comparison
    let addressParams = STPPaymentIntentShippingDetailsAddressParams(line1: lhs.address?.line1 ?? "")
    addressParams.line2 = lhs.address?.line2
    addressParams.city = lhs.address?.city
    addressParams.state = lhs.address?.state
    addressParams.postalCode = lhs.address?.postalCode
    addressParams.country = lhs.address?.country

    let lhsConverted = STPPaymentIntentShippingDetailsParams(address: addressParams, name: lhs.name ?? "")
    lhsConverted.phone = lhs.phone

    return rhs == lhsConverted
}

private extension ConsumerPaymentDetails {

    func expectedPaymentMethodTypeForPassthroughMode(
        _ elementsSession: STPElementsSession
    ) -> String? {
        switch type {
        case .card:
            return "card"
        case .unparsable:
            return nil
        case .bankAccount:
            let canAcceptACH = elementsSession.orderedPaymentMethodTypes.contains(.USBankAccount)
            let isLinkCardBrand = elementsSession.linkSettings?.linkMode?.isPantherPayment ?? false
            return isLinkCardBrand && !canAcceptACH ? "card" : "bank_account"
        }
    }
}
