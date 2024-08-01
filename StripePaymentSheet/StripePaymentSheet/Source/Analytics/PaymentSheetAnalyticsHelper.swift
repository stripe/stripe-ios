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
    let isCustom: Bool
    let linkContext: LinkAccountContext = .shared
    let configuration: PaymentSheet.Configuration

    // Vars set later as PaymentSheet successfully loads, etc.
    var intent: Intent?
    var elementsSession: STPElementsSession?

    // Computed properties
    var linkSessionType: LinkSettings.PopupWebviewOption? { elementsSession?.linkPopupWebviewOption }
    var activeLinkSession: Bool { linkContext.account?.sessionState == .verified }
    var linkEnabled: Bool {
        guard let elementsSession else { return false }
        return PaymentSheet.isLinkEnabled(elementsSession: elementsSession, configuration: configuration)
    }

    init(
        isCustom: Bool,
        configuration: PaymentSheet.Configuration,
        analyticsClient: STPAnalyticsClient = .sharedClient
    ) {
        self.isCustom = isCustom
        self.configuration = configuration
        self.analyticsClient = analyticsClient
    }

    func logInitialized() {
        let event: STPAnalyticEvent = {
            switch (configuration.customer == nil, configuration.applePay == nil) {
            case (false, false):
                return isCustom ? .mcInitCustomDefault : .mcInitCompleteDefault
            case (true, false):
                return isCustom ? .mcInitCustomCustomer : .mcInitCompleteCustomer
            case (false, true):
                return isCustom ? .mcInitCustomApplePay : .mcInitCompleteApplePay
            case (true, true):
                return isCustom ? .mcInitCustomCustomerApplePay : .mcInitCompleteCustomerApplePay
            }
        }()
        log(event: event)
    }

    var loadingStartDate: Date?
    func logLoadStarted() {
        loadingStartDate = Date()
        log(event: .paymentSheetLoadStarted)
    }

    func logLoadFailed(error: Error) {
        assert(loadingStartDate != nil)
        let duration: TimeInterval = {
            guard let loadingStartDate else { return 0 }
            return Date().timeIntervalSince(loadingStartDate)
        }()
        log(event: .paymentSheetLoadFailed, duration: duration, error: error)
    }

    func logLoadSucceeded(
        intent: Intent,
        elementsSession: STPElementsSession,
        defaultPaymentMethod: SavedPaymentOptionsViewController.Selection?,
        orderedPaymentMethodTypes: [PaymentSheet.PaymentMethodType]
    ) {
        assert(loadingStartDate != nil)
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
                assertionFailure("Caller should ensure that default payment method is `nil` in this case.")
                return "none"
            }
        }()
        let params: [String: Any] = [
            "selected_lpm": defaultPaymentMethodAnalyticsValue,
            "intent_type": intent.analyticsValue,
            "ordered_lpms": orderedPaymentMethodTypes.map({ $0.identifier }).joined(separator: ","),
        ]
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

    func logShow(paymentMethod: AnalyticsPaymentMethodType) {
        assert(intent != nil)
        assert(elementsSession != nil)
        if !isCustom {
            // TODO: MOve over
            AnalyticsHelper.shared.startTimeMeasurement(.checkout)
        }
        let event: STPAnalyticEvent = {
            switch paymentMethod {
            case .newPM:
                return isCustom ? .mcShowCustomNewPM : .mcShowCompleteNewPM
            case .savedPM:
                return isCustom ? .mcShowCustomSavedPM : .mcShowCompleteSavedPM
            case .applePay:
                return isCustom ? .mcShowCustomApplePay : .mcShowCompleteApplePay
            case .link:
                // TODO: Can't show link or apple pay...??
                return isCustom ? .mcShowCustomLink : .mcShowCompleteLink
            }
        }()
        log(event: event)
    }

    func logPaymentOptionSelect(paymentMethod: AnalyticsPaymentMethodType) {
        let event: STPAnalyticEvent = {
            if isCustom {
                switch paymentMethod {
                case .newPM:
                    return .mcOptionSelectCustomNewPM
                case .savedPM:
                    return .mcOptionSelectCustomSavedPM
                case .applePay:
                    return .mcOptionSelectCustomApplePay
                case .link:
                    return .mcOptionSelectCustomLink
                }
            } else {
                switch paymentMethod {
                case .newPM:
                    return .mcOptionSelectCompleteNewPM
                case .savedPM:
                    return .mcOptionSelectCompleteSavedPM
                case .applePay:
                    return .mcOptionSelectCompleteApplePay
                case .link:
                    return .mcOptionSelectCompleteLink
                }
            }
        }()
        log(event: event)
    }

//    func logFormShown(paymentMethodTypeIdentifier: String, apiClient: STPAPIClient) {
//        AnalyticsHelper.shared.didSendPaymentSheetFormInteractedEventAfterFormShown = false
//        AnalyticsHelper.shared.startTimeMeasurement(.formShown)
//        log(event: .paymentSheetFormShown, paymentMethodTypeAnalyticsValue: paymentMethodTypeIdentifier, apiClient: apiClient)
//    }
//
//    func logFormInteracted(paymentMethodTypeIdentifier: String) {
//        if !AnalyticsHelper.shared.didSendPaymentSheetFormInteractedEventAfterFormShown {
//            AnalyticsHelper.shared.didSendPaymentSheetFormInteractedEventAfterFormShown = true
//            log(event: .paymentSheetFormInteracted, paymentMethodTypeAnalyticsValue: paymentMethodTypeIdentifier)
//        }
//    }

