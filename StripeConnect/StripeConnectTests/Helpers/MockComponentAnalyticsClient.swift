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
    init(commonFields: CommonFields) {
        super.init(client: MockAnalyticsClientV2(), commonFields: commonFields)
    }

    // TODO: Add test helpers
}
