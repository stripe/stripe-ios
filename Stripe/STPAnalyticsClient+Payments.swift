//
//  STPAnalyticsClient+Payments.swift
//  StripeiOS
//
//  Created by Mel Ludowise on 5/26/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

extension STPAnalyticsClient {
    class func serializeConfiguration(_ configuration: STPPaymentConfiguration) -> [String:
        String]
    {
        var dictionary: [String: String] = [:]
        dictionary["publishable_key"] = STPAPIClient.shared.publishableKey ?? "unknown"

        if configuration.applePayEnabled && !configuration.fpxEnabled {
            dictionary["additional_payment_methods"] = "default"
        } else if !configuration.applePayEnabled && !configuration.fpxEnabled {
            dictionary["additional_payment_methods"] = "none"
        } else if !configuration.applePayEnabled && configuration.fpxEnabled {
            dictionary["additional_payment_methods"] = "fpx"
        } else if configuration.applePayEnabled && configuration.fpxEnabled {
            dictionary["additional_payment_methods"] = "applepay,fpx"
        }

        switch configuration.requiredBillingAddressFields {
        case .none:
            dictionary["required_billing_address_fields"] = "none"
        case .postalCode:
            dictionary["required_billing_address_fields"] = "zip"
        case .full:
            dictionary["required_billing_address_fields"] = "full"
        case .name:
            dictionary["required_billing_address_fields"] = "name"
        default:
            fatalError()
        }

        var shippingFields: [String] = []
        if let shippingAddressFields = configuration.requiredShippingAddressFields {
            if shippingAddressFields.contains(.name) {
                shippingFields.append("name")
            }
            if shippingAddressFields.contains(.emailAddress) {
                shippingFields.append("email")
            }
            if shippingAddressFields.contains(.postalAddress) {
                shippingFields.append("address")
            }
            if shippingAddressFields.contains(.phoneNumber) {
                shippingFields.append("phone")
            }
        }

        if shippingFields.isEmpty {
            shippingFields.append("none")
        }
        dictionary["required_shipping_address_fields"] = shippingFields.joined(separator: "_")

        switch configuration.shippingType {
        case .shipping:
            dictionary["shipping_type"] = "shipping"
        case .delivery:
            dictionary["shipping_type"] = "delivery"
        }

        dictionary["company_name"] = configuration.companyName
        dictionary["apple_merchant_identifier"] = configuration.appleMerchantIdentifier ?? "unknown"
        return dictionary
    }

    /**
     Generates a UI usage string based on any payment UI element classes being used by the app.
     */
    class func uiUsageLevelString(from productUsage: Set<String>) -> String {
        let uiUsageLevel: String
        if productUsage.contains(STPPaymentContext.stp_analyticsIdentifier) {
            uiUsageLevel = "full"
        } else if productUsage.count == 1
                    && productUsage.contains(STPPaymentCardTextField.stp_analyticsIdentifier)
        {
            uiUsageLevel = "card_text_field"
        } else if productUsage.count > 0 {
            uiUsageLevel = "partial"
        } else {
            uiUsageLevel = "none"
        }
        return uiUsageLevel
    }

    class func ocrTypeString() -> String {
        if #available(iOS 13.0, macCatalyst 14.0, *) {
            if STPAnalyticsClient.sharedClient.productUsage.contains(
                STPCardScanner.stp_analyticsIdentifier)
            {
                return "stripe"
            }
        }
        return "none"
    }
}

// MARK: - Creation
extension STPAnalyticsClient {
    func logTokenCreationAttempt(
        with configuration: STPPaymentConfiguration,
        tokenType: String?
    ) {
        log(analytic: GenericPaymentAnalytic(
            event: .tokenCreation,
            paymentConfiguration: configuration,
            productUsage: productUsage,
            additionalParams: [
                "token_type": tokenType ?? "unknown"
            ]
        ))
    }

    func logSourceCreationAttempt(
        with configuration: STPPaymentConfiguration,
        sourceType: String?
    ) {
        log(analytic: GenericPaymentAnalytic(
            event: .sourceCreation,
            paymentConfiguration: configuration,
            productUsage: productUsage,
            additionalParams: [
                "source_type": sourceType ?? "unknown"
            ]
        ))
    }

    func logPaymentMethodCreationAttempt(
        with configuration: STPPaymentConfiguration,
        paymentMethodType: String?
    ) {
        log(analytic: GenericPaymentAnalytic(
            event: .paymentMethodCreation,
            paymentConfiguration: configuration,
            productUsage: productUsage,
            additionalParams: [
                "source_type": paymentMethodType ?? "unknown"
            ]
        ))
    }
}

// MARK: - Confirmation
extension STPAnalyticsClient {
    func logPaymentIntentConfirmationAttempt(
        with configuration: STPPaymentConfiguration,
        paymentMethodType: String?
    ) {
        log(analytic: GenericPaymentAnalytic(
            event: .paymentMethodIntentCreation,
            paymentConfiguration: configuration,
            productUsage: productUsage,
            additionalParams: [
                "source_type": paymentMethodType ?? "unknown"
            ]
        ))
    }

