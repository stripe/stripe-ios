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
    private let mockAnalyticsClient = MockAnalyticsClient()
    private let mockVerificationSheetController = VerificationSheetControllerMock()

    override func setUp() {
        super.setUp()

        mockAnalyticsClient.reset()
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
        XCTAssertEqual(mockAnalyticsClient.loggedAnalytics.count, 1)
        guard let failedAnalytic = mockAnalyticsClient.loggedAnalytics.first as? VerificationSheetFailedAnalytic else {
            return XCTFail("Expected `VerificationSheetFailedAnalytic`")
        }
        XCTAssertNil(failedAnalytic.verificationSessionId)
        guard let analyticError = failedAnalytic.error as? IdentityVerificationSheetError,
              case .invalidClientSecret = analyticError else {
            return XCTFail("Expected `IdentityVerificationSheetError.invalidClientSecret`")
        }
    }

    func testAnalytics() {
        let sheet = sheetWithWebUI()
        sheet.present(from: mockViewController) { _ in }

        // Verify presented analytic is logged
        XCTAssertEqual(mockAnalyticsClient.loggedAnalytics.count, 1)
        guard let presentedAnalytic = mockAnalyticsClient.loggedAnalytics.first as? VerificationSheetPresentedAnalytic else {
            return XCTFail("Expected `VerificationSheetPresentedAnalytic`")
        }
        XCTAssertEqual(presentedAnalytic.verificationSessionId, "vi_123")

        // Mock that flow is completed
        let mockVC = VerificationFlowWebViewController(clientSecret: VerificationClientSecret(string: mockSecret)!, delegate: nil)
        sheet.verificationFlowWebViewController(mockVC, didFinish: .flowCanceled)

        // Verify closed analytic is logged
        XCTAssertEqual(mockAnalyticsClient.loggedAnalytics.count, 2)
        guard let closedAnalytic = mockAnalyticsClient.loggedAnalytics.last as? VerificationSheetClosedAnalytic else {
            return XCTFail("Expected `VerificationSheetClosedAnalytic`")
        }
        XCTAssertEqual(closedAnalytic.verificationSessionId, "vi_123")
        XCTAssertEqual(closedAnalytic.sessionResult, "flow_canceled")
    }

    func testAnalyticsProductUsage() {
        let _ = sheetWithWebUI()
        XCTAssertEqual(mockAnalyticsClient.productUsage, ["IdentityVerificationSheet"])
    }

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
            analyticsClient: mockAnalyticsClient
        )
    }

    func sheetWithWebUI(clientSecret: String? = nil) -> IdentityVerificationSheet {
        return IdentityVerificationSheet(
            verificationSessionClientSecret: clientSecret ?? mockSecret,
            verificationSheetController: nil,
            analyticsClient: mockAnalyticsClient
        )
    }
}
