//
//  ErrorViewControllerSnapshotTest.swift
//  StripeIdentityTests
//
//  Created by Chen Cen on 10/19/23.
//

import Foundation
import iOSSnapshotTestCase
import StripeCoreTestUtils

@testable import StripeIdentity

class ErrorViewControllerSnapshotTest: STPSnapshotTestCase {

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
