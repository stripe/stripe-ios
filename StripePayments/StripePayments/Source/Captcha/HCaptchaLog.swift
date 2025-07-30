//
//  HCaptchaEvent.swift
//  HCaptcha
//
//  Copyright © 2024 HCaptcha. All rights reserved.
//

import Foundation
import os

/** Internal SDK logger level
 */
enum HCaptchaLogLevel: Int, CustomStringConvertible {
    case debug = 0
    case warning = 1
    case error = 2

    var description: String {
        switch self {
        case .debug:
            return "Debug"
        case .warning:
            return "Warning"
        case .error:
            return "Error"
        }
    }
}

/** Internal SDK logger
 */
internal class HCaptchaLogger {
    static var minLevel: HCaptchaLogLevel = .error

    static func debug(_ message: String, _ args: CVarArg...) {
        log(level: .debug, message: message, args: args)
    }

    static func warn(_ message: String, _ args: CVarArg...) {
        log(level: .warning, message: message, args: args)
    }

    static func error(_ message: String, _ args: CVarArg...) {
        log(level: .error, message: message, args: args)
    }

    static func log(level: HCaptchaLogLevel, message: String, args: [CVarArg]) {
#if DEBUG
        guard level.rawValue >= minLevel.rawValue else {
            return
        }

        let formattedMessage = String(format: message, arguments: args)
        let logMessage = "\(threadId) HCaptcha/\(level.description): \(formattedMessage)"

        NSLog(logMessage)
#endif
    }


    private static var threadId: String {
        return Thread.isMainThread ? "main" : "\(pthread_self())"
    }
}
