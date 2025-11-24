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
        tokenType: String?
    ) {
        log(
            analytic: GenericPaymentAnalytic(
                event: .tokenCreation,
                additionalParams: [
                    "token_type": tokenType ?? "unknown",
                ]
            )
        )
    }

    func logSourceCreationAttempt(
        sourceType: String?
    ) {
        log(
            analytic: GenericPaymentAnalytic(
                event: .sourceCreation,
                additionalParams: [
                    "source_type": sourceType ?? "unknown",
                ]
            )
        )
    }

    func logPaymentMethodCreationAttempt(
        paymentMethodType: String?,
        apiClient: STPAPIClient
    ) {
        log(
            analytic: GenericPaymentAnalytic(
                event: .paymentMethodCreation,
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
                additionalParams: [:]
            )
        )
    }

    func logConfirmationTokenCreationAttempt() {
        log(
            analytic: GenericPaymentAnalytic(
                event: .confirmationTokenCreation,
                additionalParams: [:]
            )
        )
    }
}

// MARK: - Confirmation
extension STPAnalyticsClient {
    func logPaymentIntentConfirmationAttempt(
        paymentMethodType: String?,
        apiClient: STPAPIClient
    ) {
        log(
            analytic: GenericPaymentAnalytic(
                event: .paymentMethodIntentCreation,
                additionalParams: [
                    "source_type": paymentMethodType ?? "unknown",
                ]
            ),
            apiClient: apiClient
        )
    }

    func logSetupIntentConfirmationAttempt(
        paymentMethodType: String?,
        apiClient: STPAPIClient
    ) {
        log(
            analytic: GenericPaymentAnalytic(
                event: .setupIntentConfirmationAttempt,
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
        intentID: String,
        error: NSError
    ) {
        log(
            analytic: GenericPaymentErrorAnalytic(
                event: ._3DS2AuthenticationRequestParamsFailed,
                additionalParams: [
                    "intent_id": intentID,
                ],
                error: error
            )
        )
    }

    func log3DS2AuthenticateAttempt(
        intentID: String
    ) {
        log(
            analytic: GenericPaymentAnalytic(
                event: ._3DS2AuthenticationAttempt,
                additionalParams: [
                    "intent_id": intentID,
                ]
            )
        )
    }

    func log3DS2FrictionlessFlow(
        intentID: String
    ) {
        log(
            analytic: GenericPaymentAnalytic(
                event: ._3DS2FrictionlessFlow,
                additionalParams: [
                    "intent_id": intentID,
                ]
            )
        )
    }

    func log3DS2ChallengeFlowPresented(
        intentID: String,
        uiType: String
    ) {
        log(
            analytic: GenericPaymentAnalytic(
                event: ._3DS2ChallengeFlowPresented,
                additionalParams: [
                    "intent_id": intentID,
                    "3ds2_ui_type": uiType,
                ]
            )
        )
    }

    func log3DS2ChallengeFlowTimedOut(
        intentID: String,
        uiType: String
    ) {
        log(
            analytic: GenericPaymentAnalytic(
                event: ._3DS2ChallengeFlowTimedOut,
                additionalParams: [
                    "intent_id": intentID,
                    "3ds2_ui_type": uiType,
                ]
            )
        )
    }

    func log3DS2ChallengeFlowUserCanceled(
        intentID: String,
        uiType: String
    ) {
        log(
            analytic: GenericPaymentAnalytic(
                event: ._3DS2ChallengeFlowUserCanceled,
                additionalParams: [
                    "intent_id": intentID,
                    "3ds2_ui_type": uiType,
                ]
            )
        )
    }

    func log3DS2RedirectUserCanceled(
        intentID: String
    ) {
        log(
            analytic: GenericPaymentAnalytic(
                event: ._3DS2RedirectUserCanceled,
                additionalParams: [
                    "intent_id": intentID,
                ]
            )
        )
    }

    func log3DS2ChallengeFlowCompleted(
        intentID: String,
        uiType: String
    ) {
        log(
            analytic: GenericPaymentAnalytic(
                event: ._3DS2ChallengeFlowCompleted,
                additionalParams: [
                    "intent_id": intentID,
                    "3ds2_ui_type": uiType,
                ]
            )
        )
    }

    func log3DS2ChallengeFlowErrored(
        intentID: String,
        error: NSError
    ) {
        log(
            analytic: GenericPaymentErrorAnalytic(
                event: ._3DS2ChallengeFlowErrored,
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
                additionalParams: [:]
            )
        )
    }

    func logCardMetadataResponseFailure() {
        log(
            analytic: GenericPaymentAnalytic(
                event: .cardMetadataResponseFailure,
                additionalParams: [:]
            )
        )
    }

    func logCardMetadataMissingRange() {
        log(
            analytic: GenericPaymentAnalytic(
                event: .cardMetadataMissingRange,
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
