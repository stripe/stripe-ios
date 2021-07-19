//
//  IdentityVerificationSheetTest.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 3/8/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import XCTest

@testable import StripeIdentity
@_spi(STP) import StripeCoreTestUtils

final class IdentityVerificationSheetTest: XCTestCase {
    private let mockViewController = UIViewController()
    private let mockSecret = "vi_123_secret_456"
    private let mockAnalyticsClient = MockAnalyticsClient()

    private var sheet: IdentityVerificationSheet!

    override func setUp() {
        super.setUp()

        mockAnalyticsClient.reset()
        sheet = IdentityVerificationSheet(verificationSessionClientSecret: mockSecret, analyticsClient: mockAnalyticsClient)
    }

    func testInvalidSecret() {
        var result: IdentityVerificationSheet.VerificationFlowResult?
        sheet = IdentityVerificationSheet(verificationSessionClientSecret: "bad secret", analyticsClient: mockAnalyticsClient)
        // TODO(mludowise|RUN_MOBILESDK-120): Using `presentInternal` instead of
        // `present` so we can run tests on our CI until it's updated to iOS 14.
        sheet.presentInternal(from: mockViewController) { (r) in
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
        // TODO(mludowise|RUN_MOBILESDK-120): Using `presentInternal` instead of
        // `present` so we can run tests on our CI until it's updated to iOS 14.
        sheet.presentInternal(from: mockViewController) { _ in }

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
        XCTAssertEqual(mockAnalyticsClient.productUsage, ["IdentityVerificationSheet"])
    }
}
