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
    var mockVerificationPage = try! VerificationPageMock.response200.make()
    let mockSheetController = VerificationSheetController()

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
            staticContent: mockVerificationPage,
            requiredDataErrors: [],
            lastError: mockError,
            sheetController: mockSheetController
        )
        XCTAssertIs(nextVC, ErrorViewController.self)
        XCTAssertEqual((nextVC as? ErrorViewController)?.model, .error(mockError))

        // No requirements
        nextVC = flowController.nextViewController(
            missingRequirements: nil,
            staticContent: mockVerificationPage,
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
            staticContent: mockVerificationPage,
            requiredDataErrors: [mockRequiredDataError],
            lastError: nil,
            sheetController: mockSheetController
        )
        XCTAssertIs(nextVC, ErrorViewController.self)
        XCTAssertEqual((nextVC as? ErrorViewController)?.model, .inputError(mockRequiredDataError))
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
}

private extension VerificationSheetFlowControllerTest {
    func nextViewController(missingRequirements: Set<VerificationPageRequirements.Missing>) -> UIViewController {
        return flowController.nextViewController(
            missingRequirements: missingRequirements,
            staticContent: mockVerificationPage,
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
