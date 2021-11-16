//
//  VerificationSheetFlowControllerTest.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 11/3/21.
//

import XCTest
import StripeCoreTestUtils
@_spi(STP) import StripeCore
@testable import StripeIdentity

final class VerificationSheetFlowControllerTest: XCTestCase {

    let flowController = VerificationSheetFlowController()
    let mockSheetController = VerificationSheetController()

    static var mockVerificationPage: VerificationPage!

    override class func setUp() {
        guard let mockVerificationPage = try? VerificationPageMock.response200.make() else {
            return XCTFail("Could not load mock verification page")
        }
        self.mockVerificationPage = mockVerificationPage
    }

    func testNextViewControllerError() {
        let mockError = NSError(domain: "", code: 0, userInfo: nil)
        let mockRequiredDataError = VerificationSessionDataRequirementError(
            code: .consentDeclined,
            requirement: .biometricConsent,
            title: "",
            body: "",
            buttonText: "",
            _allResponseFieldsStorage: nil
        )

        var nextVC: UIViewController


        // API error
        nextVC = flowController.nextViewController(
            missingRequirements: [.biometricConsent],
            staticContent: VerificationSheetFlowControllerTest.mockVerificationPage,
            requiredDataErrors: [],
            lastError: mockError,
            sheetController: mockSheetController
        )
        XCTAssertIs(nextVC, ErrorViewController.self)
        XCTAssertEqual((nextVC as? ErrorViewController)?.model, .error(mockError))

        // No requirements
        nextVC = flowController.nextViewController(
            missingRequirements: nil,
            staticContent: VerificationSheetFlowControllerTest.mockVerificationPage,
            requiredDataErrors: [],
            lastError: nil,
            sheetController: mockSheetController
        )
        XCTAssertIs(nextVC, ErrorViewController.self)
        XCTAssertEqual((nextVC as? ErrorViewController)?.model, .error(NSError.stp_genericConnectionError()))

        // No staticContent
        nextVC = flowController.nextViewController(
            missingRequirements: [.biometricConsent],
            staticContent: nil,
            requiredDataErrors: [],
            lastError: nil,
            sheetController: mockSheetController
        )
        XCTAssertIs(nextVC, ErrorViewController.self)
        XCTAssertEqual((nextVC as? ErrorViewController)?.model, .error(NSError.stp_genericConnectionError()))

        // requiredDataErrors
        nextVC = flowController.nextViewController(
            missingRequirements: [.biometricConsent],
            staticContent: VerificationSheetFlowControllerTest.mockVerificationPage,
            requiredDataErrors: [mockRequiredDataError],
            lastError: nil,
            sheetController: mockSheetController
        )
        XCTAssertIs(nextVC, ErrorViewController.self)
        XCTAssertEqual((nextVC as? ErrorViewController)?.model, .inputError(mockRequiredDataError))

        // Requires document photo but user has not selected type
        nextVC = nextViewController(missingRequirements: [.idDocumentFront])
        XCTAssertIs(nextVC, ErrorViewController.self)
        XCTAssertEqual(
            (nextVC as? ErrorViewController)?.model,
            .error(VerificationSheetFlowControllerError.missingRequiredInput([.idDocumentType]))
        )
    }

    func testNextViewControllerSuccess() {
        // TODO(IDPROD-2759): Test against Success VC instead of Loading
        XCTAssertIs(nextViewController(
            missingRequirements: []
        ), LoadingViewController.self)
    }

    func testNextViewControllerBiometricConsent() {
        XCTAssertIs(nextViewController(
            missingRequirements: [.biometricConsent]
        ), BiometricConsentViewController.self)
    }

    func testNextViewControllerDocumentSelect() {
        XCTAssertIs(nextViewController(
            missingRequirements: [.idDocumentType]
        ), DocumentTypeSelectViewController.self)
    }

    // TODO(IDPROD-2745): Re-enable when `IndividualViewController` is supported
    /*
    func testNextViewControllerIndividualFields() {
        XCTAssertIs(nextViewController(
            missingRequirements: [.address]
        ), IndividualViewController.self)
        XCTAssertIs(nextViewController(
            missingRequirements: [.dob]
        ), IndividualViewController.self)
        XCTAssertIs(nextViewController(
            missingRequirements: [.email]
        ), IndividualViewController.self)
        XCTAssertIs(nextViewController(
            missingRequirements: [.idNumber]
        ), IndividualViewController.self)
        XCTAssertIs(nextViewController(
            missingRequirements: [.name]
        ), IndividualViewController.self)
        XCTAssertIs(nextViewController(
            missingRequirements: [.phoneNumber]
        ), IndividualViewController.self)
    }
     */
    
    func testNextViewControllerDocumentCapture() {

        // Mock that user has selected document type
        mockSheetController.dataStore.idDocumentType = .idCard
        // Mock camera feed
        mockSheetController.mockCameraFeed = MockIdentityDocumentCameraFeed(imageFiles: CapturedImageMock.frontDriversLicense.url)

        XCTAssertIs(nextViewController(
            missingRequirements: [.idDocumentFront]
        ), DocumentCaptureViewController.self)
        XCTAssertIs(nextViewController(
            missingRequirements: [.idDocumentBack]
        ), DocumentCaptureViewController.self)
    }
}

private extension VerificationSheetFlowControllerTest {
    func nextViewController(missingRequirements: Set<VerificationPageRequirements.Missing>) -> UIViewController {
        return flowController.nextViewController(
            missingRequirements: missingRequirements,
            staticContent: VerificationSheetFlowControllerTest.mockVerificationPage,
            requiredDataErrors: [],
            lastError: nil,
            sheetController: mockSheetController
        )
    }
}

extension ErrorViewController.Model: Equatable {
    public static func == (lhs: ErrorViewController.Model, rhs: ErrorViewController.Model) -> Bool {
        switch (lhs, rhs) {
        case let (.error(lError), .error(rError)):
            let lNSError = lError as NSError
            let rNSError = rError as NSError
            return lNSError.code == rNSError.code
                && lNSError.domain == rNSError.domain
                && (lNSError.userInfo as NSDictionary).isEqual(to: rNSError.userInfo)
        case let (.inputError(lError), .inputError(rError)):
            return lError == rError
        default:
            return false
        }
    }
}
