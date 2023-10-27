//
//  DebugViewControllerTest.swift
//  StripeIdentity
//
//  Created by Chen Cen on 5/4/23.
//

import Foundation
import XCTest

@testable import StripeIdentity

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

    func testClickSubmitWithSuccess() {
        vc.didTapButton(.submit(completeOption: .success))

        XCTAssertEqual(mockSheetController.testModeReturnResult, .flowCompleted)
        XCTAssertEqual(mockSheetController.completeOption, .success)
    }

    func testClickSubmitWithSuccessAsync() {
        vc.didTapButton(.submit(completeOption: .successAsync))

        XCTAssertEqual(mockSheetController.testModeReturnResult, .flowCompleted)
        XCTAssertEqual(mockSheetController.completeOption, .successAsync)
    }

    func testClickSubmitWithFailure() {
        vc.didTapButton(.submit(completeOption: .failure))

        XCTAssertEqual(mockSheetController.testModeReturnResult, .flowCompleted)
        XCTAssertEqual(mockSheetController.completeOption, .failure)
    }

    func testClickSubmitWithFailureAsync() {
        vc.didTapButton(.submit(completeOption: .failureAsync))

        XCTAssertEqual(mockSheetController.testModeReturnResult, .flowCompleted)
        XCTAssertEqual(mockSheetController.completeOption, .failureAsync)
    }
}
