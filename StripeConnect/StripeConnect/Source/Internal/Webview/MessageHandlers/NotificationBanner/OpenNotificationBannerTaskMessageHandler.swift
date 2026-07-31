//
//  OpenNotificationBannerTaskMessageHandler.swift
//  StripeConnect
//

import Foundation

final class OpenNotificationBannerTaskMessageHandler: ScriptMessageHandler<OpenNotificationBannerTaskMessageHandler.Payload> {
    typealias Payload = [String: JSONValue]

    init(analyticsClient: ComponentAnalyticsClient,
         didReceiveMessage: @escaping (Payload) -> Void) {
        super.init(
            name: "openNotificationBannerForm",
            analyticsClient: analyticsClient,
            didReceiveMessage: didReceiveMessage
        )
    }
}
