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
        case .mcShowCustomNewPM, .mcShowCompleteNewPM:
            return .init(eventName: "didPresent", metadata: payload)
        case .mcShowCustomSavedPM, .mcShowCompleteSavedPM:
            return .init(eventName: "didPresentWithSavedPM", metadata: payload)

        // Tapping on a payment method type
        case .paymentSheetCarouselPaymentMethodTapped:
            return .init(eventName: "didSelectPaymentMethodType", metadata: payload)

        // Payment Method form showed
        case .paymentSheetFormShown:
            return .init(eventName: "didShowPaymentMethodForm", metadata: payload)

        // Form Interaction
        case .paymentSheetFormInteracted:
            return .init(eventName: "didStartInteractWithForm", metadata: payload)
        case .paymentSheetFormCompleted:
            return .init(eventName: "formDidComplete", metadata: payload)

        // Removing Payment Method
        case .mcSavedPaymentMethodRemoved:
            return .init(eventName: "didRemovePaymentMethod", metadata: payload)

        // Saved Payment Methods
        case .mcOptionSelectCustomNewPM, .mcOptionSelectCompleteNewPM:
            return .init(eventName: "didSelectSavedPaymentMethodNew", metadata: payload)
        case .mcOptionSelectCustomSavedPM, .mcOptionSelectCompleteSavedPM:
            return .init(eventName: "didSelectSavedPaymentMethodSaved", metadata: payload)
        case .mcOptionSelectCustomApplePay, .mcOptionSelectCompleteApplePay:
            return .init(eventName: "didSelectSavedPaymentMethodApplePay", metadata: payload)
        case .mcOptionSelectCustomLink, .mcOptionSelectCompleteLink:
            return .init(eventName: "didSelectSavedPaymentMethodLink", metadata: payload)

        default:
            return nil
        }
    }
}




