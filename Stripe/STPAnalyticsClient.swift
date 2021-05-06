//
//  STPAnalyticsClient.swift
//  Stripe
//
//  Created by Ben Guo on 4/22/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

protocol STPAnalyticsProtocol {
    static var stp_analyticsIdentifier: String { get }
}

protocol STPAnalyticsClientProtocol {
    func addClass<T: STPAnalyticsProtocol>(toProductUsageIfNecessary klass: T.Type)
    func log(analytic: Analytic)
}

class STPAnalyticsClient: NSObject, STPAnalyticsClientProtocol {
    @objc static let sharedClient = STPAnalyticsClient()

    @objc internal var productUsage: Set<String> = Set()
    private var additionalInfoSet: Set<String> = Set()
    private(set) var urlSession: URLSession = URLSession(
        configuration: STPAPIClient.sharedUrlSessionConfiguration)

    @objc class func tokenType(fromParameters parameters: [AnyHashable: Any]) -> String? {
        let parameterKeys = parameters.keys

        // these are currently mutually exclusive, so we can just run through and find the first match
        let tokenTypes = ["account", "bank_account", "card", "pii", "cvc_update"]
        if let type = tokenTypes.first(where: { parameterKeys.contains($0) }) {
            return type
        } else {
            return parameterKeys.contains("pk_token") ? "apple_pay" : nil
        }
    }

    func addClass<T: STPAnalyticsProtocol>(toProductUsageIfNecessary klass: T.Type) {
        objc_sync_enter(self)
        _ = productUsage.insert(klass.stp_analyticsIdentifier)
        objc_sync_exit(self)
    }

    func addAdditionalInfo(_ info: String) {
        _ = additionalInfoSet.insert(info)
    }

    func clearAdditionalInfo() {
        additionalInfoSet.removeAll()
    }

    // MARK: - Card Scanning

    @objc class func shouldCollectAnalytics() -> Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        return NSClassFromString("XCTest") == nil
        #endif
    }

    func additionalInfo() -> [String] {
        return additionalInfoSet.sorted()
    }

    func productUsageDictionary() -> [String: Any] {
        var usage: [String: Any] = [:]
        var productUsageCopy: Set<String>
        objc_sync_enter(self)
        productUsageCopy = productUsage
        objc_sync_exit(self)

        let uiUsageLevel: String
        if productUsageCopy.contains(STPPaymentContext.stp_analyticsIdentifier) {
            uiUsageLevel = "full"
        } else if productUsageCopy.count == 1
            && productUsageCopy.contains(STPPaymentCardTextField.stp_analyticsIdentifier)
        {
            uiUsageLevel = "card_text_field"
        } else if productUsageCopy.count > 0 {
            uiUsageLevel = "partial"
        } else {
            uiUsageLevel = "none"
        }
        usage["ui_usage_level"] = uiUsageLevel
        usage["product_usage"] = productUsage.sorted()

        return usage
    }

    func logPayload(_ payload: [String: Any]) {
        #if DEBUG
        NSLog("LOG ANALYTICS: \(payload)")
        #endif
        
        guard type(of: self).shouldCollectAnalytics(),
            let url = URL(string: "https://q.stripe.com")
        else {
            return
        }

        let request: NSMutableURLRequest = NSMutableURLRequest(url: url)

        request.stp_addParameters(toURL: payload)
        let task: URLSessionDataTask = urlSession.dataTask(with: request as URLRequest)
        task.resume()
    }

    /**
     Creates a payload dictionary for the given analytic that includes the event name, common payload,
     additional info, and product usage dictionary.

     - Parameter analytic: The analytic to log.
     */
    func payload(from analytic: Analytic) -> [String: Any] {
        var payload = type(of: self).commonPayload()

        payload["event"] = analytic.event.rawValue
        payload["additional_info"] = additionalInfo()

        payload.merge(analytic.params) { (_, new) in new }
        payload.merge(productUsageDictionary()) { (_, new) in new }
        return payload
    }

    /**
     Logs an analytic with a payload dictionary that includes the event name, common payload,
     additional info, and product usage dictionary.

     - Parameter analytic: The analytic to log.
     */
    func log(analytic: Analytic) {
        logPayload(payload(from: analytic))
    }
}

