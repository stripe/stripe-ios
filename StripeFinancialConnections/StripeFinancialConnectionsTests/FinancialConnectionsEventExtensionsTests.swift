//
//  FinancialConnectionsEventExtensionsTests.swift
//  StripeFinancialConnectionsTests
//

import XCTest

@_spi(STP) import StripeCore
@testable @_spi(STP) import StripeFinancialConnections

class FinancialConnectionsEventExtensionsTests: XCTestCase {

    func testNoEligibleAccountsErrorEvent() throws {
        // Given an API error containing the user-facing event from the backend
        let error = try MakeStripeAPIError(
            statusCode: 400,
            extraFields: [
                "events_to_emit": """
                [
                    {
                        "type": "error",
                        "error": {
                            "error_code": "no_eligible_accounts"
                        }
                    }
                ]
                """,
            ]
        )

        // When the SDK converts the response into public events
        let events = FinancialConnectionsEventPayload.events(fromError: error)

        // Then it preserves the backend error code instead of using unexpected_error
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.name, .error)
        XCTAssertEqual(events.first?.metadata.errorCode, .noEligibleAccounts)
    }
}
