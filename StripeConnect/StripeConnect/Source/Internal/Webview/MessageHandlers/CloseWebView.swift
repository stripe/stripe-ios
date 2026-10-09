//
//  CloseWebView.swift
//  StripeConnect
//
//  Created by Chris Mays on 2/12/25.
//

@_spi(STP) import StripeCore

/// Indicates to close the webview
class CloseWebViewMessageHandler: ScriptMessageHandler<VoidPayload> {
    init(sourcePolicy: STPWebMessageSourcePolicy,
         analyticsClient: ComponentAnalyticsClient,
         didReceiveMessage: @escaping (VoidPayload) -> Void) {
        super.init(name: "closeWebView",
                   sourcePolicy: sourcePolicy,
                   analyticsClient: analyticsClient,
                   didReceiveMessage: didReceiveMessage)
    }
}
