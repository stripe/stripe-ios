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
    let configuration: PaymentSheet.Configuration

    // Vars set later as PaymentSheet successfully loads, etc.
    var intent: Intent?
    var elementsSession: STPElementsSession?
    var loadingStartDate: Date?

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

    func logShow(showingSavedPMList: Bool) {
        assert(intent != nil)
        assert(elementsSession != nil)
        if !isCustom {
            // TODO: MOve over
            AnalyticsHelper.shared.startTimeMeasurement(.checkout)
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

    func logSavedPMScreenOptionSelected(option: STPAnalyticsClient.AnalyticsPaymentMethodType) {
        let event: STPAnalyticEvent = {
            if isCustom {
                switch option {
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
                switch option {
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

    func logFormShown(paymentMethodTypeIdentifier: String) {
        AnalyticsHelper.shared.didSendPaymentSheetFormInteractedEventAfterFormShown = false
        AnalyticsHelper.shared.startTimeMeasurement(.formShown)
        log(
            event: .paymentSheetFormShown,
            selectedLPM: paymentMethodTypeIdentifier
        )
    }

    func logFormInteracted(paymentMethodTypeIdentifier: String) {
        if !AnalyticsHelper.shared.didSendPaymentSheetFormInteractedEventAfterFormShown {
            AnalyticsHelper.shared.didSendPaymentSheetFormInteractedEventAfterFormShown = true
            log(
                event: .paymentSheetFormInteracted,
                selectedLPM: paymentMethodTypeIdentifier
            )
        }
    }

    func logConfirmButtonTapped(paymentOption: PaymentOption) {
        let duration = AnalyticsHelper.shared.getDuration(for: .formShown)
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
        var success: Bool
        switch result {
        case .canceled:
            // We don't report these to analytics, bail out.
            return
        case .failed:
            success = false
        case .completed:
            success = true
            assert(deferredIntentConfirmationType != nil, "Successful payments should always know the deferred intent confirm type")
        }

        let event: STPAnalyticEvent = {
            if isCustom {
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
            } else {
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
            }
        }()

        log(event: event,
            duration: AnalyticsHelper.shared.getDuration(for: .checkout),
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
        let linkEnabled: Bool = {
            guard let elementsSession else { return false }
            return PaymentSheet.isLinkEnabled(elementsSession: elementsSession, configuration: configuration)
        }()
        var additionalParams = [:] as [String: Any]
        additionalParams["duration"] = duration
        additionalParams["link_enabled"] = linkEnabled
        additionalParams["active_link_session"] = LinkAccountContext.shared.account?.sessionState == .verified
        additionalParams["link_session_type"] = elementsSession?.linkPopupWebviewOption.rawValue
        additionalParams["mpe_config"] = configuration.analyticPayload
        additionalParams["locale"] = Locale.autoupdatingCurrent.identifier
        additionalParams["currency"] = intent?.currency
        additionalParams["is_decoupled"] = intent?.intentConfig != nil
        additionalParams["deferred_intent_confirmation_type"] = deferredIntentConfirmationType?.rawValue
        additionalParams["selected_lpm"] = selectedLPM
        additionalParams["link_context"] = linkContext
        additionalParams["ooc will this fail?"] = NSObject()

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

extension STPAnalyticsClient {
    enum DeferredIntentConfirmationType: String {
        case server = "server"
        case client = "client"
        case none = "none"
    }

    enum AnalyticsPaymentMethodType: String {
        case newPM = "newpm"
        case savedPM = "savedpm"
        case applePay = "applepay"
        case link = "link"
    }
}

extension SavedPaymentOptionsViewController.Selection {
    var analyticsValue: STPAnalyticsClient.AnalyticsPaymentMethodType {
        switch self {
        case .add:
            return .newPM
        case .saved:
            return .savedPM
        case .applePay:
            return .applePay
        case .link:
            return .link
        }
    }
}
