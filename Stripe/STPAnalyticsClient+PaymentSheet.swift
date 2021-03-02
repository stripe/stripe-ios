//
//  STPAnalyticsClient+PaymentSheet.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 12/14/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation

extension STPAnalyticsClient {
    /// A version of STPAnalyticsClient.log that always logs, even if this is a simulator or test
    private func unconditionallyLog(_ payload: [String: Any]) {
        let url = URL(string: "https://q.stripe.com")!
        let request = NSMutableURLRequest(url: url)
        request.stp_addParameters(toURL: payload)
        let task = urlSession.dataTask(with: request as URLRequest)
        task.resume()
    }

    func logPaymentSheetInitialized(
        isCustom: Bool = false, configuration: PaymentSheet.Configuration
    ) {
        var payload = type(of: self).commonPayload()
        payload["event"] = paymentSheetInitEventValue(
            isCustom: isCustom, configuration: configuration)
        payload["publishable_key"] = STPAPIClient.shared.publishableKey ?? "unknown"
        if isSimulatorOrTest {
            payload["is_development"] = true
        }
        unconditionallyLog(payload)
    }

    func paymentSheetInitEventValue(isCustom: Bool, configuration: PaymentSheet.Configuration)
        -> String
    {
        return [
            "mc",
            isCustom ? "custom" : "complete",
            "init",
            configuration.customer != nil ? "customer" : nil,
            configuration.applePay != nil ? "applepay" : nil,
            configuration.customer == nil && configuration.applePay == nil ? "default" : nil,
        ].compactMap({ $0 }).joined(separator: "_")
    }

    var isSimulatorOrTest: Bool {
        #if targetEnvironment(simulator)
            return true
        #else
            return NSClassFromString("XCTest") != nil
        #endif
    }
}
