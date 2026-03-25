//
//  PlaygroundUserDefaults.swift
//  FinancialConnections Example
//
//  Created by Krisjanis Gaidis on 11/5/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

final class PlaygroundUserDefaults {

    @UserDefault(
        key: "FINANCIAL_CONNECTIONS_EXAMPLE_APP_ENABLE_NATIVE",
        defaultValue: nil
    )
    static var enableNative: Bool?

    @UserDefault(
        key: "FC_LITE_ENABLE_SECURE_WEBVIEW",
        defaultValue: nil
    )
    static var enableFCLiteSecureWebview: Bool?
}
