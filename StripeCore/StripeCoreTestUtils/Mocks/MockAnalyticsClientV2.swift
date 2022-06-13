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

    public init() { }

    public func log(eventName: String, parameters: [String: Any]) {
        loggedAnalyticsPayloads.append(payload(withEventName: eventName, parameters: parameters))
    }
}
