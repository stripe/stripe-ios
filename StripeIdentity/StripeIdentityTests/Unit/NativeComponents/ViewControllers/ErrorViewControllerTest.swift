//
//  ErrorViewControllerTest.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 6/27/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCoreTestUtils
import XCTest

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

        let errorAnalytics = mockAnalyticsClient.loggedAnalyticPayloads(
            withEventName: "generic_error"
        )
        XCTAssertEqual(errorAnalytics.count, 1)

        let metadata = errorAnalytics.first?["event_metadata"] as? [String: Any]
        let errorDict = metadata?["error_details"] as? [String: Any]
        XCTAssertNotNil(errorDict)
        XCTAssertEqual(errorDict?["domain"] as? String, "custom_domain")
        XCTAssertEqual(errorDict?["code"] as? Int, 100)
        XCTAssertEqual(errorDict?["file"] as? String, "mock_file_path")
        XCTAssertEqual(errorDict?["line"] as? UInt, 123)
    }

    func testTappingContinueButton() {
        let continueText = "continue"
        let backText = "back"
        let vc = ErrorViewController(
            sheetController: mockSheetController,
            error: .inputError(
                .init(
                    backButtonText: backText, body: "body", continueButtonText: continueText, requirement: .idDocumentFront, title: "title"
                )
            )
        )

        XCTAssertEqual(vc.buttonViewModels.count, 2)
        XCTAssertEqual(vc.buttonViewModels[0].text, continueText)
        XCTAssertEqual(vc.buttonViewModels[0].state, .enabled)

        XCTAssertEqual(vc.buttonViewModels[1].text, backText)
        XCTAssertEqual(vc.buttonViewModels[1].state, .enabled)

        // mock click button tap
        vc.buttonViewModels[0].didTap()
        XCTAssertEqual(vc.buttonViewModels[0].state, .loading)
        XCTAssertEqual(vc.buttonViewModels[1].state, .disabled)

    }
}