// MARK: - Helpers
extension STPAnalyticsClient {
    class func commonPayload() -> [String: Any] {
        var payload: [String: Any] = [:]
        payload["bindings_version"] = STPAPIClient.STPSDKVersion
        payload["analytics_ua"] = "analytics.stripeios-1.0"
        let version = UIDevice.current.systemVersion
        if !version.isEmpty {
            payload["os_version"] = version
        }
        var systemInfo: utsname = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let deviceType = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        if !deviceType.isEmpty {
            payload["device_type"] = deviceType
        }
        payload["app_name"] = Bundle.stp_applicationName() ?? ""
        payload["app_version"] = Bundle.stp_applicationVersion() ?? ""
        payload["apple_pay_enabled"] = NSNumber(value: StripeAPI.deviceSupportsApplePay())
        payload["ocr_type"] = "none"
        if #available(iOS 13.0, macCatalyst 14.0, *) {
            if STPAnalyticsClient.sharedClient.productUsage.contains(
                STPCardScanner.stp_analyticsIdentifier)
            {
                payload["ocr_type"] = "stripe"
            }
        }
        payload["publishable_key"] = STPAPIClient.shared.publishableKey ?? "unknown"
        
        return payload
    }

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

    class func serializeError(_ error: NSError) -> [String: Any] {
        // TODO(mludowise|MOBILESDK-193): Find a better solution than logging `userInfo`
        return [
            "domain": error.domain,
            "code": error.code,
            "user_info": error.userInfo,
        ]
    }
}

// MARK: - Creation
extension STPAnalyticsClient {
    @objc(logTokenCreationAttemptWithConfiguration:tokenType:)
    func logTokenCreationAttempt(
        with configuration: STPPaymentConfiguration,
        tokenType: String?
    ) {
        log(analytic: GenericPaymentAnalytic(
            event: .tokenCreation,
            paymentConfiguration: configuration,
            additionalParams: [
                "token_type": tokenType ?? "unknown"
            ]
        ))
    }

    @objc(logSourceCreationAttemptWithConfiguration:sourceType:)
    func logSourceCreationAttempt(
        with configuration: STPPaymentConfiguration,
        sourceType: String?
    ) {
        log(analytic: GenericPaymentAnalytic(
            event: .sourceCreation,
            paymentConfiguration: configuration,
            additionalParams: [
                "source_type": sourceType ?? "unknown"
            ]
        ))
    }

    @objc(logPaymentMethodCreationAttemptWithConfiguration:paymentMethodType:)
    func logPaymentMethodCreationAttempt(
        with configuration: STPPaymentConfiguration,
        paymentMethodType: String?
    ) {
        log(analytic: GenericPaymentAnalytic(
            event: .paymentMethodCreation,
            paymentConfiguration: configuration,
            additionalParams: [
                "source_type": paymentMethodType ?? "unknown"
            ]
        ))
    }
}

// MARK: - Confirmation
extension STPAnalyticsClient {
    @objc(logPaymentIntentConfirmationAttemptWithConfiguration:paymentMethodType:)
    func logPaymentIntentConfirmationAttempt(
        with configuration: STPPaymentConfiguration,
        paymentMethodType: String?
    ) {
        log(analytic: GenericPaymentAnalytic(
            event: .paymentMethodIntentCreation,
            paymentConfiguration: configuration,
            additionalParams: [
                "source_type": paymentMethodType ?? "unknown"
            ]
        ))
    }

    @objc(logSetupIntentConfirmationAttemptWithConfiguration:paymentMethodType:)
    func logSetupIntentConfirmationAttempt(
        with configuration: STPPaymentConfiguration,
        paymentMethodType: String?
    ) {
        log(analytic: GenericPaymentAnalytic(
            event: .setupIntentConfirmationAttempt,
            paymentConfiguration: configuration,
            additionalParams: [
                "source_type": paymentMethodType ?? "unknown"
            ]
        ))
    }
}

