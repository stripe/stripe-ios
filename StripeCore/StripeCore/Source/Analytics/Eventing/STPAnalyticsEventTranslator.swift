//
//  STPAnalyticsEventTranslator.swift
//  StripeCore
//

import Foundation

struct STPAnalyticsTranslatedEvent {
    let notificationName: Notification.Name
    let event: MobilePaymentElementEvent

    init(notificationName: Notification.Name = .mobilePaymentElement,
         eventName: String,
         metadata: [String: Any]) {
        self.notificationName = notificationName
        self.event = .init(eventName: eventName, metadata: metadata)
    }
}

struct STPAnalyticsEventTranslator {
    func translate(_ analyticEvent: STPAnalyticEvent, payload: [String: Any]) -> STPAnalyticsTranslatedEvent? {
        guard let translatedEventName = translateEvent(analyticEvent) else {
            return nil
        }
        return .init(eventName: translatedEventName, metadata: filterPayload(payload))
    }

    func translateEvent(_ analyticEvent: STPAnalyticEvent) -> String? {
        switch analyticEvent {
        // Sheet presentation
        case .mcShowCustomNewPM, .mcShowCompleteNewPM, .mcShowCustomSavedPM, .mcShowCompleteSavedPM:
            return "presentedSheet"

        // Tapping on a payment method type
        case .paymentSheetCarouselPaymentMethodTapped:
            return "selectedPaymentMethodType"

        // Payment Method form showed
        case .paymentSheetFormShown:
            return "displayedPaymentMethodForm"

        // Form Interaction
        case .paymentSheetFormInteracted:
            return "startedInteractionWithPaymentMethodForm"
        case .paymentSheetFormCompleted:
            return "completedPaymentMethodForm"
        case .paymentSheetConfirmButtonTapped:
            return "tappedConfirmButton"

        // Saved Payment Methods
        case .mcOptionSelectCustomSavedPM, .mcOptionSelectCompleteSavedPM:
            return "selectedSavedPaymentMethod"
        case .mcOptionRemoveCustomSavedPM, .mcOptionRemoveCompleteSavedPM:
            return "removedSavedPaymentMethod"

        default:
            return nil
        }
    }

    func filterPayload(_ originalPayload: [String: Any]) -> [String: Any] {
        var filteredPayload: [String: Any] = [:]
        if let paymentMethodType = originalPayload["selected_lpm"] {
            filteredPayload["paymentMethodType"] = paymentMethodType
        }
        return filteredPayload
    }
}
