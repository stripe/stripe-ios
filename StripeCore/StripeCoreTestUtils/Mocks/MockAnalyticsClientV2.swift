//
//  MockAnalyticsClientV2.swift
//  StripeCoreTestUtils
//
//  Created by Mel Ludowise on 6/7/22.
//

import Foundation
@_spi(STP) import StripeCore

@_spi(STP) public final class MockAnalyticsClientV2: AnalyticsClientV2Protocol {
    public let clientId: String = "MockAnalyticsClient"

    public private(set) var loggedAnalyticsPayloads: [[String: Any]] = []

    public func loggedAnalyticPayloads(withEventName eventName: String) -> [[String: Any]] {
        return loggedAnalyticsPayloads.filter { ($0["event_name"] as? String) == eventName }
    }

    public init() { }

    public func log(eventName: String, parameters: [String: Any]) {
        loggedAnalyticsPayloads.append(payload(withEventName: eventName, parameters: parameters))
    }
}
