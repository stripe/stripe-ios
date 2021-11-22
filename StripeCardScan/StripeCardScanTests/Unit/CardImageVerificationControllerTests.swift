//
//  CardImageVerificationControllerTests.swift
//  StripeCardScanTests
//
//  Created by Jaime Park on 11/18/21.
//

@testable import StripeCardScan
import UIKit
import XCTest

/**
 NOTE(jaimepark): This test is going to drastically change when the existing verify view controllers
 get updated.
*/
@available(iOS 11.2, *)
class CardImageVerificationControllerTests: XCTestCase {
    private var result: CardImageVerificationSheetResult?
    private var expectation: XCTestExpectation!
    private var baseViewController: UIViewController!
    private var verificationSheetController: CardImageVerificationController!

    override func setUp() {
        super.setUp()
        self.expectation = XCTestExpectation(description: "CIV Sheet result has been stored")
        self.baseViewController = UIViewController()
        self.verificationSheetController = CardImageVerificationController(delegate: self)
    }

    /// This test simulates the verification view controller closing on back button press
    func testFlowCanceled_Back() {
        /// Invoke a `VerifyCardAddViewController` being created by not passing an expected card
        verificationSheetController.present(with: nil, from: baseViewController)
        verificationSheetController.userDidCancelCardAdd(baseViewController)

        guard case .canceled(reason: .back) = result else {
            XCTFail("Expected .canceled(reason: .back)")
            return
        }

        wait(for: [expectation], timeout: 1)
    }

    /// This test simulates the verification view controller closing by pressing the manual button
    func testFlowCanceled_Close() {
        /// Invoke a `VerifyCardAddViewController` being created by not passing an expected card
        verificationSheetController.present(with: nil, from: baseViewController)
        verificationSheetController.userDidPressManualCardAdd(baseViewController)

        guard case .canceled(reason: .closed) = result else {
            XCTFail("Expected .canceled(reason: .closed)")
            return
        }

        wait(for: [expectation], timeout: 1)
    }

    /// This test simulates the verification view controller completing the scan flow
    func testFlowCompleted() {
        /// Invoke a `VerifyCardAddViewController` being created by not passing an expected card
        verificationSheetController.present(with: nil, from: baseViewController)
        verificationSheetController.userDidScanCardAdd(baseViewController, creditCard: CreditCard(number: "4242"))

        guard case .completed(scannedCard: ScannedCard(pan: "4242")) = result else {
            XCTFail("Expected .completed(scannedCard: ScannedCard(pan: \"4242\")")
            return
        }

        wait(for: [expectation], timeout: 1)
    }
}

@available(iOS 11.2, *)
extension CardImageVerificationControllerTests: CardImageVerificationControllerDelegate {
    func cardImageVerificationController(_ controller: CardImageVerificationController, didFinishWithResult result: CardImageVerificationSheetResult) {
        self.result = result
        expectation.fulfill()
    }
}
