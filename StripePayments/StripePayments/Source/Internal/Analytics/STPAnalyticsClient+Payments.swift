//
//  STPAnalyticsClient+Payments.swift
//  StripePayments
//
//  Created by Mel Ludowise on 5/26/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

// MARK: - Creation
extension STPAnalyticsClient {
    func logTokenCreationAttempt(
        with configuration: NSObject?,
        tokenType: String?
    ) {
        log(
            analytic: GenericPaymentAnalytic(
                event: .tokenCreation,
                paymentConfiguration: configuration,
                additionalParams: [
                    "token_type": tokenType ?? "unknown",
                ]
            )
        )
    }

    func logSourceCreationAttempt(
        with configuration: NSObject?,
        sourceType: String?
    ) {
        log(
            analytic: GenericPaymentAnalytic(
                event: .sourceCreation,
                paymentConfiguration: configuration,
                additionalParams: [
                    "source_type": sourceType ?? "unknown",
                ]
            )
        )
    }

    func logPaymentMethodCreationAttempt(
        with configuration: NSObject?,
        paymentMethodType: String?,
        apiClient: STPAPIClient
    ) {
        log(
            analytic: GenericPaymentAnalytic(
                event: .paymentMethodCreation,
                paymentConfiguration: configuration,
                additionalParams: [
                    "source_type": paymentMethodType ?? "unknown",
                ]
            ),
            apiClient: apiClient
        )
    }

    func logPaymentMethodUpdateAttempt(
        with configuration: NSObject?
    ) {
        log(
            analytic: GenericPaymentAnalytic(
                event: .paymentMethodUpdate,
                paymentConfiguration: configuration,
                additionalParams: [:]
            )
        )
    }
}

// MARK: - Confirmation
extension STPAnalyticsClient {
    func logPaymentIntentConfirmationAttempt(
        with configuration: NSObject?,
        paymentMethodType: String?,
        apiClient: STPAPIClient
    ) {
        log(
            analytic: GenericPaymentAnalytic(
                event: .paymentMethodIntentCreation,
                paymentConfiguration: configuration,
                additionalParams: [
                    "source_type": paymentMethodType ?? "unknown",
                ]
            ),
            apiClient: apiClient
        )
    }

    func logSetupIntentConfirmationAttempt(
        with configuration: NSObject?,
        paymentMethodType: String?,
        apiClient: STPAPIClient
    ) {
        log(
            analytic: GenericPaymentAnalytic(
                event: .setupIntentConfirmationAttempt,
                paymentConfiguration: configuration,
                additionalParams: [
                    "source_type": paymentMethodType ?? "unknown",
                ]
            ),
            apiClient: apiClient
        )
    }
}

// MARK: - 3DS2 Flow
extension STPAnalyticsClient {
    func log3DS2AuthenticationRequestParamsFailed(
        with configuration: NSObject?,
        intentID: String,
        error: NSError
    ) {
        log(
            analytic: GenericPaymentErrorAnalytic(
                event: ._3DS2AuthenticationRequestParamsFailed,
                paymentConfiguration: configuration,
                additionalParams: [
                    "intent_id": intentID,
                ],
                error: error
            )
        )
    }

    func log3DS2AuthenticateAttempt(
        with configuration: NSObject?,
        intentID: String
    ) {
        log(
            analytic: GenericPaymentAnalytic(
                event: ._3DS2AuthenticationAttempt,
                paymentConfiguration: configuration,
                additionalParams: [
                    "intent_id": intentID,
                ]
            )
        )
    }

    func log3DS2FrictionlessFlow(
        with configuration: NSObject?,
        intentID: String
    ) {
        log(
            analytic: GenericPaymentAnalytic(
                event: ._3DS2FrictionlessFlow,
                paymentConfiguration: configuration,
                additionalParams: [
                    "intent_id": intentID,
                ]
            )
        )
    }

    func logURLRedirectNextAction(
        with configuration: NSObject?,
        intentID: String?,
        usesWebAuthSession: Bool
    ) {
        logURLRedirectNextAction(with: configuration, intentID: intentID, usesWebAuthSession: usesWebAuthSession, isComplete: false)
    }

    func logURLRedirectNextActionCompleted(
        with configuration: NSObject?,
        intentID: String?,
        usesWebAuthSession: Bool
    ) {
        logURLRedirectNextAction(with: configuration, intentID: intentID, usesWebAuthSession: usesWebAuthSession, isComplete: true)
    }

    func logURLRedirectNextAction(
        with configuration: NSObject?,
        intentID: String?,
        usesWebAuthSession: Bool,
        isComplete: Bool
    ) {
        var params: [String: Any] = ["redirect_type": usesWebAuthSession ? "SFVC" : "ASWAS"]
        if let intentID {
            params["intent_id"] = intentID
        }
        log(
            analytic: GenericPaymentAnalytic(
                event: isComplete ? .urlRedirectNextActionCompleted : .urlRedirectNextAction,
                paymentConfiguration: configuration,
                additionalParams: params
            )
        )
    }

