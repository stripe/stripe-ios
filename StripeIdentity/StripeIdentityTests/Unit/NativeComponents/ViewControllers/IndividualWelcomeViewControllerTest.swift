//
//  IndividualWelcomeViewControllerTest.swift
//  StripeIdentity
//
//  Created by Chen Cen on 2/14/23.
//

import Foundation
import XCTest

@testable import StripeIdentity

final class IndividualWelcomeViewControllerTest: XCTestCase {
    static let mockVerificationPage = try! VerificationPageMock.response200.make()

    private var vc: IndividualWelcomeViewController!
    private let mockSheetController = VerificationSheetControllerMock()

    override func setUp() {
        super.setUp()

        vc = try! IndividualWelcomeViewController(
            brandLogo: UIImage(),
            welcomeContent: IndividualWelcomeViewControllerTest.mockVerificationPage.individualWelcome,
            sheetController: mockSheetController
        )
    }

    func testGetStarted() {
        // Tap accept button
        vc.flowViewModel.buttons.first?.didTap()

        // Verify transitioned to individual
        XCTAssertTrue(mockSheetController.transitionedToIndividual)
    }

}
