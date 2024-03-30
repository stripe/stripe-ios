//
//  PhoneOtpViewControllerTest.swift
//  StripeIdentityTests
//
//  Created by Chen Cen on 6/16/23.
//

import Foundation
import XCTest

@testable import StripeIdentity

final class PhoneOtpViewControllerTest: XCTestCase {

    static let mockVerificationPage = try! VerificationPageMock.response200.make()

    private var vc: PhoneOtpViewController!

    private let mockSheetController = VerificationSheetControllerMock()

    private let phoneOtpContent = StripeAPI.VerificationPageStaticContentPhoneOtpPage(
        title: "title",
        body: "body",
        redactedPhoneNumber: "(***)*****12",
        errorOtpMessage: "error",
        resendButtonText: "resend",
        cannotVerifyButtonText: "cannot verify",
        otpLength: 6
    )

    override func setUp() {
        super.setUp()

        vc = PhoneOtpViewController(phoneOtpContent: phoneOtpContent, sheetController: mockSheetController)

        vc.viewDidAppear(false)
    }

    func testGenerateCodeOnceWhenLoads() {
        vc.viewDidLoad()
        XCTAssertEqual(vc.phoneOtpView.viewModel, .RequestingOTP)
        XCTAssertNotNil(mockSheetController.generatePhonOtpSuccessCallback)
    }

    func testTransitionToInputtingWhenGenerateSuccess() throws {
        try mockViewDidLoad()
        XCTAssertEqual(vc.phoneOtpView.viewModel, .InputtingOTP)
    }

    func testGetFullOtp() throws {
        try mockViewDidLoad()

        // get full OTP, transition to SubmittingOTP
        let newOtp = "123456"
        vc.didInputFullOtp(newOtp: newOtp)
        XCTAssertEqual(vc.phoneOtpView.viewModel, .SubmittingOTP(newOtp))
        XCTAssertNotNil(mockSheetController.saveOtpAndMaybeTransitionCompletion)
        XCTAssertNotNil(mockSheetController.saveOtpAndMaybeTransitionInvalidOtp)

        // mock invalid OTP, transition to ErrorOTP
        mockSheetController.saveOtpAndMaybeTransitionInvalidOtp!()
        XCTAssertEqual(vc.phoneOtpView.viewModel, .ErrorOTP)
    }

    func testClickResend() throws {
        try mockViewDidLoad()

        XCTAssertEqual(vc.phoneOtpView.viewModel, .InputtingOTP)

        // click resend button, transition to RequestingOTP
        vc.flowViewModel.buttons.first?.didTap()

        XCTAssertEqual(vc.phoneOtpView.viewModel, .RequestingOTP)
    }

    func testClickCannotVerify() throws {
        try mockViewDidLoad()

        XCTAssertEqual(vc.phoneOtpView.viewModel, .InputtingOTP)

        // click cannot verify button, transition to RequestingCannotVerify
        vc.flowViewModel.buttons.last?.didTap()

        XCTAssertEqual(vc.phoneOtpView.viewModel, .RequestingCannotVerify)
        XCTAssertTrue(mockSheetController.cannotVerifyPhoneOtpCalled)

    }

    private func mockViewDidLoad() throws {
        vc.viewDidLoad()
        XCTAssertEqual(vc.phoneOtpView.viewModel, .RequestingOTP)
        XCTAssertNotNil(mockSheetController.generatePhonOtpSuccessCallback)

        // mock network call success
        mockSheetController.generatePhonOtpSuccessCallback!(
            try VerificationPageDataMock.response200.make()
        )
    }

}
