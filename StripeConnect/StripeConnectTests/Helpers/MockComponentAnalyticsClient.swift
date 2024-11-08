//
//  MockComponentAnalyticsClient.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 11/7/24.
//

@testable import StripeConnect
@_spi(STP) import StripeCoreTestUtils
import XCTest

class MockComponentAnalyticsClient: ComponentAnalyticsClient {
    var events: [any ConnectAnalyticEvent] = []
    var clientErrors: [(error: any Error, file: StaticString)] = []

    init(commonFields: CommonFields) {
        super.init(client: MockAnalyticsClientV2(), commonFields: commonFields)
    }

    override func log<Event: ConnectAnalyticEvent>(event: Event) {
        events.append(event)
    }

    override func logClientError(_ error: any Error,
                                 file: StaticString = #file,
                                 line: UInt = #line) {
        clientErrors.append((error, file))
    }
}
