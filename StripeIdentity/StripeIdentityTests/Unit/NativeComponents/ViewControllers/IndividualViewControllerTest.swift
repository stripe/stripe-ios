//
//  IndividualViewControllerTest.swift
//  StripeIdentityTests
//
//  Created by Chen Cen on 2/6/23.
//

import Foundation
import XCTest

@testable import StripeIdentity

final class IndividualViewControllerTest: XCTestCase {

    static let mockVerificationPage = try! VerificationPageMock.response200.make()

    private var vc: IndividualViewController!

    private let mockSheetController = VerificationSheetControllerMock()

    override func setUp() {
        super.setUp()

        vc = IndividualViewController(
            individualContent: IndividualViewControllerTest.mockVerificationPage.individual,
            missing: [.name, .dob, .idNumber, .address],
            sheetController: mockSheetController
        )

    }

    func testClickedIdNumberCountryNotListed() {
        vc.individualElement.idCountryNotListedButtonElement?.didTap()
        XCTAssertEqual(mockSheetController.missingType, .idNumber)
    }

    func testClickedAddressCountryNotListed() {
        vc.individualElement.addressCountryNotListedButtonElement?.didTap()
        XCTAssertEqual(mockSheetController.missingType, .address)
    }

    @MainActor
    func testSecondTapWhileSavingDoesNotSaveAgain() async {
        // Given saving the individual data has not finished yet
        let secondSaveExp = expectation(description: "Individual data saved twice")
        secondSaveExp.expectedFulfillmentCount = 2
        secondSaveExp.isInverted = true
        mockSheetController.saveAndTransitionCallback = {
            secondSaveExp.fulfill()
        }

        // When the user taps continue twice
        vc.flowViewModel.buttons.first?.didTap()
        vc.flowViewModel.buttons.first?.didTap()

        // Then the data is saved once
        await fulfillment(of: [secondSaveExp], timeout: 0.5)
        XCTAssertEqual(mockSheetController.saveAndTransitionCallCount, 1)
    }
}
