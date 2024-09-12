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

        // Sheet presentation (Custom)
        case .mcShowCustomNewPM:
            return .init(eventName: "didPresentCustom", metadata: payload)
        case .mcShowCustomSavedPM:
            return .init(eventName: "didPresentWithSavedPMCustom", metadata: payload)

        // Sheet presentation (Complete)
        case .mcShowCompleteNewPM:
            return .init(eventName: "didPresentComplete", metadata: payload)
        case .mcShowCompleteSavedPM:
            return .init(eventName: "didPresentWithSavedPMComplete", metadata: payload)

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

        // Saved Payment Methods (Custom)
        case .mcOptionSelectCustomNewPM:
            return .init(eventName: "didSelectSavedPaymentMethodNewCustom", metadata: payload)
        case .mcOptionSelectCustomSavedPM:
            return .init(eventName: "didSelectSavedPaymentMethodSavedCustom", metadata: payload)
        case .mcOptionSelectCustomApplePay:
            return .init(eventName: "didSelectSavedPaymentMethodApplePayCustom", metadata: payload)
        case .mcOptionSelectCustomLink:
            return .init(eventName: "didSelectSavedPaymentMethodLinkCustom", metadata: payload)

        // Saved Payment Methods (Complete)
        case .mcOptionSelectCompleteNewPM:
            return .init(eventName: "didSelectSavedPaymentMethodNewComplete", metadata: payload)
        case .mcOptionSelectCompleteSavedPM:
            return .init(eventName: "didSelectSavedPaymentMethodSavedComplete", metadata: payload)
        case .mcOptionSelectCompleteApplePay:
            return .init(eventName: "didSelectSavedPaymentMethodApplePayComplete", metadata: payload)
        case .mcOptionSelectCompleteLink:
            return .init(eventName: "didSelectSavedPaymentMethodLinkComplete", metadata: payload)

        default:
            return nil
        }
    }
}




