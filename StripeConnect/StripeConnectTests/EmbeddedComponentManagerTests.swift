//
//  EmbeddedComponentManagerTests.swift
//  StripeConnectTests
//
//  Created by Mel Ludowise on 9/24/24.
//

@_spi(PrivateBetaConnect) @testable import StripeConnect
import XCTest

class EmbeddedComponentManagerTests: XCTestCase {
    var componentManager = EmbeddedComponentManager {
        return nil
    }

    @MainActor
    func testLogout() async throws {
        // Expect a logout proxy
        let logoutProxy = try XCTUnwrap(componentManager.childWebViews.allObjects.first)
        XCTAssertEqual(componentManager.childWebViews.count, 1)
        XCTAssertEqual(logoutProxy.componentType, .logoutProxy)

        let expectation = try logoutProxy.expectationForMessageReceived(sender: LogoutSender())

        componentManager.logout()

        await fulfillment(of: [expectation], timeout: TestHelpers.defaultTimeout)
    }
}
