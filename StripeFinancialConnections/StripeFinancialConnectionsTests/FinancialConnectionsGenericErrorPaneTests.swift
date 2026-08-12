//
//  FinancialConnectionsGenericErrorPaneTests.swift
//  StripeFinancialConnectionsTests
//
//  Created by Mat Schmid on 2026-08-12.
//

import XCTest

@_spi(STP) import StripeCore
@testable @_spi(STP) import StripeFinancialConnections

class FinancialConnectionsGenericErrorPaneTests: XCTestCase {

    private enum TestError: Error {
        case sampleError
    }

    private func extraFields(
        overrides: [String: Any?] = [:]
    ) -> [String: Any] {
        var extraFields: [String: Any] = [
            "reason": "missing_required_data",
            "use_generic_error_pane": true,
            "generic_error_pane_heading": "There was a problem accessing your account",
            "generic_error_pane_subheading": "Please try again and be sure to select **Profile information**.",
            "generic_error_pane_primary_cta": "Try again",
            "generic_error_pane_primary_cta_action": "restart_auth_flow",
            "generic_error_pane_icon_url": "https://b.stripecdn.com/icon.png",
            "generic_error_pane_image": "https://b.stripecdn.com/image.png",
        ]
        for (key, value) in overrides {
            if let value {
                extraFields[key] = value
            } else {
                extraFields.removeValue(forKey: key)
            }
        }
        return extraFields
    }

    func testParsesFullPayload() throws {
        // Given an API error carrying a complete generic error pane
        let error = try MakeStripeAPIError(statusCode: 400, extraFields: extraFields())

        // When we extract the pane
        let pane = FinancialConnectionsGenericErrorPane.from(error: error)

        // Then every field is populated
        XCTAssertEqual(pane?.heading, "There was a problem accessing your account")
        XCTAssertEqual(pane?.subheading, "Please try again and be sure to select **Profile information**.")
        XCTAssertEqual(pane?.primaryCta, "Try again")
        XCTAssertEqual(pane?.primaryCtaAction, .restartAuthFlow)
        XCTAssertEqual(pane?.iconUrl, "https://b.stripecdn.com/icon.png")
        XCTAssertEqual(pane?.imageUrl, "https://b.stripecdn.com/image.png")
    }

    func testReturnsNilWhenNotOptedIn() throws {
        // Given an API error that doesn't set `use_generic_error_pane`
        let missing = try MakeStripeAPIError(
            statusCode: 400,
            extraFields: extraFields(overrides: ["use_generic_error_pane": nil])
        )
        // ...and one that explicitly opts out
        let explicitlyFalse = try MakeStripeAPIError(
            statusCode: 400,
            extraFields: extraFields(overrides: ["use_generic_error_pane": false])
        )

        // Then neither produces a pane
        XCTAssertNil(FinancialConnectionsGenericErrorPane.from(error: missing))
        XCTAssertNil(FinancialConnectionsGenericErrorPane.from(error: explicitlyFalse))
    }

    func testReturnsNilWhenExtraFieldsAbsent() throws {
        // Given an API error with no `extra_fields` at all
        let error = try MakeStripeAPIError(statusCode: 400)

        // Then there's no pane to show
        XCTAssertNil(FinancialConnectionsGenericErrorPane.from(error: error))
    }

    func testReturnsNilForNonStripeError() {
        // Given an error that didn't come from the API
        // Then there's no pane to show
        XCTAssertNil(FinancialConnectionsGenericErrorPane.from(error: TestError.sampleError))
    }

    func testReturnsNilWhenRequiredContentIsMissing() throws {
        // Given errors that opt in but are missing content we need to render the pane
        for missingKey in [
            "generic_error_pane_heading",
            "generic_error_pane_subheading",
            "generic_error_pane_primary_cta",
        ] {
            let error = try MakeStripeAPIError(
                statusCode: 400,
                extraFields: extraFields(overrides: [missingKey: nil])
            )

            // Then we fall back rather than render a broken screen
            XCTAssertNil(
                FinancialConnectionsGenericErrorPane.from(error: error),
                "Expected no pane when \(missingKey) is missing"
            )
        }
    }

    func testUnknownPrimaryCtaActionParsesAsNil() throws {
        // Given a CTA action this version of the SDK doesn't know about
        let error = try MakeStripeAPIError(
            statusCode: 400,
            extraFields: extraFields(overrides: ["generic_error_pane_primary_cta_action": "some_future_action"])
        )

        // When we extract the pane
        let pane = FinancialConnectionsGenericErrorPane.from(error: error)

        // Then the pane still renders, but with no action we can perform
        XCTAssertNotNil(pane)
        XCTAssertNil(pane?.primaryCtaAction)
        XCTAssertEqual(pane?.heading, "There was a problem accessing your account")
    }

    func testMissingPrimaryCtaActionParsesAsNil() throws {
        // Given no CTA action at all
        let error = try MakeStripeAPIError(
            statusCode: 400,
            extraFields: extraFields(overrides: ["generic_error_pane_primary_cta_action": nil])
        )

        // Then the pane renders with no action we can perform
        XCTAssertNil(FinancialConnectionsGenericErrorPane.from(error: error)?.primaryCtaAction)
    }

    func testOptionalImagesAreOptional() throws {
        // Given a payload without an icon or an image, which the server may not send yet
        let error = try MakeStripeAPIError(
            statusCode: 400,
            extraFields: extraFields(overrides: [
                "generic_error_pane_icon_url": nil,
                "generic_error_pane_image": nil,
            ])
        )

        // When we extract the pane
        let pane = FinancialConnectionsGenericErrorPane.from(error: error)

        // Then it still renders, just without imagery
        XCTAssertNotNil(pane)
        XCTAssertNil(pane?.iconUrl)
        XCTAssertNil(pane?.imageUrl)
    }
}
