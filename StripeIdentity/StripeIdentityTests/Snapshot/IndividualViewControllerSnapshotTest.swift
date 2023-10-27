//
//  IndividualViewControllerSnapshotTest.swift
//  StripeIdentity
//
//  Created by Chen Cen on 6/12/23.
//

import Foundation
import iOSSnapshotTestCase
import StripeCoreTestUtils

@testable import StripeIdentity

final class IndividualViewControllerSnapshotTest: STPSnapshotTestCase {
    static let mockVerificationPageIdAndAddr = try! VerificationPageMock.typeDocumentRequireIdNumberAndAddress.make()
    static let mockVerificationPageId = try! VerificationPageMock.typeIdNumber.make()
    static let mockVerificationPageAddr = try! VerificationPageMock.typeAddress.make()
    static let mockVerificationPagePhone = try! VerificationPageMock.typePhone.make()

    func testViewIsConfiguredFromAPIIdAndAddr() {
        testWithResponse(reponse: IndividualViewControllerSnapshotTest.mockVerificationPageIdAndAddr)
    }

    func testViewIsConfiguredFromAPIId() {
        testWithResponse(reponse: IndividualViewControllerSnapshotTest.mockVerificationPageId)
    }

    func testViewIsConfiguredFromAPIAddr() {
        testWithResponse(reponse: IndividualViewControllerSnapshotTest.mockVerificationPageAddr)
    }

    func testViewIsConfiguredFromAPIPhone() {
        testWithResponse(reponse: IndividualViewControllerSnapshotTest.mockVerificationPagePhone)
    }

    fileprivate func testWithResponse(reponse: VerificationPageMock.ResponseType) {
        let vc = IndividualViewController(
            individualContent: reponse.individual,
            missing: reponse.requirements.missing,
            sheetController: VerificationSheetControllerMock()
        )

        STPSnapshotVerifyView(vc.view)
    }

}
