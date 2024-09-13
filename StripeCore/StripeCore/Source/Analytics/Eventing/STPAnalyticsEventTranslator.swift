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
    func translate(_ analytic: Analytic, payload: [String: Any]) -> STPAnalyticsTranslatedEvent? {
        switch analytic.event {

        // Sheet presentation
        case .mcShowCustomNewPM, .mcShowCompleteNewPM, .mcShowCustomSavedPM, .mcShowCompleteSavedPM:
            return .init(eventName: "presentedSheet", metadata: payload)

        // Tapping on a payment method type
        case .paymentSheetCarouselPaymentMethodTapped:
            return .init(eventName: "selectedPaymentMethodType", metadata: payload)

        // Payment Method form showed
        case .paymentSheetFormShown:
            return .init(eventName: "displayedPaymentMethodForm", metadata: payload)

        // Form Interaction
        case .paymentSheetFormInteracted:
            return .init(eventName: "startedInteractionWithPaymentMethodForm", metadata: payload)
        case .paymentSheetFormCompleted:
            return .init(eventName: "completedPaymentMethodForm", metadata: payload)

        // Saved Payment Methods
        case .mcOptionSelectCustomSavedPM, .mcOptionSelectCompleteSavedPM:
            return .init(eventName: "selectedSavedPaymentMethod", metadata: payload)
        case .mcOptionRemoveCustomSavedPM, .mcOptionRemoveCompleteSavedPM:
            return .init(eventName: "removedSavedPaymentMethod", metadata: payload)
        default:
            return nil
        }
    }
}
