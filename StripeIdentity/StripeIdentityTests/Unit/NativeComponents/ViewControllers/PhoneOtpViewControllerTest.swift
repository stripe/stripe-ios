//
//  PhoneOtpViewControllerTest.swift
//  StripeIdentityTests
//
//  Created by Chen Cen on 6/16/23.
//

import Foundation
import XCTest

@testable import StripeIdentity

@MainActor
final class PhoneOtpViewControllerTest: XCTestCase {

    static let mockVerificationPage = try! VerificationPageMock.response200.make()

    private var vc: PhoneOtpViewController!
    private var phoneOtpViewDelegateSpy: PhoneOtpViewDelegateSpy!

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
        phoneOtpViewDelegateSpy = PhoneOtpViewDelegateSpy(wrappedDelegate: vc)
        vc.phoneOtpView.delegate = phoneOtpViewDelegateSpy
    }

    func testGenerateCodeOnceWhenLoads() async throws {
        let pausedGenerateOtp = pauseGeneratePhoneOtp()

        vc.viewDidAppear(false)
        await fulfillment(of: [pausedGenerateOtp.started], timeout: 1)

        XCTAssertEqual(vc.phoneOtpView.viewModel, .RequestingOTP)
        XCTAssertNil(mockSheetController.phoneOtpSuccessResult)

        let inputtingOtp = expectViewStateUpdate()
        pausedGenerateOtp.finish(try VerificationPageDataMock.response200.make())
        await fulfillment(of: [inputtingOtp], timeout: 1)

        XCTAssertEqual(vc.phoneOtpView.viewModel, .InputtingOTP)
        XCTAssertNotNil(mockSheetController.phoneOtpSuccessResult)
    }

    func testTransitionToInputtingWhenGenerateSuccess() async throws {
        try await mockViewDidAppear()
        XCTAssertEqual(vc.phoneOtpView.viewModel, .InputtingOTP)
    }

    func testInvalidFullOtp() async throws {
        try await mockViewDidAppear()

        let pausedSaveOtp = pauseSaveOtp()
        let newOtp = "123456"
        vc.didInputFullOtp(newOtp: newOtp)

        await fulfillment(of: [pausedSaveOtp.started], timeout: 1)
        XCTAssertEqual(vc.phoneOtpView.viewModel, .SubmittingOTP(newOtp))

        let errorOtp = expectViewStateUpdate()
        pausedSaveOtp.finish(.invalidOtp)
        await fulfillment(of: [errorOtp], timeout: 1)

        XCTAssertEqual(vc.phoneOtpView.viewModel, .ErrorOTP)
    }

    func testResetFullOtpAfterTransition() async throws {
        try await mockViewDidAppear()

        let pausedSaveOtp = pauseSaveOtp()
        let newOtp = "123456"
        vc.didInputFullOtp(newOtp: newOtp)

        await fulfillment(of: [pausedSaveOtp.started], timeout: 1)
        XCTAssertEqual(vc.phoneOtpView.viewModel, .SubmittingOTP(newOtp))

        let inputtingOtp = expectViewStateUpdate()
        pausedSaveOtp.finish(.transitioned)
        await fulfillment(of: [inputtingOtp], timeout: 1)

        XCTAssertEqual(vc.phoneOtpView.viewModel, .InputtingOTP)
    }

    func testClickResend() async throws {
        try await mockViewDidAppear()

        XCTAssertEqual(vc.phoneOtpView.viewModel, .InputtingOTP)

        // click resend button, transition to RequestingOTP
        let pausedGenerateOtp = pauseGeneratePhoneOtp()
        vc.flowViewModel.buttons.first?.didTap()
        await fulfillment(of: [pausedGenerateOtp.started], timeout: 1)

        XCTAssertEqual(vc.phoneOtpView.viewModel, .RequestingOTP)

        let inputtingOtp = expectViewStateUpdate()
        pausedGenerateOtp.finish(try VerificationPageDataMock.response200.make())
        await fulfillment(of: [inputtingOtp], timeout: 1)

        XCTAssertEqual(vc.phoneOtpView.viewModel, .InputtingOTP)
    }

    func testClickCannotVerify() async throws {
        try await mockViewDidAppear()

        XCTAssertEqual(vc.phoneOtpView.viewModel, .InputtingOTP)

        // click cannot verify button, transition to RequestingCannotVerify
        let pausedCannotVerify = pauseCannotVerifyPhoneOtp()
        vc.flowViewModel.buttons.last?.didTap()
        await fulfillment(of: [pausedCannotVerify.started], timeout: 1)

        XCTAssertEqual(vc.phoneOtpView.viewModel, .RequestingCannotVerify)
        XCTAssertTrue(mockSheetController.cannotVerifyPhoneOtpCalled)

        let inputtingOtp = expectViewStateUpdate()
        pausedCannotVerify.finish()
        await fulfillment(of: [inputtingOtp], timeout: 1)

        XCTAssertEqual(vc.phoneOtpView.viewModel, .InputtingOTP)
    }

    private func mockViewDidAppear() async throws {
        let pausedGenerateOtp = pauseGeneratePhoneOtp()

        vc.viewDidAppear(false)
        await fulfillment(of: [pausedGenerateOtp.started], timeout: 1)

        XCTAssertEqual(vc.phoneOtpView.viewModel, .RequestingOTP)

        let inputtingOtp = expectViewStateUpdate()
        pausedGenerateOtp.finish(try VerificationPageDataMock.response200.make())
        await fulfillment(of: [inputtingOtp], timeout: 1)

        XCTAssertNotNil(mockSheetController.phoneOtpSuccessResult)
    }

    private func pauseGeneratePhoneOtp(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (
        started: XCTestExpectation,
        finish: (StripeAPI.VerificationPageData) -> Void
    ) {
        let started = expectation(description: "Generate OTP started")
        var continuation: CheckedContinuation<StripeAPI.VerificationPageData, Never>?

        mockSheetController.generatePhoneOtpHandler = {
            await withCheckedContinuation { checkedContinuation in
                continuation = checkedContinuation
                started.fulfill()
            }
        }

        return (started, { response in
            guard let continuation else {
                XCTFail("Generate OTP was not started", file: file, line: line)
                return
            }
            continuation.resume(returning: response)
        })
    }

    private func pauseCannotVerifyPhoneOtp() -> (
        started: XCTestExpectation,
        finish: () -> Void
    ) {
        let started = expectation(description: "Cannot verify OTP started")
        let finish = expectation(description: "Finish cannot verify OTP")

        mockSheetController.cannotVerifyPhoneOtpHandler = {
            started.fulfill()
            await self.fulfillment(of: [finish], timeout: 1)
        }

        return (started, { finish.fulfill() })
    }

    private func pauseSaveOtp(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (
        started: XCTestExpectation,
        finish: (OtpSubmissionResult) -> Void
    ) {
        let started = expectation(description: "Save OTP started")
        var continuation: CheckedContinuation<OtpSubmissionResult, Never>?

        mockSheetController.saveOtpAndMaybeTransitionHandler = {
            await withCheckedContinuation { checkedContinuation in
                continuation = checkedContinuation
                started.fulfill()
            }
        }

        return (started, { result in
            guard let continuation else {
                XCTFail("Save OTP was not started", file: file, line: line)
                return
            }
            continuation.resume(returning: result)
        })
    }

    private func expectViewStateUpdate() -> XCTestExpectation {
        let expectation = expectation(description: "View state updated")
        phoneOtpViewDelegateSpy.viewStateDidUpdateCallback = { [weak self] in
            self?.phoneOtpViewDelegateSpy.viewStateDidUpdateCallback = nil
            expectation.fulfill()
        }
        return expectation
    }

}

private final class PhoneOtpViewDelegateSpy: PhoneOtpViewDelegate {
    weak var wrappedDelegate: PhoneOtpViewDelegate?
    var viewStateDidUpdateCallback: (() -> Void)?

    init(wrappedDelegate: PhoneOtpViewDelegate) {
        self.wrappedDelegate = wrappedDelegate
    }

    func didInputFullOtp(newOtp: String) {
        wrappedDelegate?.didInputFullOtp(newOtp: newOtp)
    }

    func viewStateDidUpdate() {
        wrappedDelegate?.viewStateDidUpdate()
        viewStateDidUpdateCallback?()
    }
}
