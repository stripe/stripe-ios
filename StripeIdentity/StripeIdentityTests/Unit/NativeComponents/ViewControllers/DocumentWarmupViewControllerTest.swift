//
//  DocumentWarmupViewControllerTest.swift
//  StripeIdentityTests
//
//  Created by Chen Cen on 11/7/23.
//

import Foundation
import PassKit
@_spi(STP) import StripeCore
import XCTest

@_spi(VerifyWithWallet) @testable import StripeIdentity

final class DocumentWarmupViewControllerTest: XCTestCase {

    private var vc: DocumentWarmupViewController!
    private let mockSheetController = VerificationSheetControllerMock()
    private let verifyViaWalletManager = VerifyDocumentViaWalletManagerMock()

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
                ),
                verifyViaWalletManager: verifyViaWalletManager
        )
    }

    func testTapContinue() {
        vc.flowViewModel.buttons.first?.didTap()

        // Verify transitioned to selfie capture
        XCTAssertTrue(mockSheetController.transitionedToDocumentCapture)
    }

    @available(iOS 16.0, *)
    func testWalletNonCredentialOutcomes() {
        let cancelled = NSError(
            domain: PKIdentityErrorDomain,
            code: PKIdentityError.Code.cancelled.rawValue
        )
        let unsupported = NSError(
            domain: PKIdentityErrorDomain,
            code: PKIdentityError.Code.notSupported.rawValue
        )

        XCTAssertEqual(
            VerifyDocumentViaWalletManager.nonCredentialOutcome(for: cancelled),
            .userDeclined
        )
        XCTAssertEqual(
            VerifyDocumentViaWalletManager.nonCredentialOutcome(for: unsupported),
            .noDocument
        )
        if #available(iOS 18.0, *) {
            let unsupportedRegion = NSError(
                domain: PKIdentityErrorDomain,
                code: PKIdentityError.Code.regionNotSupported.rawValue
            )
            XCTAssertEqual(
                VerifyDocumentViaWalletManager.nonCredentialOutcome(for: unsupportedRegion),
                .noDocument
            )
        }
        XCTAssertNil(
            VerifyDocumentViaWalletManager.nonCredentialOutcome(
                for: NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
            )
        )
    }

}

private final class VerifyDocumentViaWalletManagerMock: VerifyDocumentViaWalletManagerProtocol {
    func isVerifyDocumentViaWalletAvailable() async -> Bool {
        return false
    }

    @MainActor
    func requestDocument() async throws -> StripeAPI.VerificationPageWalletIdentitySessionSubmission.Status {
        return .validated
    }
}