    func logSetupIntentConfirmationAttempt(
        with configuration: STPPaymentConfiguration,
        paymentMethodType: String?
    ) {
        log(analytic: GenericPaymentAnalytic(
            event: .setupIntentConfirmationAttempt,
            paymentConfiguration: configuration,
            productUsage: productUsage,
            additionalParams: [
                "source_type": paymentMethodType ?? "unknown"
            ]
        ))
    }
}

// MARK: - 3DS2 Flow
extension STPAnalyticsClient {
    func log3DS2AuthenticateAttempt(
        with configuration: STPPaymentConfiguration,
        intentID: String
    ) {
        log(analytic: GenericPaymentAnalytic(
            event: ._3DS2AuthenticationAttempt,
            paymentConfiguration: configuration,
            productUsage: productUsage,
            additionalParams: [
                "intent_id": intentID
            ]
        ))
    }

    func log3DS2FrictionlessFlow(
        with configuration: STPPaymentConfiguration,
        intentID: String
    ) {
        log(analytic: GenericPaymentAnalytic(
            event: ._3DS2FrictionlessFlow,
            paymentConfiguration: configuration,
            productUsage: productUsage,
            additionalParams: [
                "intent_id": intentID
            ]
        ))
    }

    func logURLRedirectNextAction(
        with configuration: STPPaymentConfiguration,
        intentID: String
    ) {
        log(analytic: GenericPaymentAnalytic(
            event: .urlRedirectNextAction,
            paymentConfiguration: configuration,
            productUsage: productUsage,
            additionalParams: [
                "intent_id": intentID
            ]
        ))
    }

    func log3DS2ChallengeFlowPresented(
        with configuration: STPPaymentConfiguration,
        intentID: String,
        uiType: String
    ) {
        log(analytic: GenericPaymentAnalytic(
            event: ._3DS2ChallengeFlowPresented,
            paymentConfiguration: configuration,
            productUsage: productUsage,
            additionalParams: [
                "intent_id": intentID,
                "3ds2_ui_type": uiType
            ]
        ))
    }

    func log3DS2ChallengeFlowTimedOut(
        with configuration: STPPaymentConfiguration,
        intentID: String,
        uiType: String
    ) {
        log(analytic: GenericPaymentAnalytic(
            event: ._3DS2ChallengeFlowTimedOut,
            paymentConfiguration: configuration,
            productUsage: productUsage,
            additionalParams: [
                "intent_id": intentID,
                "3ds2_ui_type": uiType
            ]
        ))
    }

    func log3DS2ChallengeFlowUserCanceled(
        with configuration: STPPaymentConfiguration,
        intentID: String,
        uiType: String
    ) {
        log(analytic: GenericPaymentAnalytic(
            event: ._3DS2ChallengeFlowUserCanceled,
            paymentConfiguration: configuration,
            productUsage: productUsage,
            additionalParams: [
                "intent_id": intentID,
                "3ds2_ui_type": uiType
            ]
        ))
    }

    func log3DS2ChallengeFlowCompleted(
        with configuration: STPPaymentConfiguration,
        intentID: String,
        uiType: String
    ) {
        log(analytic: GenericPaymentAnalytic(
            event: ._3DS2ChallengeFlowCompleted,
            paymentConfiguration: configuration,
            productUsage: productUsage,
            additionalParams: [
                "intent_id": intentID,
                "3ds2_ui_type": uiType
            ]
        ))
    }

    func log3DS2ChallengeFlowErrored(
        with configuration: STPPaymentConfiguration,
        intentID: String,
        error: NSError
    ) {
        log(analytic: GenericPaymentAnalytic(
            event: ._3DS2ChallengeFlowErrored,
            paymentConfiguration: configuration,
            productUsage: productUsage,
            additionalParams: [
                "intent_id": intentID,
                "error_dictionary": type(of: self).serializeError(error)
            ]
        ))
    }
}

// MARK: - Card Metadata
extension STPAnalyticsClient {
    func logUserEnteredCompletePANBeforeMetadataLoaded(with configuration: STPPaymentConfiguration)
    {
        log(analytic: GenericPaymentAnalytic(
            event: .cardMetadataLoadedTooSlow,
            paymentConfiguration: configuration,
            productUsage: productUsage,
            additionalParams: [:]
        ))
    }

    func logCardMetadataResponseFailure(with configuration: STPPaymentConfiguration) {
        log(analytic: GenericPaymentAnalytic(
            event: .cardMetadataResponseFailure,
            paymentConfiguration: configuration,
            productUsage: productUsage,
            additionalParams: [:]
        ))
    }

    func logCardMetadataMissingRange(with configuration: STPPaymentConfiguration) {
        log(analytic: GenericPaymentAnalytic(
            event: .cardMetadataMissingRange,
            paymentConfiguration: configuration,
            productUsage: productUsage,
            additionalParams: [:]
        ))
    }
}

// MARK: - Card Scanning
extension STPAnalyticsClient {
    func logCardScanSucceeded(withDuration duration: TimeInterval) {
        log(analytic: GenericAnalytic(
            event: .cardScanSucceeded,
            params: [
                "duration": NSNumber(value: round(duration))
            ]
        ))
    }

    func logCardScanCancelled(withDuration duration: TimeInterval) {
        log(analytic: GenericAnalytic(
            event: .cardScanCancelled,
            params: [
                "duration": NSNumber(value: round(duration))
            ]
        ))
    }
}
