//
//  VerificationSheetFlowControllerTest.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 11/3/21.
//

import XCTest
import StripeCoreTestUtils
@testable import StripeIdentity

final class VerificationSheetFlowControllerTest: XCTestCase {

    let flowController = VerificationSheetFlowController()
    var mockVerificationPage = try! VerificationPageMock.response200.make()
    let mockSheetController = VerificationSheetController()

    func testNextViewControllerError() {
        // TODO(IDPROD-2749): Test against an Error VC instead of Loading

        // API error
        XCTAssertIs(flowController.nextViewController(
            missingRequirements: [.biometricConsent],
            staticContent: mockVerificationPage,
            requiredDataErrors: [],
            lastError: NSError(domain: "", code: 0, userInfo: nil),
            sheetController: mockSheetController
        ), LoadingViewController.self)

        // No requirements
        XCTAssertIs(flowController.nextViewController(
            missingRequirements: nil,
            staticContent: mockVerificationPage,
            requiredDataErrors: [],
            lastError: nil,
            sheetController: mockSheetController
        ), LoadingViewController.self)

        // No staticContent
        XCTAssertIs(flowController.nextViewController(
            missingRequirements: [.biometricConsent],
            staticContent: nil,
            requiredDataErrors: [],
            lastError: nil,
            sheetController: mockSheetController
        ), LoadingViewController.self)

        // requiredDataErrors
        XCTAssertIs(flowController.nextViewController(
            missingRequirements: [.biometricConsent],
            staticContent: mockVerificationPage,
            requiredDataErrors: [.init(
                code: .consentDeclined,
                requirement: .biometricConsent,
                title: "",
                body: "",
                buttonText: "",
                _allResponseFieldsStorage: nil
            )],
            lastError: nil,
            sheetController: mockSheetController
        ), LoadingViewController.self)
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
