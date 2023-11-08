//
//  DocumentWarmupViewControllerTest.swift
//  StripeIdentityTests
//
//  Created by Chen Cen on 11/7/23.
//

import Foundation
import XCTest

@testable import StripeIdentity

final class DocumentWarmupViewControllerTest: XCTestCase {

    private var vc: DocumentWarmupViewController!
    private let mockSheetController = VerificationSheetControllerMock()

    override func setUp() {
        super.setUp()

        vc = try! DocumentWarmupViewController(
            sheetController: mockSheetController,
            staticContent:
                    .init(
                        body: "unused body",
                        buttonText: "continue",
                        idDocumentTypeAllowlist: [
                            "passport": "Passport",
                            "driving_license": "Driver's license",
                            "id_card": "Identity card",
                        ],
                        title: "unused title"
                    )
        )
    }

    func testTapContinue() {
        // Tap continue button
        vc.flowViewModel.buttons.first?.didTap()

        // Verify transitioned to selfie capture
        XCTAssertTrue(mockSheetController.transitionedToDocumentCapture)
    }

}
