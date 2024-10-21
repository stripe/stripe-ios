//
//  PaymentSheetAnalyticsHelper.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 8/1/24.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

final class PaymentSheetAnalyticsHelper {
    let analyticsClient: STPAnalyticsClient
    let integrationShape: IntegrationShape
    let configuration: PaymentElementConfiguration

    // Vars set later as PaymentSheet successfully loads, etc.
    var intent: Intent?
    var elementsSession: STPElementsSession?
    var loadingStartDate: Date?
    private var startTimes: [TimeMeasurement: Date] = [:]

    enum IntegrationShape {
        case flowController
        case complete
        case embedded
    }

    init(
        integrationShape: IntegrationShape,
        configuration: PaymentElementConfiguration,
        analyticsClient: STPAnalyticsClient = .sharedClient
    ) {
        self.integrationShape = integrationShape
        self.configuration = configuration
        self.analyticsClient = analyticsClient
    }

    func logInitialized() {
        let event: STPAnalyticEvent = {
            switch integrationShape {
            case .flowController:
                switch (configuration.customer != nil, configuration.applePay != nil) {
                case (false, false):
                    return .mcInitCustomDefault
                case (true, false):
                    return .mcInitCustomCustomer
                case (false, true):
                    return .mcInitCustomApplePay
                case (true, true):
                    return .mcInitCustomCustomerApplePay
                }
            case .complete:
                switch (configuration.customer != nil, configuration.applePay != nil) {
                case (false, false):
                    return .mcInitCompleteDefault
                case (true, false):
                    return .mcInitCompleteCustomer
                case (false, true):
                    return .mcInitCompleteApplePay
                case (true, true):
                    return .mcInitCompleteCustomerApplePay
                }
            case .embedded:
                return .mcInitEmbedded
            }
        }()
        log(event: event)
    }

    func logLoadStarted() {
        loadingStartDate = Date()
        log(event: .paymentSheetLoadStarted)
    }

    func logLoadFailed(error: Error) {
        stpAssert(loadingStartDate != nil)
        let duration: TimeInterval = {
            guard let loadingStartDate else { return 0 }
            return Date().timeIntervalSince(loadingStartDate)
        }()
        log(
            event: .paymentSheetLoadFailed,
            duration: duration,
            error: error
        )
    }

    func logLoadSucceeded(
        intent: Intent,
        elementsSession: STPElementsSession,
        defaultPaymentMethod: SavedPaymentOptionsViewController.Selection?,
        orderedPaymentMethodTypes: [PaymentSheet.PaymentMethodType]
    ) {
        stpAssert(loadingStartDate != nil)
        self.intent = intent
        self.elementsSession = elementsSession
        let defaultPaymentMethodAnalyticsValue: String = {
            switch defaultPaymentMethod {
            case .applePay:
                return "apple_pay"
            case .link:
                return "link"
            case .saved(paymentMethod: let paymentMethod):
                return paymentMethod.type.identifier
            case nil:
                return "none"
            case .add:
                stpAssertionFailure("Caller should ensure that default payment method is `nil` in this case.")
                return "none"
            }
        }()
        var params: [String: Any] = [
            "selected_lpm": defaultPaymentMethodAnalyticsValue,
            "intent_type": intent.analyticsValue,
            "ordered_lpms": orderedPaymentMethodTypes.map({ $0.identifier }).joined(separator: ","),
        ]
        let linkEnabled: Bool = PaymentSheet.isLinkEnabled(elementsSession: elementsSession, configuration: configuration)
        if linkEnabled {
            let linkMode: String = elementsSession.linkPassthroughModeEnabled ? "passthrough" : "payment_method_mode"
            params["link_mode"] = linkMode
        }
        let duration: TimeInterval = {
            guard let loadingStartDate else { return 0 }
            return Date().timeIntervalSince(loadingStartDate)
        }()
        log(
            event: .paymentSheetLoadSucceeded,
            duration: duration,
            params: params
        )
    }

    func logShow(showingSavedPMList: Bool) {
        if case .embedded = integrationShape {
            stpAssertionFailure("logShow() is not supported for embedded integration")
            return
        }
        let isCustom = integrationShape == .flowController
        if !isCustom {
            startTimeMeasurement(.checkout)
        }
        let event: STPAnalyticEvent = {
            switch showingSavedPMList {
            case true:
                return isCustom ? .mcShowCustomSavedPM : .mcShowCompleteSavedPM
            case false:
                return isCustom ? .mcShowCustomNewPM : .mcShowCompleteNewPM
            }
        }()
        log(event: event)
    }

