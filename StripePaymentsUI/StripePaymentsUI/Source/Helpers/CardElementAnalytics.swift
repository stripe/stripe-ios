//
//  CardElementAnalytics.swift
//  StripePaymentsUI
//
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

final class CardElementAnalytics {
    enum WidgetType: String {
        case paymentCardTextField = "payment_card_text_field"
        case cardFormView = "card_form_view"
    }

    private let widgetType: WidgetType
    private let analyticsClient: STPAnalyticsClientProtocol
    private(set) var reportedEvents: Set<STPAnalyticEvent> = []

    init(
        widgetType: WidgetType,
        analyticsClient: STPAnalyticsClientProtocol = STPAnalyticsClient.sharedClient
    ) {
        self.widgetType = widgetType
        self.analyticsClient = analyticsClient
    }

    func reportShown() {
        report(.mobileCardElementShown)
    }

    func reportInteraction() {
        report(.mobileCardElementInteraction)
    }

    func reportFormCompleted() {
        report(.mobileCardElementFormCompleted)
    }

    private func report(_ event: STPAnalyticEvent) {
        guard reportedEvents.insert(event).inserted else {
            return
        }
        analyticsClient.log(
            analytic: CardElementAnalytic(event: event, widgetType: widgetType),
            apiClient: .shared
        )
    }

    private struct CardElementAnalytic: PaymentAnalytic {
        let event: STPAnalyticEvent
        let widgetType: WidgetType

        var additionalParams: [String: Any] {
            ["widget_type": widgetType.rawValue]
        }
    }
}
