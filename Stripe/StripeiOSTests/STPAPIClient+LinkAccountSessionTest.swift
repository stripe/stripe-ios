//
//  STPAPIClient+LinkAccountSessionTest.swift
//  StripeiOSTests
//
//  Created by Yuki Tokuhiro on 4/26/23.
//

@testable @_spi(STP) import StripePayments
import XCTest

final class STPAPIClient_LinkAccountSessionTest: XCTestCase {

    func testCreateLinkAccountSessionForDeferredIntent() {
        let e = expectation(description: "create link account session")
        let apiClient = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        apiClient.createLinkAccountSessionForDeferredIntent(
            sessionId: "mobile_test_\(UUID().uuidString)",
            amount: nil,
            currency: nil,
            onBehalfOf: nil,
            linkMode: nil
        ) { linkAccountSession, error in
            XCTAssertNil(error)
            XCTAssertNotNil(linkAccountSession)
            e.fulfill()
        }
        waitForExpectations(timeout: 10)
    }
}
