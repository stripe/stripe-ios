//
//  IdentityAnalyticsClientTest.swift
//  StripeIdentityTests
//
//  Created by Chen Cen on 3/8/24.
//

@_spi(STP) import StripeCoreTestUtils
import StripeCoreTestUtils
import XCTest

@_spi(STP) @testable import StripeCore

@testable import StripeIdentity

final class IdentityAnalyticsClientTest: XCTestCase {

    var analyticsClient: IdentityAnalyticsClient!
    var mockAnalyticsClient: MockAnalyticsClientV2!
    var sheetController: VerificationSheetControllerMock!

    override func setUp() {
        super.setUp()
        self.mockAnalyticsClient = .init()
        self.sheetController = VerificationSheetControllerMock()
        self.analyticsClient = IdentityAnalyticsClient(
            verificationSessionId: "",
            analyticsClient: mockAnalyticsClient
        )
    }

    func testNoExperiement() throws {
        sheetController.verificationPageResponse = .success(try VerificationPageMock.response200NoExp.make())
        self.analyticsClient.logScreenAppeared(screenName: .documentCapture, sheetController: sheetController)
        // mockAnalyticsClient doesn't send exp exposure, only log screen_presented
        XCTAssertEqual(mockAnalyticsClient.loggedAnalyticsPayloads.count, 1)
        XCTAssertTrue(mockAnalyticsClient.loggedAnalyticsPayloads.contains(where: { $0["event_name"] as? String == IdentityAnalyticsClient.EventName.screenAppeared.rawValue }))
    }

    func testExperimentWithEventMatchedLogged() throws {
        // log experiment exposure on screen_presented, live_capture
        sheetController.verificationPageResponse = .success(try VerificationPageMock.response200.make())
        // analytics mathces
        self.analyticsClient.logScreenAppeared(screenName: .documentCapture, sheetController: sheetController)
        // assert log
        XCTAssertEqual(mockAnalyticsClient.loggedAnalyticsPayloads.count, 2)
        XCTAssertTrue(mockAnalyticsClient.loggedAnalyticsPayloads.contains(where: { $0["event_name"] as? String == IdentityAnalyticsClient.EventName.screenAppeared.rawValue }))
        XCTAssertTrue(mockAnalyticsClient.loggedAnalyticsPayloads.contains(where: {
            $0["event_name"] as? String == IdentityAnalyticsClient.EventName.experimentExposure.rawValue &&
            $0["arb_id"] as? String == "testUserSession" &&
            $0["experiment_retrieved"] as? String == "experiment1"
        }))
    }

    func testExperimentWithoutEventMatchedNotLogged() throws {
        // log exposrue on screen_presented, live_capture
        sheetController.verificationPageResponse = .success(try VerificationPageMock.response200.make())
        // analytics doesn't match
        self.analyticsClient.logScreenAppeared(screenName: .selfieCapture, sheetController: sheetController)
        // no experiement exposure log
        XCTAssertEqual(mockAnalyticsClient.loggedAnalyticsPayloads.count, 1)
        XCTAssertTrue(mockAnalyticsClient.loggedAnalyticsPayloads.contains(where: { $0["event_name"] as? String == IdentityAnalyticsClient.EventName.screenAppeared.rawValue }))
    }

}
