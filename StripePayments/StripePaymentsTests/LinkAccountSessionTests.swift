//
//  LinkAccountSessionTests.swift
//  StripePaymentsTests
//

import XCTest

@_spi(STP) @testable import StripePayments

final class LinkAccountSessionTests: XCTestCase {

    func testDecodesPermissions() throws {
        // Given
        let response: [AnyHashable: Any] = [
            "id": "fcsess_123",
            "livemode": false,
            "client_secret": "fcsess_123_secret_456",
            "permissions": ["payment_method", "balances"],
        ]

        // When
        let session = try XCTUnwrap(LinkAccountSession.decodedObject(fromAPIResponse: response))

        // Then
        XCTAssertEqual(session.permissions, ["payment_method", "balances"])
    }

    func testMissingPermissionsDefaultsToEmpty() throws {
        // Given
        let response: [AnyHashable: Any] = [
            "id": "fcsess_123",
            "livemode": false,
            "client_secret": "fcsess_123_secret_456",
        ]

        // When
        let session = try XCTUnwrap(LinkAccountSession.decodedObject(fromAPIResponse: response))

        // Then
        XCTAssertTrue(session.permissions.isEmpty)
    }
}
