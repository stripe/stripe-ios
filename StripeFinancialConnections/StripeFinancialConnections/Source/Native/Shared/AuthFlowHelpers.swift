//
//  AuthFlowHelpers.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 10/5/22.
//

import Foundation
import SafariServices

final class AuthFlowHelpers {

    private init() {}  // only static functions used

    static func formatUrlString(_ urlString: String?) -> String? {
        guard var urlString = urlString else {
            return nil
        }
        if urlString.hasPrefix("https://") {
            urlString.removeFirst("https://".count)
        }
        if urlString.hasPrefix("http://") {
            urlString.removeFirst("http://".count)
        }
        if urlString.hasPrefix("www.") {
            urlString.removeFirst("www.".count)
        }
        if urlString.hasSuffix("/") {
            urlString.removeLast()
        }
        return urlString
    }

    @available(iOSApplicationExtension, unavailable)
    static func handleURLInTextFromBackend(
        url: URL,
        pane: FinancialConnectionsSessionManifest.NextPane,
        analyticsClient: FinancialConnectionsAnalyticsClient,
        handleStripeScheme: (_ urlHost: String?) -> Void
    ) {
        if let urlParameters = URLComponents(url: url, resolvingAgainstBaseURL: true),
            let eventName = urlParameters.queryItems?.first(where: { $0.name == "eventName" })?.value
        {
            analyticsClient
                .log(
                    eventName: eventName,
                    parameters: ["pane": pane.rawValue]
                )
        }

        if url.scheme == "stripe" {
            handleStripeScheme(url.host)
        } else {
            SFSafariViewController.present(url: url)
        }
    }
}