// MARK: - 3DS2 Flow
extension STPAnalyticsClient {
    @objc(log3DS2AuthenticateAttemptWithConfiguration:intentID:)
    func log3DS2AuthenticateAttempt(
        with configuration: STPPaymentConfiguration,
        intentID: String
    ) {
        log(analytic: GenericPaymentAnalytic(
            event: ._3DS2AuthenticationAttempt,
            paymentConfiguration: configuration,
            additionalParams: [
                "intent_id": intentID
            ]
        ))
    }

    @objc(log3DS2FrictionlessFlowWithConfiguration:intentID:)
    func log3DS2FrictionlessFlow(
        with configuration: STPPaymentConfiguration,
        intentID: String
    ) {
        log(analytic: GenericPaymentAnalytic(
            event: ._3DS2FrictionlessFlow,
            paymentConfiguration: configuration,
            additionalParams: [
                "intent_id": intentID
            ]
        ))
    }

    @objc(logURLRedirectNextActionWithConfiguration:intentID:)
    func logURLRedirectNextAction(
        with configuration: STPPaymentConfiguration,
        intentID: String
    ) {
        log(analytic: GenericPaymentAnalytic(
            event: .urlRedirectNextAction,
            paymentConfiguration: configuration,
            additionalParams: [
                "intent_id": intentID
            ]
        ))
    }

    @objc(log3DS2ChallengeFlowPresentedWithConfiguration:intentID:uiType:)
    func log3DS2ChallengeFlowPresented(
        with configuration: STPPaymentConfiguration,
        intentID: String,
        uiType: String
    ) {
        log(analytic: GenericPaymentAnalytic(
            event: ._3DS2ChallengeFlowPresented,
            paymentConfiguration: configuration,
            additionalParams: [
                "intent_id": intentID,
                "3ds2_ui_type": uiType
            ]
        ))
    }

    @objc(log3DS2ChallengeFlowTimedOutWithConfiguration:intentID:uiType:)
    func log3DS2ChallengeFlowTimedOut(
        with configuration: STPPaymentConfiguration,
        intentID: String,
        uiType: String
    ) {
        log(analytic: GenericPaymentAnalytic(
            event: ._3DS2ChallengeFlowTimedOut,
            paymentConfiguration: configuration,
            additionalParams: [
                "intent_id": intentID,
                "3ds2_ui_type": uiType
            ]
        ))
    }

    @objc(log3DS2ChallengeFlowUserCanceledWithConfiguration:intentID:uiType:)
    func log3DS2ChallengeFlowUserCanceled(
        with configuration: STPPaymentConfiguration,
        intentID: String,
        uiType: String
    ) {
        log(analytic: GenericPaymentAnalytic(
            event: ._3DS2ChallengeFlowUserCanceled,
            paymentConfiguration: configuration,
            additionalParams: [
                "intent_id": intentID,
                "3ds2_ui_type": uiType
            ]
        ))
    }

    @objc(log3DS2ChallengeFlowCompletedWithConfiguration:intentID:uiType:)
    func log3DS2ChallengeFlowCompleted(
        with configuration: STPPaymentConfiguration,
        intentID: String,
        uiType: String
    ) {
        log(analytic: GenericPaymentAnalytic(
            event: ._3DS2ChallengeFlowCompleted,
            paymentConfiguration: configuration,
            additionalParams: [
                "intent_id": intentID,
                "3ds2_ui_type": uiType
            ]
        ))
    }

    @objc(log3DS2ChallengeFlowErroredWithConfiguration:intentID:errorDictionary:)
    func log3DS2ChallengeFlowErrored(
        with configuration: STPPaymentConfiguration,
        intentID: String,
        error: NSError
    ) {
        log(analytic: GenericPaymentAnalytic(
            event: ._3DS2ChallengeFlowErrored,
            paymentConfiguration: configuration,
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
            additionalParams: [:]
        ))
    }

    func logCardMetadataResponseFailure(with configuration: STPPaymentConfiguration) {
        log(analytic: GenericPaymentAnalytic(
            event: .cardMetadataResponseFailure,
            paymentConfiguration: configuration,
            additionalParams: [:]
        ))
    }

    func logCardMetadataMissingRange(with configuration: STPPaymentConfiguration) {
        log(analytic: GenericPaymentAnalytic(
            event: .cardMetadataMissingRange,
            paymentConfiguration: configuration,
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