    func log3DS2ChallengeFlowPresented(
        with configuration: NSObject?,
        intentID: String,
        uiType: String
    ) {
        log(
            analytic: GenericPaymentAnalytic(
                event: ._3DS2ChallengeFlowPresented,
                paymentConfiguration: configuration,
                additionalParams: [
                    "intent_id": intentID,
                    "3ds2_ui_type": uiType,
                ]
            )
        )
    }

    func log3DS2ChallengeFlowTimedOut(
        with configuration: NSObject?,
        intentID: String,
        uiType: String
    ) {
        log(
            analytic: GenericPaymentAnalytic(
                event: ._3DS2ChallengeFlowTimedOut,
                paymentConfiguration: configuration,
                additionalParams: [
                    "intent_id": intentID,
                    "3ds2_ui_type": uiType,
                ]
            )
        )
    }

    func log3DS2ChallengeFlowUserCanceled(
        with configuration: NSObject?,
        intentID: String,
        uiType: String
    ) {
        log(
            analytic: GenericPaymentAnalytic(
                event: ._3DS2ChallengeFlowUserCanceled,
                paymentConfiguration: configuration,
                additionalParams: [
                    "intent_id": intentID,
                    "3ds2_ui_type": uiType,
                ]
            )
        )
    }

    func log3DS2RedirectUserCanceled(
        with configuration: NSObject?,
        intentID: String
    ) {
        log(
            analytic: GenericPaymentAnalytic(
                event: ._3DS2RedirectUserCanceled,
                paymentConfiguration: configuration,
                additionalParams: [
                    "intent_id": intentID,
                ]
            )
        )
    }

    func log3DS2ChallengeFlowCompleted(
        with configuration: NSObject?,
        intentID: String,
        uiType: String
    ) {
        log(
            analytic: GenericPaymentAnalytic(
                event: ._3DS2ChallengeFlowCompleted,
                paymentConfiguration: configuration,
                additionalParams: [
                    "intent_id": intentID,
                    "3ds2_ui_type": uiType,
                ]
            )
        )
    }

    func log3DS2ChallengeFlowErrored(
        with configuration: NSObject?,
        intentID: String,
        error: NSError
    ) {
        log(
            analytic: GenericPaymentErrorAnalytic(
                event: ._3DS2ChallengeFlowErrored,
                paymentConfiguration: configuration,
                additionalParams: [
                    "intent_id": intentID,
                ],
                error: error
            )
        )
    }
}

// MARK: - Card Metadata
extension STPAnalyticsClient {
    @_spi(STP) public func logUserEnteredCompletePANBeforeMetadataLoaded() {
        log(
            analytic: GenericPaymentAnalytic(
                event: .cardMetadataLoadedTooSlow,
                paymentConfiguration: nil,
                additionalParams: [:]
            )
        )
    }

    func logCardMetadataResponseFailure() {
        log(
            analytic: GenericPaymentAnalytic(
                event: .cardMetadataResponseFailure,
                paymentConfiguration: nil,
                additionalParams: [:]
            )
        )
    }

    func logCardMetadataMissingRange() {
        log(
            analytic: GenericPaymentAnalytic(
                event: .cardMetadataMissingRange,
                paymentConfiguration: nil,
                additionalParams: [:]
            )
        )
    }

    @_spi(STP) public func logCardMetadataExpectedExtraDigitsButUserEntered16ThenSwitchedFields() {
        log(
            analytic: GenericPaymentAnalytic(
                event: .cardMetadataExpectedExtraDigitsButUserEntered16ThenSwitchedFields,
                paymentConfiguration: nil,
                additionalParams: [:]
            )
        )
    }
}

// MARK: - Card Scanning
extension STPAnalyticsClient {
    @_spi(STP) public func logCardScanSucceeded(withDuration duration: TimeInterval) {
        log(
            analytic: GenericAnalytic(
                event: .cardScanSucceeded,
                params: [
                    "duration": NSNumber(value: round(duration)),
                ]
            )
        )
    }

    @_spi(STP) public func logCardScanCancelled(withDuration duration: TimeInterval) {
        log(
            analytic: GenericAnalytic(
                event: .cardScanCancelled,
                params: [
                    "duration": NSNumber(value: round(duration)),
                ]
            )
        )
    }
}

// MARK: - Card Element Config
extension STPAnalyticsClient {
    @_spi(STP) public func logCardElementConfigLoadFailed() {
        log(
            analytic: GenericPaymentAnalytic(
                event: .cardElementConfigLoadFailure,
                paymentConfiguration: nil,
                additionalParams: [:]
            )
        )
    }
}

/// An analytic specific to payments that serializes payment-specific
/// information into its params.
@_spi(STP) public protocol PaymentAnalytic: Analytic {
    var additionalParams: [String: Any] { get }
}

@_spi(STP) extension PaymentAnalytic {
    public var params: [String: Any] {
        var params = additionalParams

        params["apple_pay_enabled"] = NSNumber(value: StripeAPI.deviceSupportsApplePay())
        params["ocr_type"] = PaymentsSDKVariant.ocrTypeString
        params["pay_var"] = PaymentsSDKVariant.variant
        return params
    }
}
