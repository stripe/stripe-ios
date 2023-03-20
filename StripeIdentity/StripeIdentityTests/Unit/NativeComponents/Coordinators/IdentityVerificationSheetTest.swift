//
//  IdentityVerificationSheetTest.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 3/8/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import XCTest

@_spi(STP) @testable import StripeIdentity
@_spi(STP) import StripeCoreTestUtils
@_spi(STP) import StripeCore

final class IdentityVerificationSheetTest: XCTestCase {
    private let mockViewController = UIViewController()
    private let mockSecret = "vi_123_secret_456"

    private var mockAnalyticsClientV1: MockAnalyticsClient!
    private var mockAnalyticsClientV2: MockAnalyticsClientV2!
    private var mockVerificationSheetController: VerificationSheetControllerMock!

    override func setUp() {
        super.setUp()

        mockAnalyticsClientV1 = MockAnalyticsClient()
        mockAnalyticsClientV2 = MockAnalyticsClientV2()
        mockVerificationSheetController = VerificationSheetControllerMock(
            analyticsClient: .init(
                verificationSessionId: "vi_123",
                analyticsClient: mockAnalyticsClientV2
            )
        )

    }

    func testInvalidSecret() {
        var result: IdentityVerificationSheet.VerificationFlowResult?
        let sheet = sheetWithWebUI(clientSecret: "bad secret")
        sheet.present(from: mockViewController) { (r) in
            result = r
        }
        guard case let .flowFailed(error) = result else {
            return XCTFail("Expected `flowFailed`")
        }
        guard let sheetError = error as? IdentityVerificationSheetError,
              case .invalidClientSecret = sheetError else {
            return XCTFail("Expected `IdentityVerificationSheetError.invalidClientSecret`")
        }

        // Verify failed analytic is logged
        XCTAssertEqual(mockAnalyticsClientV1.loggedAnalytics.count, 1)
        guard let failedAnalytic = mockAnalyticsClientV1.loggedAnalytics.first as? VerificationSheetFailedAnalytic else {
            return XCTFail("Expected `VerificationSheetFailedAnalytic`")
        }
        XCTAssertNil(failedAnalytic.verificationSessionId)
        guard let analyticError = failedAnalytic.error as? IdentityVerificationSheetError,
              case .invalidClientSecret = analyticError else {
            return XCTFail("Expected `IdentityVerificationSheetError.invalidClientSecret`")
        }
    }

    @available(iOS 14.3, *)
    func testAnalyticsWeb() {
        let sheet = sheetWithWebUI()
        sheet.present(from: mockViewController) { _ in }

        // Verify presented analytic is logged
        XCTAssertEqual(mockAnalyticsClientV1.loggedAnalytics.count, 1)
        guard let presentedAnalytic = mockAnalyticsClientV1.loggedAnalytics.first as? VerificationSheetPresentedAnalytic else {
            return XCTFail("Expected `VerificationSheetPresentedAnalytic`")
        }
        XCTAssertEqual(presentedAnalytic.verificationSessionId, "vi_123")

        // Mock that flow is completed
        let mockVC = VerificationFlowWebViewController(clientSecret: VerificationClientSecret(string: mockSecret)!, delegate: nil)
        sheet.verificationFlowWebViewController(mockVC, didFinish: .flowCanceled)

        // Verify closed analytic is logged
        XCTAssertEqual(mockAnalyticsClientV1.loggedAnalytics.count, 2)
        guard let closedAnalytic = mockAnalyticsClientV1.loggedAnalytics.last as? VerificationSheetClosedAnalytic else {
            return XCTFail("Expected `VerificationSheetClosedAnalytic`")
        }
        XCTAssertEqual(closedAnalytic.verificationSessionId, "vi_123")
        XCTAssertEqual(closedAnalytic.sessionResult, "flow_canceled")

        // Verify no v2 analytics were logged
        XCTAssertEqual(mockAnalyticsClientV2.loggedAnalyticsPayloads.count, 0)
    }

    func testAnalyticsWebProductUsage() {
        let _ = sheetWithWebUI()
        XCTAssertEqual(mockAnalyticsClientV1.productUsage, ["IdentityVerificationSheet"])
    }

    func testNativeAnalyticsPresent() {
        let sheet = sheetWithNativeUI()
        sheet.present(from: mockViewController) { _ in }

        // Verify presented analytic is logged
        XCTAssertEqual(mockAnalyticsClientV2.loggedAnalyticsPayloads.count, 1)
        let presentedAnalytic = mockAnalyticsClientV2.loggedAnalyticsPayloads.last
        XCTAssertEqual(presentedAnalytic?["event_name"] as? String, "sheet_presented")
        XCTAssertEqual(presentedAnalytic?["verification_session"] as? String, "vi_123")

        // Verify no v1 analytics were logged
        XCTAssertEqual(mockAnalyticsClientV1.loggedAnalytics.count, 0)
    }