    func logSavedPMScreenOptionSelected(option: SavedPaymentOptionsViewController.Selection) {
        let (event, selectedLPM): (STPAnalyticEvent?, String?) = {
            switch integrationShape {
            case .flowController:
                switch option {
                case .add:
                    return (.mcOptionSelectCustomNewPM, nil)
                case .saved(let paymentMethod):
                    return (.mcOptionSelectCustomSavedPM, paymentMethod.type.identifier)
                case .applePay:
                    return (.mcOptionSelectCustomApplePay, nil)
                case .link:
                    return (.mcOptionSelectCustomLink, nil)
                }
            case .complete:
                switch option {
                case .add:
                    return (.mcOptionSelectCompleteNewPM, nil)
                case .saved(let paymentMethod):
                    return (.mcOptionSelectCompleteSavedPM, paymentMethod.type.identifier)
                case .applePay:
                    return (.mcOptionSelectCompleteApplePay, nil)
                case .link:
                    return (.mcOptionSelectCompleteLink, nil)
                }
            case .embedded:
                if case .saved(let paymentMethod) = option {
                    return (.mcOptionSelectEmbeddedSavedPM, paymentMethod.type.identifier)
                } else {
                    stpAssertionFailure("Embedded should only use this function to record tapped saved payment methods")
                    return (nil, nil)
                }
            }
        }()
        guard let event else {
            return
        }
        log(event: event, selectedLPM: selectedLPM)
    }

    func logNewPaymentMethodSelected(paymentMethodTypeIdentifier: String) {
        log(event: .paymentSheetCarouselPaymentMethodTapped, selectedLPM: paymentMethodTypeIdentifier)
    }
    func logSavedPaymentMethodRemoved(paymentMethod: STPPaymentMethod) {
        let event: STPAnalyticEvent = {
            switch integrationShape {
            case .flowController:
                return .mcOptionRemoveCustomSavedPM
            case .complete:
                return .mcOptionRemoveCompleteSavedPM
            case .embedded:
                return .mcOptionRemoveEmbeddedSavedPM
            }
        }()
        log(event: event, selectedLPM: paymentMethod.type.identifier)
    }

    /// Used to ensure we only send one `mc_form_interacted` event per `mc_form_shown` to avoid spamming.
    var didSendPaymentSheetFormInteractedEventAfterFormShown: Bool = false
    func logFormShown(paymentMethodTypeIdentifier: String) {
        didSendPaymentSheetFormInteractedEventAfterFormShown = false
        didSendPaymentSheetFormCompletedEvent = false
        lastLogFormShown = paymentMethodTypeIdentifier
        startTimeMeasurement(.formShown)
        log(
            event: .paymentSheetFormShown,
            selectedLPM: paymentMethodTypeIdentifier
        )
    }

    func logFormInteracted(paymentMethodTypeIdentifier: String) {
        if !didSendPaymentSheetFormInteractedEventAfterFormShown {
            didSendPaymentSheetFormInteractedEventAfterFormShown = true
            log(
                event: .paymentSheetFormInteracted,
                selectedLPM: paymentMethodTypeIdentifier
            )
        }
    }

    /// Used to ensure we only send one `mc_form_completed` event per `mc_form_shown` to avoid spamming.
    var didSendPaymentSheetFormCompletedEvent: Bool = false
    /// Used because it is possible for logFormCompleted to be called before logFormShown when switching payment methods
    var lastLogFormShown: String?
    func logFormCompleted(paymentMethodTypeIdentifier: String) {
        if !didSendPaymentSheetFormCompletedEvent && paymentMethodTypeIdentifier == lastLogFormShown {
            didSendPaymentSheetFormCompletedEvent = true
            log(
                event: .paymentSheetFormCompleted,
                selectedLPM: paymentMethodTypeIdentifier
            )
        }
    }

    func logConfirmButtonTapped(paymentOption: PaymentOption) {
        let duration = getDuration(for: .formShown)
        log(
            event: .paymentSheetConfirmButtonTapped,
            duration: duration,
            selectedLPM: paymentOption.paymentMethodTypeAnalyticsValue,
            linkContext: paymentOption.linkContextAnalyticsValue
        )
    }

    func logPayment(
        paymentOption: PaymentOption,
        result: PaymentSheetResult,
        deferredIntentConfirmationType: STPAnalyticsClient.DeferredIntentConfirmationType?
    ) {
        if NSClassFromString("XCTest") == nil {
            stpAssert(intent != nil)
        }
        var success: Bool
        switch result {
        case .canceled:
            // We don't report these to analytics, bail out.
            return
        case .failed:
            success = false
        case .completed:
            success = true
            if intent?.isDeferredIntent ?? true {
                stpAssert(deferredIntentConfirmationType != nil, "Successful deferred intent payments should always know the deferred intent confirm type")
            } else {
                stpAssert(deferredIntentConfirmationType == nil, "Non-deferred intent should not send deferred intent confirm type")
            }
        }

        let event: STPAnalyticEvent = {
            switch integrationShape {
            case .flowController:
                switch paymentOption {
                case .new, .external:
                    return success ? .mcPaymentCustomNewPMSuccess : .mcPaymentCustomNewPMFailure
                case .saved:
                    return success ? .mcPaymentCustomSavedPMSuccess : .mcPaymentCustomSavedPMFailure
                case .applePay:
                    return success ? .mcPaymentCustomApplePaySuccess : .mcPaymentCustomApplePayFailure
                case .link:
                    return success ? .mcPaymentCustomLinkSuccess : .mcPaymentCustomLinkFailure
                }
            case .complete:
                switch paymentOption {
                case .new, .external:
                    return success ? .mcPaymentCompleteNewPMSuccess : .mcPaymentCompleteNewPMFailure
                case .saved:
                    return success ? .mcPaymentCompleteSavedPMSuccess : .mcPaymentCompleteSavedPMFailure
                case .applePay:
                    return success ? .mcPaymentCompleteApplePaySuccess : .mcPaymentCompleteApplePayFailure
                case .link:
                    return success ? .mcPaymentCompleteLinkSuccess : .mcPaymentCompleteLinkFailure
                }
            case .embedded:
                return success ? .mcPaymentEmbeddedSuccess : .mcPaymentEmbeddedFailure
            }
        }()

        log(event: event,
            duration: getDuration(for: .checkout),
            error: result.error,
            deferredIntentConfirmationType: deferredIntentConfirmationType,
            selectedLPM: paymentOption.paymentMethodTypeAnalyticsValue,
            linkContext: paymentOption.linkContextAnalyticsValue
        )
    }

