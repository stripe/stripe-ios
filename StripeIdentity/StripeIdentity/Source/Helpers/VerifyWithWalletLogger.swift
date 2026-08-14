//
//  VerifyWithWalletLogger.swift
//  StripeIdentity
//
//  Created by Stripe on 8/14/26.
//

import Foundation
import os.log

/// Routes Verify with Wallet debug logs through unified logging so they're visible in Console.app,
/// tagged with a common prefix and subsystem/category for easy filtering.
enum VerifyWithWalletLogger {
    private static let logPrefix = "[VerifyWithWallet]"
    private static let oslog = OSLog(subsystem: "com.stripe.StripeIdentity", category: "VerifyWithWallet")

    static func log(_ message: @autoclosure () -> String) {
        os_log("%{public}@ %{public}@", log: oslog, type: .default, logPrefix, message())
    }

    static func logError(_ message: @autoclosure () -> String) {
        os_log("%{public}@ %{public}@", log: oslog, type: .error, logPrefix, message())
    }
}
