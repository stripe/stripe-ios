//
//  DebugViewControllerTest.swift
//  StripeIdentity
//
//  Created by Chen Cen on 5/4/23.
//

import Foundation
import XCTest

@testable import StripeIdentity

@MainActor
final class DebugViewControllerTest: XCTestCase {

    static let mockVerificationPage = try! VerificationPageMock.response200.make()

    private var vc: DebugViewController!

    private let mockSheetController = VerificationSheetControllerMock()

    override func setUp() {
        super.setUp()

        vc = DebugViewController(
            sheetController: mockSheetController
        )

    }

    func testClickCancelled() {
        vc.didTapButton(.cancelled)
        XCTAssertEqual(mockSheetController.testModeReturnResult, .flowCanceled)

    }

    func testClickFailed() {
        vc.didTapButton(.failed)
        XCTAssertEqual(mockSheetController.testModeReturnResult, .flowFailed(error: IdentityVerificationSheetError.testModeSampleError))
    }

    func testClickProceed() {
        vc.didTapButton(.preview)
        XCTAssertEqual(mockSheetController.skipTestMode, true)
    }

    func testClickSubmitWithSuccess() async {
        let transitionExp = expectation(description: "Transition completed")
        mockSheetController.testModeTransitionCallback = {
            transitionExp.fulfill()
        }

        vc.didTapButton(.submit(completeOption: .success))
        await fulfillment(of: [transitionExp], timeout: 1)

        XCTAssertEqual(mockSheetController.testModeReturnResult, .flowCompleted)
        XCTAssertEqual(mockSheetController.completeOption, .success)
    }

    func testClickSubmitWithSuccessAsync() async {
        let transitionExp = expectation(description: "Transition completed")
        mockSheetController.testModeTransitionCallback = {
            transitionExp.fulfill()
        }

        vc.didTapButton(.submit(completeOption: .successAsync))
        await fulfillment(of: [transitionExp], timeout: 1)

        XCTAssertEqual(mockSheetController.testModeReturnResult, .flowCompleted)
        XCTAssertEqual(mockSheetController.completeOption, .successAsync)
    }

    func testClickSubmitWithFailure() async {
        let transitionExp = expectation(description: "Transition completed")
        mockSheetController.testModeTransitionCallback = {
            transitionExp.fulfill()
        }

        vc.didTapButton(.submit(completeOption: .failure))
        await fulfillment(of: [transitionExp], timeout: 1)

        XCTAssertEqual(mockSheetController.testModeReturnResult, .flowCompleted)
        XCTAssertEqual(mockSheetController.completeOption, .failure)
    }

    func testClickSubmitWithFailureAsync() async {
        let transitionExp = expectation(description: "Transition completed")
        mockSheetController.testModeTransitionCallback = {
            transitionExp.fulfill()
        }

        vc.didTapButton(.submit(completeOption: .failureAsync))
        await fulfillment(of: [transitionExp], timeout: 1)

        XCTAssertEqual(mockSheetController.testModeReturnResult, .flowCompleted)
        XCTAssertEqual(mockSheetController.completeOption, .failureAsync)
    }
}