    func log(
        event: STPAnalyticEvent,
        duration: TimeInterval? = nil,
        error: Error? = nil,
        deferredIntentConfirmationType: STPAnalyticsClient.DeferredIntentConfirmationType? = nil,
        selectedLPM: String? = nil,
        linkContext: String? = nil,
        params: [String: Any] = [:]
    ) {
        let linkEnabled: Bool? = {
            guard let elementsSession else { return nil }
            return PaymentSheet.isLinkEnabled(elementsSession: elementsSession, configuration: configuration)
        }()

        var additionalParams = [:] as [String: Any]
        additionalParams["duration"] = duration
        additionalParams["link_enabled"] = linkEnabled
        additionalParams["active_link_session"] = LinkAccountContext.shared.account?.sessionState == .verified
        additionalParams["link_session_type"] = elementsSession?.linkPopupWebviewOption.rawValue
        additionalParams["mpe_config"] = configuration.analyticPayload
        additionalParams["currency"] = intent?.currency
        additionalParams["is_decoupled"] = intent?.intentConfig != nil
        additionalParams["deferred_intent_confirmation_type"] = deferredIntentConfirmationType?.rawValue
        additionalParams["require_cvc_recollection"] = intent?.cvcRecollectionEnabled
        additionalParams["selected_lpm"] = selectedLPM
        additionalParams["link_context"] = linkContext

        if let error {
            additionalParams.mergeAssertingOnOverwrites(error.serializeForV1Analytics())
        }

        for (param, param_value) in params {
            additionalParams[param] = param_value
        }
        let analytic = PaymentSheetAnalytic(event: event, additionalParams: additionalParams)
        analyticsClient.log(analytic: analytic, apiClient: configuration.apiClient)
    }
}

// MARK: - Time measurement helper
extension PaymentSheetAnalyticsHelper {
    enum TimeMeasurement {
        case checkout
        case formShown
    }

    func startTimeMeasurement(_ measurement: TimeMeasurement) {
        startTimes[measurement] = Date()
    }

    func getDuration(for measurement: TimeMeasurement) -> TimeInterval? {
        guard let startTime = startTimes[measurement] else {
            // Return `nil` if the time measurement hasn't started.
            return nil
        }

        return Date().roundedTimeIntervalSince(startTime)
    }
}

extension STPAnalyticsClient {
    enum DeferredIntentConfirmationType: String {
        case server = "server"
        case client = "client"
        case none = "none"
    }
}

extension PaymentSheet.Configuration {
    /// Serializes the configuration into a safe dictionary containing no PII for analytics logging
    var analyticPayload: [String: Any] {
        var payload = commonAnalyticPayload
        payload["payment_method_layout"] = paymentMethodLayout.description
        return payload
    }
}

extension EmbeddedPaymentElement.Configuration {
    /// Serializes the configuration into a safe dictionary containing no PII for analytics logging
    var analyticPayload: [String: Any] {
        var payload = commonAnalyticPayload
        payload["form_sheet_action"] = formSheetAction.analyticValue
        payload["embedded_view_displays_mandate_text"] = embeddedViewDisplaysMandateText
        return payload
    }
}

extension PaymentElementConfiguration {
    var commonAnalyticPayload: [String: Any] {
        var payload = [String: Any]()
        payload["allows_delayed_payment_methods"] = allowsDelayedPaymentMethods
        payload["apple_pay_config"] = applePay != nil
        payload["style"] = style.rawValue
        payload["customer"] = customer != nil
        payload["customer_access_provider"] = customer?.customerAccessProvider.analyticValue
        payload["return_url"] = returnURL != nil
        payload["default_billing_details"] = defaultBillingDetails != PaymentSheet.BillingDetails()
        payload["save_payment_method_opt_in_behavior"] = savePaymentMethodOptInBehavior.description
        payload["appearance"] = appearance.analyticPayload
        payload["billing_details_collection_configuration"] = billingDetailsCollectionConfiguration.analyticPayload
        payload["preferred_networks"] = preferredNetworks?.map({ STPCardBrandUtilities.apiValue(from: $0) }).joined(separator: ", ")
        payload["card_brand_acceptance"] = cardBrandAcceptance != .all
        return payload
    }
}
