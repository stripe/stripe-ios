//
//  PMMEAnalyticsHelper.swift
//  StripePaymentSheet
//
//  Created by George Birch on 11/6/25.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

final class PMMEAnalyticsHelper {

    enum IntegrationType: String {
        case uiKit = "uikit"
        case config = "swiftui_config_only"
        case content = "swiftui_content"
        case viewData = "swiftui_view_data"
    }

    private let configuration: PaymentMethodMessagingElement.Configuration
    private let analyticsClient: STPAnalyticsClientProtocol

    private var loadingStartDate: Date?
    private var hasLoggedDisplay = false

    init(
        configuration: PaymentMethodMessagingElement.Configuration,
        analyticsClient: STPAnalyticsClientProtocol = STPAnalyticsClient.sharedClient
    ) {
        self.configuration = configuration
        self.analyticsClient = analyticsClient
    }

    func logInitialized() {
        log(event: .paymentMethodMessagingElementInit)
    }

    func logLoadStarted() {
        loadingStartDate = Date()
        log(event: .paymentMethodMessagingElementLoadStarted)
    }

    func logLoadSucceeded(mode: PaymentMethodMessagingElement.Mode) {
        var additionalParams = [:] as [String: Any]
        switch mode {
        case .singlePartner(let logo):
            additionalParams["payment_methods"] = logo.code
            additionalParams["content_type"] = "single_partner"
        case .multiPartner(logos: let logos):
            additionalParams["payment_methods"] = logos.map { $0.code }.joined(separator: ",")
            additionalParams["content_type"] = "multi_partner"
        }
        additionalParams["duration"] = getLoadingDuration()

        log(event: .paymentMethodMessagingElementLoadSucceeded, additionalParams: additionalParams)
    }

    func logLoadSucceededNoContent() {
        var additionalParams = [:] as [String: Any]
        additionalParams["payment_methods"] = nil
        additionalParams["content_type"] = "no_content"
        additionalParams["duration"] = getLoadingDuration()

        log(event: .paymentMethodMessagingElementLoadSucceeded, additionalParams: additionalParams)
    }

    func logLoadFailed(error: Error) {
        var additionalParams = [:] as [String: Any]
        additionalParams["duration"] = getLoadingDuration()
        additionalParams.mergeAssertingOnOverwrites(error.serializeForV1Analytics())

        log(event: .paymentMethodMessagingElementLoadFailed, additionalParams: additionalParams)
    }

    func logDisplayed(integrationType: IntegrationType) {
        if !hasLoggedDisplay {
            log(
                event: .paymentMethodMessagingElementDisplayed,
                additionalParams: ["integration_type": integrationType.rawValue]
            )
        }
        hasLoggedDisplay = true
    }

    func logTapped() {
        log(event: .paymentMethodMessagingElementLoadSucceeded)
    }

    private func log(event: STPAnalyticEvent, additionalParams: [String: Any] = [:]) {
        var params = [:] as [String: Any]
        // config
        params["requested_payment_methods"] = configuration.paymentMethodTypes?.map { $0.identifier }.joined(separator: ",")
        params["amount"] = configuration.amount
        params["currency"] = configuration.currency
        params["requested_locale"] = configuration.locale
        params["country_code"] = configuration.countryCode

        // appearance
        var appearanceParams = [:] as [String: Any]
        appearanceParams["font"] = configuration.appearance.font != PaymentMethodMessagingElement.Appearance().font
        appearanceParams["text_color"] = configuration.appearance.textColor != PaymentMethodMessagingElement.Appearance().textColor
        appearanceParams["info_icon_color"] = configuration.appearance.infoIconColor != PaymentMethodMessagingElement.Appearance().infoIconColor
        appearanceParams["style"] = configuration.appearance.style != PaymentMethodMessagingElement.Appearance().style
        params["appearance"] = appearanceParams

        params.mergeAssertingOnOverwrites(additionalParams)

        // log
        let analytic = PaymentSheetAnalytic(event: event, additionalParams: params)
        analyticsClient.log(analytic: analytic, apiClient: configuration.apiClient)
    }

    private func getLoadingDuration() -> TimeInterval {
        stpAssert(loadingStartDate != nil)
        guard let loadingStartDate else { return 0 }
        return Date().timeIntervalSince(loadingStartDate)
    }
}
