//
//  SentryException.swift
//  StripeFinancialConnections
//
//  Created by Mat Schmid on 2024-10-23.
//

import Foundation

struct SentryException: Encodable {
    var values: [SentryExceptionValue] = []
}

/// https://develop.sentry.dev/sdk/data-model/event-payloads/exception/
struct SentryExceptionValue: Encodable {
    let type: String
    let value: String
    let stacktrace: SentryStacktrace
}
