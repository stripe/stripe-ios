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
        confirmationChallenge: ConfirmationChallenge? = nil,
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
                confirmAfterHandlingLocalActions(configuration: configuration, authenticationContext: authenticationContext, intent: intent, elementsSession: elementsSession, paymentOption: paymentOption, intentConfirmParamsForDeferredIntent: nil, paymentHandler: paymentHandler, confirmationChallenge: confirmationChallenge, analyticsHelper: analyticsHelper, completion: completion)
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
                    confirmAfterHandlingLocalActions(configuration: configuration, authenticationContext: authenticationContext, intent: intent, elementsSession: elementsSession, paymentOption: paymentOption, intentConfirmParamsForDeferredIntent: intentConfirmParams, paymentHandler: paymentHandler, confirmationChallenge: confirmationChallenge, analyticsHelper: analyticsHelper, completion: completion)
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
            confirmAfterHandlingLocalActions(configuration: configuration, authenticationContext: authenticationContext, intent: intent, elementsSession: elementsSession, paymentOption: paymentOption, intentConfirmParamsForDeferredIntent: nil, paymentHandler: paymentHandler, confirmationChallenge: confirmationChallenge, analyticsHelper: analyticsHelper, completion: completion)
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
        confirmationChallenge: ConfirmationChallenge? = nil,
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
                    confirmationChallenge: confirmationChallenge,
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
        confirmationChallenge: ConfirmationChallenge?,
        analyticsHelper: PaymentSheetAnalyticsHelper,
        completion: @escaping (PaymentSheetResult, STPAnalyticsClient.DeferredIntentConfirmationType?) -> Void
    ) {
        // Translates a STPPaymentHandler result to a PaymentResult
        let paymentHandlerCompletion: (STPPaymentHandlerActionStatus, NSError?) -> Void = { status, error in
            completion(makePaymentSheetResult(for: status, error: error), nil)
        }

        let clientAttributionMetadata = STPClientAttributionMetadata.makeClientAttributionMetadata(intent: intent, elementsSession: elementsSession)

        let isSettingUp: (STPPaymentMethodType) -> Bool = { paymentMethodType in
            intent.isSetupFutureUsageSet(for: paymentMethodType) || elementsSession.forceSaveFutureUseBehaviorAndNewMandateText
        }

        switch paymentOption {
        // MARK: - Apple Pay
        case .applePay:
            guard
                let applePayContext = STPApplePayContext.create(
                    intent: intent,
                    configuration: configuration,
                    clientAttributionMetadata: clientAttributionMetadata,
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
            Task { @MainActor in
                let radarOptions = await confirmationChallenge?.makeRadarOptions()
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
                    isSettingUp: isSettingUp(paymentMethodType)
                )
                confirmParams.paymentMethodParams.radarOptions = radarOptions
                confirmParams.paymentMethodParams.clientAttributionMetadata = clientAttributionMetadata
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
                    paymentHandler.confirmPaymentIntent(
                        params: params,
                        authenticationContext: authenticationContext,
                        completion: { actionStatus, paymentIntent, error in
                            Task { await confirmationChallenge?.complete() }
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
                        params: setupIntentParams,
                        authenticationContext: authenticationContext,
                        completion: { actionStatus, setupIntent, error in
                            Task { await confirmationChallenge?.complete() }
                            if let setupIntent {
                                setDefaultPaymentMethodIfNecessary(actionStatus: actionStatus, intent: .setupIntent(setupIntent), configuration: configuration, paymentMethodSetAsDefault: elementsSession.paymentMethodSetAsDefaultForPaymentSheet)
                            }
                            paymentHandlerCompletion(actionStatus, error)
                        }
                    )
                    // MARK: ↪ Deferred Intent
                case .deferredIntent(let intentConfig):
                    Task { @MainActor in
                        let result = await routeDeferredIntentConfirmation(
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
                            elementsSession: elementsSession
                        )
                        await confirmationChallenge?.complete()
                        completion(result.result, result.deferredIntentConfirmationType)
                    }
                }
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

                let paymentIntentParams = makePaymentIntentParams(confirmPaymentMethodType: .saved(paymentMethod, paymentOptions: paymentOptions, clientAttributionMetadata: clientAttributionMetadata, radarOptions: nil), paymentIntent: paymentIntent, configuration: configuration)

                paymentHandler.confirmPaymentIntent(
                    params: paymentIntentParams,
                    authenticationContext: authenticationContext,
                    completion: { actionStatus, _, error in
                        paymentHandlerCompletion(actionStatus, error)
                    }
                )
            // MARK: ↪ SetupIntent
            case .setupIntent(let setupIntent):
                let setupIntentParams = makeSetupIntentParams(
                    confirmPaymentMethodType: .saved(paymentMethod, paymentOptions: nil, clientAttributionMetadata: clientAttributionMetadata, radarOptions: nil),
                    setupIntent: setupIntent,
                    configuration: configuration
                )
                paymentHandler.confirmSetupIntent(
                    params: setupIntentParams,
                    authenticationContext: authenticationContext,
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
                Task { @MainActor in
                    let result = await routeDeferredIntentConfirmation(
                        confirmType: .saved(paymentMethod, paymentOptions: paymentOptions, clientAttributionMetadata: clientAttributionMetadata, radarOptions: nil),
                        configuration: configuration,
                        intentConfig: intentConfig,
                        authenticationContext: authenticationContext,
                        paymentHandler: paymentHandler,
                        isFlowController: isFlowController,
                        elementsSession: elementsSession
                    )
                    completion(result.result, result.deferredIntentConfirmationType)
                }
            }
        // MARK: - Link
        case .link(let confirmOption):
            // This is called when the customer pays in the sheet (as opposed to the Link webview) and agreed to sign up for Link
            // Parameters:
            // - paymentMethodParams: The params to use for the payment.
            // - linkAccount: The Link account used for payment. Will be logged out if present after payment completes, whether it was successful or not.
            let confirmWithPaymentMethodParams: (STPPaymentMethodParams, PaymentSheetLinkAccount?, Bool) -> Void = { paymentMethodParams, linkAccount, shouldSave in
                Task { @MainActor in
                    let radarOptions = await confirmationChallenge?.makeRadarOptions()
                    paymentMethodParams.radarOptions = radarOptions
                    paymentMethodParams.clientAttributionMetadata = clientAttributionMetadata
                    switch intent {
                    case .paymentIntent(let paymentIntent):
                        let paymentIntentParams = STPPaymentIntentConfirmParams(clientSecret: paymentIntent.clientSecret)
                        paymentIntentParams.paymentMethodParams = paymentMethodParams
                        paymentIntentParams.returnURL = configuration.returnURL
                        let paymentOptions = paymentIntentParams.paymentMethodOptions ?? STPConfirmPaymentMethodOptions()
                        let paymentMethodType = paymentMethodParams.type
                        let currentSetupFutureUsage = paymentIntent.paymentMethodOptions?.setupFutureUsage(for: paymentMethodType)
                        paymentOptions.setSetupFutureUsageIfNecessary(shouldSave, currentSetupFutureUsage: currentSetupFutureUsage, paymentMethodType: paymentMethodType, customer: configuration.customer)
                        paymentIntentParams.paymentMethodOptions = paymentOptions
                        paymentIntentParams.shipping = makeShippingParams(for: paymentIntent, configuration: configuration)
                        paymentIntentParams.clientAttributionMetadata = paymentMethodParams.clientAttributionMetadata
                        paymentHandler.confirmPaymentIntent(
                            params: paymentIntentParams,
                            authenticationContext: authenticationContext,
                            completion: { actionStatus, _, error in
                                Task { await confirmationChallenge?.complete() }
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
                        setupIntentParams.clientAttributionMetadata = paymentMethodParams.clientAttributionMetadata
                        paymentHandler.confirmSetupIntent(
                            params: setupIntentParams,
                            authenticationContext: authenticationContext,
                            completion: { actionStatus, _, error in
                                Task { await confirmationChallenge?.complete() }
                                paymentHandlerCompletion(actionStatus, error)
                                if actionStatus == .succeeded {
                                    linkAccount?.logout()
                                }
                            }
                        )
                    case .deferredIntent(let intentConfig):
                        Task { @MainActor in
                            let result = await routeDeferredIntentConfirmation(
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
                                elementsSession: elementsSession
                            )
                            if shouldLogOutOfLink(result: result.result, elementsSession: elementsSession) {
                                linkAccount?.logout()
                            }
                            await confirmationChallenge?.complete()
                            completion(result.result, result.deferredIntentConfirmationType)
                        }
                    }
                }
            }
            let confirmWithPaymentMethod: (STPPaymentMethod, PaymentSheetLinkAccount?, Bool, STPClientAttributionMetadata?) -> Void = { paymentMethod, linkAccount, shouldSave, clientAttributionMetadata in
                Task { @MainActor in
                    let radarOptions = await confirmationChallenge?.makeRadarOptions()
                    let mandateCustomerAcceptanceParams = STPMandateCustomerAcceptanceParams()
                    let onlineParams = STPMandateOnlineParams(ipAddress: "", userAgent: "")
                    // Tell Stripe to infer mandate info from client
                    onlineParams.inferFromClient = true
                    mandateCustomerAcceptanceParams.onlineParams = onlineParams
                    mandateCustomerAcceptanceParams.type = .online
                    let mandateData = STPMandateDataParams(customerAcceptance: mandateCustomerAcceptanceParams)
                    switch intent {
                    case .paymentIntent(let paymentIntent):
                        let paymentIntentParams = STPPaymentIntentConfirmParams(clientSecret: paymentIntent.clientSecret)
                        paymentIntentParams.paymentMethodId = paymentMethod.stripeId
                        paymentIntentParams.returnURL = configuration.returnURL
                        paymentIntentParams.shipping = makeShippingParams(for: paymentIntent, configuration: configuration)
                        let paymentOptions = paymentIntentParams.paymentMethodOptions ?? STPConfirmPaymentMethodOptions()
                        let paymentMethodType = paymentMethod.type
                        let currentSetupFutureUsage = paymentIntent.paymentMethodOptions?.setupFutureUsage(for: paymentMethodType)
                        paymentOptions.setSetupFutureUsageIfNecessary(shouldSave, currentSetupFutureUsage: currentSetupFutureUsage, paymentMethodType: paymentMethodType, customer: configuration.customer)
                        paymentIntentParams.paymentMethodOptions = paymentOptions
                        paymentIntentParams.radarOptions = radarOptions
                        paymentIntentParams.mandateData = mandateData
                        paymentIntentParams.clientAttributionMetadata = clientAttributionMetadata
                        paymentHandler.confirmPaymentIntent(
                            params: paymentIntentParams,
                            authenticationContext: authenticationContext,
                            completion: { actionStatus, _, error in
                                Task { await confirmationChallenge?.complete() }
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
                        setupIntentParams.radarOptions = radarOptions
                        setupIntentParams.clientAttributionMetadata = clientAttributionMetadata
                        paymentHandler.confirmSetupIntent(
                            params: setupIntentParams,
                            authenticationContext: authenticationContext,
                            completion: { actionStatus, _, error in
                                Task { await confirmationChallenge?.complete() }
                                if actionStatus == .succeeded {
                                    linkAccount?.logout()
                                }
                                paymentHandlerCompletion(actionStatus, error)
                            }
                        )
                    case .deferredIntent(let intentConfig):
                        Task { @MainActor in
                            let result = await routeDeferredIntentConfirmation(
                                confirmType: .saved(paymentMethod, paymentOptions: nil, clientAttributionMetadata: clientAttributionMetadata, radarOptions: radarOptions),
                                configuration: configuration,
                                intentConfig: intentConfig,
                                authenticationContext: authenticationContext,
                                paymentHandler: paymentHandler,
                                isFlowController: isFlowController,
                                elementsSession: elementsSession
                            )
                            if shouldLogOutOfLink(result: result.result, elementsSession: elementsSession) {
                                linkAccount?.logout()
                            }
                            await confirmationChallenge?.complete()
                            completion(result.result, result.deferredIntentConfirmationType)
                        }
                    }
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
                    paymentMethodParams.clientAttributionMetadata = clientAttributionMetadata
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
                                    billingPhoneNumber: billingPhoneNumber,
                                    clientAttributionMetadata: clientAttributionMetadata
                                ) { result in
                                    switch result {
                                    case .success(let paymentDetailsShareResponse):
                                        confirmWithPaymentMethod(paymentDetailsShareResponse.paymentMethod, linkAccount, shouldSave, clientAttributionMetadata)
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
                    let linkController = PayWithNativeLinkController(mode: .full, intent: intent, elementsSession: elementsSession, configuration: configuration, logPayment: true, analyticsHelper: analyticsHelper, confirmationChallenge: confirmationChallenge)
                    linkController.presentAsBottomSheet(from: authenticationContext.authenticationPresentingViewController(), shouldOfferApplePay: false, shouldFinishOnClose: false, completion: { result, confirmationType, _ in
                        completion(result, confirmationType)
                    })
                } else {
                    let linkController = PayWithLinkController(intent: intent, elementsSession: elementsSession, configuration: configuration, analyticsHelper: analyticsHelper, confirmationChallenge: confirmationChallenge)
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
                            isSettingUp: isSettingUp(linkPaymentMethodType)
                        )
                        createPaymentDetailsAndConfirm(linkAccount, intentConfirmParams.paymentMethodParams, intentConfirmParams.saveForFutureUseCheckboxState == .selected)
                    case .failure(let error as NSError):
                        STPAnalyticsClient.sharedClient.logLinkSignupFailure(error: error)
                        // Attempt to confirm directly with params as a fallback.
                        intentConfirmParams.setAllowRedisplay(
                            mobilePaymentElementFeatures: elementsSession.customerSessionMobilePaymentElementFeatures,
                            isSettingUp: isSettingUp(intentConfirmParams.paymentMethodParams.type)
                        )
                        confirmWithPaymentMethodParams(intentConfirmParams.paymentMethodParams, linkAccount, intentConfirmParams.saveForFutureUseCheckboxState == .selected)
                    }
                }
            case .withPaymentMethod(let paymentMethod):
                confirmWithPaymentMethod(paymentMethod, nil, false, clientAttributionMetadata) // from Link web controller
            case .withPaymentDetails(let linkAccount, let paymentDetails, let confirmationExtras, _):
                let shouldSave = false // always false, as we don't show a save-to-merchant checkbox in Link VC
                let allowRedisplay = paymentDetails.computeAllowRedisplay(
                    elementsSession: elementsSession,
                    isSettingUp: isSettingUp
                )

                if elementsSession.linkPassthroughModeEnabled {
                    linkAccount.sharePaymentDetails(
                        id: paymentDetails.stripeID,
                        cvc: paymentDetails.cvc,
                        allowRedisplay: allowRedisplay,
                        expectedPaymentMethodType: paymentDetails.expectedPaymentMethodTypeForPassthroughMode(elementsSession),
                        billingPhoneNumber: confirmationExtras?.billingPhoneNumber,
                        clientAttributionMetadata: clientAttributionMetadata
                    ) { result in
                        switch result {
                        case .success(let paymentDetailsShareResponse):
                            confirmWithPaymentMethod(paymentDetailsShareResponse.paymentMethod, linkAccount, shouldSave, clientAttributionMetadata)
                        case .failure(let error):
                            STPAnalyticsClient.sharedClient.logLinkSharePaymentDetailsFailure(error: error)
                            paymentHandlerCompletion(.failed, error as NSError)
                        }
                    }
                } else {
                    confirmWithPaymentDetails(linkAccount, paymentDetails, paymentDetails.cvc, confirmationExtras?.billingPhoneNumber, shouldSave, allowRedisplay)
                }
            }
        case let .external(externalPaymentOption, billingDetails):
            Task { @MainActor in
                // Call confirmHandler so that the merchant completes the payment
                let result = await externalPaymentOption.confirm(billingDetails: billingDetails)
                completion(result, nil)
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
        case saved(STPPaymentMethod, paymentOptions: STPConfirmPaymentMethodOptions?, clientAttributionMetadata: STPClientAttributionMetadata?, radarOptions: STPRadarOptions?)
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
    ) -> STPPaymentIntentConfirmParams {
        let params: STPPaymentIntentConfirmParams
        let shouldSave: Bool
        let paymentMethodType: STPPaymentMethodType
        switch confirmPaymentMethodType {
        case .saved(let paymentMethod, let paymentMethodOptions, let clientAttributionMetadata, let radarOptions):
            shouldSave = false
            paymentMethodType = paymentMethod.type
            params = STPPaymentIntentConfirmParams(clientSecret: paymentIntent.clientSecret, paymentMethodType: paymentMethod.type)
            params.paymentMethodOptions = paymentMethodOptions
            params.paymentMethodId = paymentMethod.stripeId
            params.radarOptions = radarOptions
            params.clientAttributionMetadata = clientAttributionMetadata
        case let .new(paymentMethodParams, paymentMethodoptions, paymentMethod, _shouldSave, shouldSetAsDefaultPM):
            shouldSave = _shouldSave
            if let paymentMethod = paymentMethod {
                paymentMethodType = paymentMethod.type
                params = STPPaymentIntentConfirmParams(clientSecret: paymentIntent.clientSecret, paymentMethodType: paymentMethod.type)
                params.paymentMethodId = paymentMethod.stripeId
                params.paymentMethodOptions = paymentMethodoptions
            } else {
                params = STPPaymentIntentConfirmParams(clientSecret: paymentIntent.clientSecret)
                params.paymentMethodParams = paymentMethodParams
                params.paymentMethodOptions = paymentMethodoptions
                paymentMethodType = paymentMethodParams.type
            }
            // Send CAM at the top-level of all requests in scope for consistency
            // Also send under payment_method_data because there are existing dependencies
            params.clientAttributionMetadata = paymentMethodParams.clientAttributionMetadata
            if let shouldSetAsDefaultPM {
                params.setAsDefaultPM = NSNumber(value: shouldSetAsDefaultPM)
            }
            let isSetupFutureUsageOffSession = paymentIntent.setupFutureUsage(for: paymentMethodType) == "off_session"
            if STPPaymentMethodType.requiresMandateDataForPaymentIntent.contains(paymentMethodType) && isSetupFutureUsageOffSession
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
        case let .saved(paymentMethod, _, clientAttributionMetadata, radarOptions):
            params = STPSetupIntentConfirmParams(
                clientSecret: setupIntent.clientSecret,
                paymentMethodType: paymentMethod.type
            )
            params.paymentMethodID = paymentMethod.stripeId
            params.radarOptions = radarOptions
            params.clientAttributionMetadata = clientAttributionMetadata
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
            // Send CAM at the top-level of all requests in scope for consistency
            // Also send under payment_method_data because there are existing dependencies
            params.clientAttributionMetadata = paymentMethodParams.clientAttributionMetadata
            if let shouldSetAsDefaultPM {
                params.setAsDefaultPM = NSNumber(value: shouldSetAsDefaultPM)
            }
            // These payment methods require mandate_data if setting up
            if let paymentMethodType = params.paymentMethodType, STPPaymentMethodType.requiresMandateDataForSetupIntent.contains(paymentMethodType) {
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

    private static func shouldLogOutOfLink(
        result: PaymentSheetResult,
        elementsSession: STPElementsSession
    ) -> Bool {
        guard case .completed = result else {
            return false
        }
        // Only log out non-verified merchants.
        return elementsSession.linkSettings?.useAttestationEndpoints != true
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

    var bankAccountDetails: ConsumerPaymentDetails.Details.BankAccount? {
        switch details {
        case .bankAccount(let bankAccount):
            return bankAccount
        case .card, .unparsable:
            return nil
        }
    }

    func expectedPaymentMethodTypeForPassthroughMode(
        _ elementsSession: STPElementsSession
    ) -> String? {
        switch type {
        case .card:
            return "card"
        case .unparsable:
            return nil
        case .bankAccount:
            return elementsSession.useCardPaymentMethodTypeForIBP ? "card" : "bank_account"
        }
    }

    func computeAllowRedisplay(
        elementsSession: STPElementsSession,
        isSettingUp: (STPPaymentMethodType) -> Bool
    ) -> STPPaymentMethodAllowRedisplay? {
        let paymentMethodType: STPPaymentMethodType = {
            if elementsSession.linkPassthroughModeEnabled {
                let expectedPaymentMethodType = expectedPaymentMethodTypeForPassthroughMode(elementsSession)

                if expectedPaymentMethodType == "bank_account" {
                    return bankAccountDetails?.asPassthroughPaymentMethodType ?? .unknown
                } else if expectedPaymentMethodType == "card" {
                    return .card
                } else {
                    return .unknown
                }
            } else {
                return .link
            }
        }()

        return elementsSession.computeAllowRedisplay(isSettingUp: isSettingUp(paymentMethodType))
    }
}
