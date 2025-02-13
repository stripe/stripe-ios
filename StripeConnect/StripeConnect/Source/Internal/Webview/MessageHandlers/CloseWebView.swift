//
//  CloseWebView.swift
//  StripeConnect
//
//  Created by Chris Mays on 2/12/25.
//

/// Indicates to close the webview
class CloseWebViewMessageHandler: ScriptMessageHandler<VoidPayload> {
    init(analyticsClient: ComponentAnalyticsClient,
         didReceiveMessage: @escaping (VoidPayload) -> Void) {
        super.init(name: "closeWebView",
                   analyticsClient: analyticsClient,
                   didReceiveMessage: didReceiveMessage)
    }
}
