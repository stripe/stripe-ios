//
//  CryptoOnrampAnalyticsClient.swift
//  StripeCryptoOnramp
//
//  Created by Mat Schmid on 9/10/25.
//

import Foundation
@_spi(STP) import StripeCore

final class CryptoOnrampAnalyticsClient {
    private let analyticsClient: AnalyticsClientV2Protocol
    private var additionalParameters: [String: Any] = [:]

    init(
        analyticsClient: AnalyticsClientV2Protocol = AnalyticsClientV2(
            clientId: "mobile-onramp-sdk",
            origin: "stripe-onramp-ios"
        )
    ) {
        self.analyticsClient = analyticsClient

        if AnalyticsHelper.shared.sessionID == nil {
            AnalyticsHelper.shared.generateSessionID()
        }
        additionalParameters["session_id"] = AnalyticsHelper.shared.sessionID ?? "N/a"
    }

    func log(_ event: CryptoOnrampAnalyticsEvent) {
        var parameters = event.parameters

        for (key, value) in additionalParameters {
            parameters[key] = value
        }
        analyticsClient.log(eventName: event.eventName, parameters: parameters)
    }
}
