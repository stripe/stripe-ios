//
//  Log.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 10/14/24.
//

import os

struct Log {
    static let log = OSLog(subsystem: "StripeConnect", category: "general")

    static func debug(_ message: String) {
        os_log("[StripeConnect] %{public}@", log: log, type: .debug, message)
    }

    static func warn(_ message: String) {
        os_log("[StripeConnect] Warning: %{public}@", log: log, type: .error, message)
    }
}
