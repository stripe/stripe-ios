//
//  ErrorViewControllerSnapshotTest.swift
//  StripeIdentityTests
//
//  Created by Chen Cen on 10/19/23.
//

import Foundation
import iOSSnapshotTestCase

@testable import StripeIdentity

class ErrorViewControllerSnapshotTest: FBSnapshotTestCase {

    override func setUp() {
        super.setUp()
//        recordMode = true
    }

    func testWithoutContinueButton() {
        testWithError(error: .init(backButtonText: "backButton", body: "body", continueButtonText: nil, requirement: .idDocumentFront, title: "title"))
    }

    func testWithContinueButton() {
        testWithError(error: .init(backButtonText: "back", body: "body", continueButtonText: "continue", requirement: .idDocumentFront, title: "title"))
    }

    fileprivate func testWithError(error: StripeAPI.VerificationPageDataRequirementError) {
        let vc = ErrorViewController(
            sheetController: VerificationSheetControllerMock(),
            error: .inputError(error)
        )
        STPSnapshotVerifyView(vc.view)
    }
}