    func testNativeAnalyticsCanceled() {
        let sheet = sheetWithNativeUI()
        sheet.present(from: mockViewController) { _ in }

        // Mock that flow is cancelled
        sheet.verificationSheetController(mockVerificationSheetController, didFinish: .flowCanceled)

        XCTAssertEqual(mockAnalyticsClientV2.loggedAnalyticsPayloads.count, 3)
        // Verify closed analytic
        let closedAnalytic = mockAnalyticsClientV2.loggedAnalyticPayloads(withEventName: "sheet_closed").first
        XCTAssert(analytic: closedAnalytic, hasProperty: "verification_session", withValue: "vi_123")
        XCTAssert(analytic: closedAnalytic, hasMetadata: "session_result", withValue: "flow_canceled")

        // Verify canceled analytic
        let canceledAnalytic = mockAnalyticsClientV2.loggedAnalyticPayloads(withEventName: "verification_canceled").first
        XCTAssert(analytic: canceledAnalytic, hasProperty: "verification_session", withValue: "vi_123")

        // Verify no v1 analytics were logged
        XCTAssertEqual(mockAnalyticsClientV1.loggedAnalytics.count, 0)
    }

    func testNativeAnalyticsComplete() {
        let sheet = sheetWithNativeUI()
        sheet.present(from: mockViewController) { _ in }

        // Mock that flow is completed
        sheet.verificationSheetController(mockVerificationSheetController, didFinish: .flowCompleted)

        // Verify closed analytic
        XCTAssertEqual(mockAnalyticsClientV2.loggedAnalyticsPayloads.count, 2)
        let closedAnalytic = mockAnalyticsClientV2.loggedAnalyticsPayloads.last
        XCTAssertEqual(closedAnalytic?["verification_session"] as? String, "vi_123")
        XCTAssertEqual(closedAnalytic?["event_name"] as? String, "sheet_closed")
        XCTAssertEqual(closedAnalytic?["event_metadata"] as? [String: String], ["session_result": "flow_complete"])

        // Verify no v1 analytics were logged
        XCTAssertEqual(mockAnalyticsClientV1.loggedAnalytics.count, 0)
    }

    func testNativeAnalyticsFailed() {
        let sheet = sheetWithNativeUI()
        sheet.present(from: mockViewController) { _ in }

        // Mock that data has been collected
        mockVerificationSheetController.collectedData = VerificationPageDataUpdateMock.default.collectedData!

        // Mock that flow fails
        sheet.verificationSheetController(mockVerificationSheetController, didFinish: .flowFailed(error: NSError(domain: "mock_domain", code: 27)))

        // Verify closed analytic
        XCTAssertEqual(mockAnalyticsClientV2.loggedAnalyticsPayloads.count, 2)
        let failedAnalytic = mockAnalyticsClientV2.loggedAnalyticsPayloads.last
        XCTAssertEqual(failedAnalytic?["verification_session"] as? String, "vi_123")
        XCTAssertEqual(failedAnalytic?["event_name"] as? String, "verification_failed")

        let metadata = failedAnalytic?["event_metadata"] as? [String: Any]
        XCTAssertEqual(metadata?["doc_front_upload_type"] as? String, "auto_capture")
        XCTAssertEqual(metadata?["doc_back_upload_type"] as? String, "auto_capture")

        let error = metadata?["error"] as? [String: Any]
        XCTAssertEqual(error?["domain"] as? String, "mock_domain")
        XCTAssertEqual(error?["code"] as? Int, 27)
        XCTAssertEqual(error?["file"] as? String, "IdentityVerificationSheet.swift")
        XCTAssertNotNil(error?["line"] as? UInt)

        // Verify no v1 analytics were logged
        XCTAssertEqual(mockAnalyticsClientV1.loggedAnalytics.count, 0)
    }

    @available(iOS 14.3, *)
    func testWebDelegateCallsCompletion() {
        let exp = expectation(description: "completion block called")
        let mockPresentingViewController = UIViewController(nibName: nil, bundle: nil)
        let mockWebViewController = VerificationFlowWebViewController(
            clientSecret: VerificationClientSecret(string: "vi_234_secret_456")!,
            delegate: nil
        )
        let sheet = sheetWithWebUI()

        sheet.present(from: mockPresentingViewController) { _ in
            exp.fulfill()
        }
        sheet.verificationFlowWebViewController(mockWebViewController, didFinish: .flowCanceled)
        wait(for: [exp], timeout: 1)
    }

    func testNativeDelegateCallsCompletion() {
        let exp = expectation(description: "completion block called")
        let mockPresentingViewController = UIViewController(nibName: nil, bundle: nil)
        let sheet = sheetWithNativeUI()

        sheet.present(from: mockPresentingViewController) { _ in
            exp.fulfill()
        }
        sheet.verificationSheetController(mockVerificationSheetController, didFinish: .flowCanceled)
        wait(for: [exp], timeout: 1)
    }
}

// MARK: - Helpers

private extension IdentityVerificationSheetTest {
    func sheetWithNativeUI() -> IdentityVerificationSheet {
        return IdentityVerificationSheet(
            verificationSessionClientSecret: "",
            verificationSheetController: mockVerificationSheetController,
            analyticsClient: mockAnalyticsClientV1
        )
    }

    func sheetWithWebUI(clientSecret: String? = nil) -> IdentityVerificationSheet {
        return IdentityVerificationSheet(
            verificationSessionClientSecret: clientSecret ?? mockSecret,
            verificationSheetController: nil,
            analyticsClient: mockAnalyticsClientV1
        )
    }
}
