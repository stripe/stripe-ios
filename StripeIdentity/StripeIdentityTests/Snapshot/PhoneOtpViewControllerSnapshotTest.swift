//
//  PhoneOtpViewControllerSnapshotTest.swift
//  StripeIdentityTests
//
//  Created by Chen Cen on 6/16/23.
//

import Foundation
import iOSSnapshotTestCase
import StripeCoreTestUtils

@testable import StripeIdentity

final class PhoneOtpViewControllerSnapshotTest: STPSnapshotTestCase {

    func testInputtingOTP() {
        verifyView(with: .InputtingOTP)
    }

    func testSubmittingOTP() {
        verifyView(with: .SubmittingOTP("123456"))
    }

    func testErrorOTP() {
        verifyView(with: .ErrorOTP)
    }

    func testRequestingOTP() {
        verifyView(with: .RequestingOTP)
    }

    func testRequestingCannotVerify() {
        verifyView(with: .RequestingCannotVerify)
    }

}

extension PhoneOtpViewControllerSnapshotTest {
    fileprivate func verifyView(
        with viewModel: PhoneOtpView.ViewModel
    ) {
        let vc = PhoneOtpViewController(phoneOtpContent: PhoneOtpPageMock.default, sheetController: VerificationSheetControllerMock())
        vc.viewDidLoad()
        vc.phoneOtpView.configure(with: viewModel)
        vc.updateUI()

        STPSnapshotVerifyView(vc.view)
    }
}
