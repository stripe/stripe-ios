//
//  STPAnalyticsEventTranslator.swift
//  StripeCore
//

import Foundation

struct STPAnalyticsTranslatedEvent {
    let notificationName: Notification.Name
    let event: MobilePaymentElementAnalyticEvent

    init(notificationName: Notification.Name = .mobilePaymentElement,
         name: MobilePaymentElementAnalyticEvent.Name) {
        self.notificationName = notificationName
        self.event = .init(name: name)
    }
}

struct STPAnalyticsEventTranslator {
    func translate(_ analyticEvent: STPAnalyticEvent, payload: [String: Any]) -> STPAnalyticsTranslatedEvent? {
        guard let translatedEventName = translateEvent(analyticEvent, payload: payload) else {
            return nil
        }
        return .init(name: translatedEventName)
    }

    func translateEvent(_ analyticEvent: STPAnalyticEvent, payload: [String: Any]) -> MobilePaymentElementAnalyticEvent.Name? {
        let paymentMethodType = paymentMethodType(payload)
        switch analyticEvent {

        // Sheet presentation
        case .mcShowCustomNewPM, .mcShowCompleteNewPM, .mcShowCustomSavedPM, .mcShowCompleteSavedPM:
            return .presentedSheet

        // Tapping on a payment method type
        case .paymentSheetCarouselPaymentMethodTapped:
            guard let paymentMethodType else {
                return nil
            }
            return .selectedPaymentMethodType(.init(paymentMethodType: paymentMethodType))

        // Payment Method form showed
        case .paymentSheetFormShown:
            guard let paymentMethodType else {
                return nil
            }
            return .displayedPaymentMethodForm(.init(paymentMethodType: paymentMethodType))

        // Form Interaction
        case .paymentSheetFormInteracted:
            guard let paymentMethodType else {
                return nil
            }
            return .startedInteractionWithPaymentMethodForm(.init(paymentMethodType: paymentMethodType))
        case .paymentSheetFormCompleted:
            guard let paymentMethodType else {
                return nil
            }
            return .completedPaymentMethodForm(.init(paymentMethodType: paymentMethodType))
        case .paymentSheetConfirmButtonTapped:
            guard let paymentMethodType else {
                return nil
            }
            return .tappedConfirmButton(.init(paymentMethodType: paymentMethodType))

        // Saved Payment Methods
        case .mcOptionSelectCustomSavedPM, .mcOptionSelectCompleteSavedPM, .mcOptionSelectEmbeddedSavedPM:
            guard let paymentMethodType else {
                return nil
            }
            return .selectedSavedPaymentMethod(.init(paymentMethodType: paymentMethodType))
        case .mcOptionRemoveCustomSavedPM, .mcOptionRemoveCompleteSavedPM, .mcOptionRemoveEmbeddedSavedPM:
            guard let paymentMethodType else {
                return nil
            }
            return .removedSavedPaymentMethod(.init(paymentMethodType: paymentMethodType))

        default:
            return nil
        }
    }

    func paymentMethodType(_ originalPayload: [String: Any]) -> String? {
        if let paymentMethodType = originalPayload["selected_lpm"] as? String {
            return paymentMethodType
        }
        return nil
    }
}
