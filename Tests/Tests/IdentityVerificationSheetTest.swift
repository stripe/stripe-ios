//
//  IdentityVerificationSheetTest.swift
//  StripeiOS
//
//  Created by Mel Ludowise on 3/8/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import XCTest

@testable import Stripe

final class IdentityVerificationSheetTest: XCTestCase {
    private let mockViewController = UIViewController()
    private let mockSecret = "vi_123_secret_456"
    private var sheet: IdentityVerificationSheet!

    override func setUp() {
        super.setUp()

        sheet = IdentityVerificationSheet(verificationSessionClientSecret: mockSecret)
    }

    func testInvalidSecret() {
        var result: IdentityVerificationSheet.VerificationFlowResult?
        sheet = IdentityVerificationSheet(verificationSessionClientSecret: "bad secret")
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
    }

    func testAnalytics() {
        // TODO(mludowise|IDPROD-1438)
    }
}
