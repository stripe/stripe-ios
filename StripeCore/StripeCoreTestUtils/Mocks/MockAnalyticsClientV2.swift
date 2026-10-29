//
//  MockAnalyticsClientV2.swift
//  StripeCoreTestUtils
//
//  Created by Mel Ludowise on 6/7/22.
//

import Foundation
@_spi(InternalOnlyAPI) import StripeCore

@_spi(InternalOnlyAPI) public final class MockAnalyticsClientV2: AnalyticsClientV2Protocol {
    public let clientId: String = "MockAnalyticsClient"

    // Locked, because some callers log from several queues at once.
    private let lock = NSLock()
    private var payloads: [[String: Any]] = []

    public var loggedAnalyticsPayloads: [[String: Any]] {
        lock.lock()
        defer { lock.unlock() }
        return payloads
    }

    public func loggedAnalyticPayloads(withEventName eventName: String) -> [[String: Any]] {
        return loggedAnalyticsPayloads.filter { ($0["event_name"] as? String) == eventName }
    }

    public init() {}

    public func log(eventName: String, parameters: [String: Any]) {
        let newPayload = payload(withEventName: eventName, parameters: parameters)
        lock.lock()
        payloads.append(newPayload)
        lock.unlock()
    }
}