//    func logConfirmButtonTapped(
//        paymentMethodTypeIdentifier: String,
//        linkContext: String? = nil
//    ) {
//        let duration = AnalyticsHelper.shared.getDuration(for: .formShown)
//        log(
//            event: .paymentSheetConfirmButtonTapped,
//            duration: duration, paymentMethodTypeAnalyticsValue: paymentMethodTypeIdentifier,
//            linkContext: linkContext
//        )
//    }

    func paymentSheetPaymentEventValue(
        isCustom: Bool,
        paymentMethod: AnalyticsPaymentMethodType,
        success: Bool
    ) -> STPAnalyticEvent
    {
        if isCustom {
            switch paymentMethod {
            case .newPM:
                return success ? .mcPaymentCustomNewPMSuccess : .mcPaymentCustomNewPMFailure
            case .savedPM:
                return success ? .mcPaymentCustomSavedPMSuccess : .mcPaymentCustomSavedPMFailure
            case .applePay:
                return success ? .mcPaymentCustomApplePaySuccess : .mcPaymentCustomApplePayFailure
            case .link:
                return success ? .mcPaymentCustomLinkSuccess : .mcPaymentCustomLinkFailure
            }
        } else {
            switch paymentMethod {
            case .newPM:
                return success ? .mcPaymentCompleteNewPMSuccess : .mcPaymentCompleteNewPMFailure
            case .savedPM:
                return success ? .mcPaymentCompleteSavedPMSuccess : .mcPaymentCompleteSavedPMFailure
            case .applePay:
                return success ? .mcPaymentCompleteApplePaySuccess : .mcPaymentCompleteApplePayFailure
            case .link:
                return success ? .mcPaymentCompleteLinkSuccess : .mcPaymentCompleteLinkFailure
            }
        }
    }

    func paymentSheetPaymentOptionSelectEventValue(
        isCustom: Bool,
        paymentMethod: AnalyticsPaymentMethodType
    ) -> STPAnalyticEvent
    {
        if isCustom {
            switch paymentMethod {
            case .newPM:
                return .mcOptionSelectCustomNewPM
            case .savedPM:
                return .mcOptionSelectCustomSavedPM
            case .applePay:
                return .mcOptionSelectCustomApplePay
            case .link:
                return .mcOptionSelectCustomLink
            }
        } else {
            switch paymentMethod {
            case .newPM:
                return .mcOptionSelectCompleteNewPM
            case .savedPM:
                return .mcOptionSelectCompleteSavedPM
            case .applePay:
                return .mcOptionSelectCompleteApplePay
            case .link:
                return .mcOptionSelectCompleteLink
            }
        }
    }

    // MARK: - mc_{complete / custom}_payment_{newpm / savedpm, applepay / googlepay / link}_{success / failure / cancel}
    enum AnalyticsPaymentMethodType: String {
        case newPM = "newpm"
        case savedPM = "savedpm"
        case applePay = "applepay"
        case link = "link"
    }
    enum DeferredIntentConfirmationType: String {
        case server = "server"
        case client = "client"
        case none = "none"
    }
    func logPaymentSheetPayment(
        paymentMethod: AnalyticsPaymentMethodType,
        result: PaymentSheetResult,
        currency: String?,
        deferredIntentConfirmationType: DeferredIntentConfirmationType? = nil,
        paymentMethodTypeAnalyticsValue: String? = nil,
        error: Error? = nil
    ) {

    }

    func log(
        event: STPAnalyticEvent,
        duration: TimeInterval? = nil,
        error: Error? = nil,
        deferredIntentConfirmationType: DeferredIntentConfirmationType? = nil,
        paymentMethodTypeAnalyticsValue: String? = nil,
        linkContext: String? = nil,
        params: [String: Any] = [:]
    ) {
//        let additionalParams: [String: Codable] = [
//            "duration": duration,
//            "link_enabled": linkEnabled,
//            "active_link_session": activeLinkSession,
//            "link_session_type": linkSessionType?.rawValue,
//            "locale": Locale.autoupdatingCurrent.identifier,
//            "currency": currency,
//            "is_decoupled": (intentConfig != nil),
//            "deferred_intent_confirmation_type": deferredIntentConfirmationType?.rawValue,
//            "selected_lpm": paymentMethodTypeAnalyticsValue,
//            "link_context": linkContext
//        ]//.compactMapValues { $0 }

        var additionalParams = [:] as [String: Any]
        additionalParams["duration"] = duration
        additionalParams["link_enabled"] = linkEnabled
        additionalParams["active_link_session"] = activeLinkSession
        additionalParams["link_session_type"] = linkSessionType?.rawValue
        additionalParams["mpe_config"] = configuration.analyticPayload
        additionalParams["locale"] = Locale.autoupdatingCurrent.identifier
        additionalParams["currency"] = intent?.currency
        additionalParams["is_decoupled"] = intent?.intentConfig != nil
        additionalParams["deferred_intent_confirmation_type"] = deferredIntentConfirmationType?.rawValue
        additionalParams["selected_lpm"] = paymentMethodTypeAnalyticsValue
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
