//
//  ErrorViewControllerTest.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 6/27/22.
//

import Foundation
import XCTest
@_spi(STP) import StripeCoreTestUtils
@testable import StripeIdentity

final class ErrorViewControllerTest: XCTestCase {

    var mockAnalyticsClient: MockAnalyticsClientV2!
    var mockSheetController: VerificationSheetControllerMock!

    override func setUp() {
        super.setUp()

        mockAnalyticsClient = .init()
        mockSheetController = .init(
            analyticsClient: IdentityAnalyticsClient(
                verificationSessionId: "",
                analyticsClient: mockAnalyticsClient
            )
        )
    }

    func testErrorLoggedOnInit() {
        let mockError = NSError(domain: "custom_domain", code: 100)
        _ = ErrorViewController(
            sheetController: mockSheetController,
            error: .error(mockError),
            filePath: "mock_file_path",
            line: 123
        )

        let errorAnalytics = mockAnalyticsClient.loggedAnalyticPayloads(withEventName: "generic_error")
        XCTAssertEqual(errorAnalytics.count, 1)

        let metadata = errorAnalytics.first?["event_metadata"] as? [String: Any]
        let errorDict = metadata?["error_details"] as? [String: Any]
        XCTAssertNotNil(errorDict)
        XCTAssertEqual(errorDict?["domain"] as? String, "custom_domain")
        XCTAssertEqual(errorDict?["code"] as? Int, 100)
        XCTAssertEqual(errorDict?["file"] as? String, "mock_file_path")
        XCTAssertEqual(errorDict?["line"] as? UInt, 123)
    }
}
