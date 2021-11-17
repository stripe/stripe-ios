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
    var mockSheetController: VerificationSheetControllerMock!

    static var mockVerificationPage: VerificationPage!

    override class func setUp() {
        super.setUp()

        guard let mockVerificationPage = try? VerificationPageMock.response200.make() else {
            return XCTFail("Could not load mock verification page")
        }
        self.mockVerificationPage = mockVerificationPage
    }

    override func setUp() {
        super.setUp()

        mockSheetController = VerificationSheetControllerMock(
            flowController: flowController,
            dataStore: VerificationSessionDataStore()
        )
    }

    // Tests that `transition` calls the `submit` method on the VerificationSheetController
    func testTransitionSubmits() throws {
        // Mock that user is done entering data but data hasn't been submitted yet
        let mockVerificationSessionData = try VerificationSessionDataMock.response200.makeWithModifications(
            requirements: [],
            errors: [],
            submitted: false
        )
        let mockVerificationPage = try VerificationPageMock.response200.make()
        let exp = expectation(description: "did transition to next screen")

        flowController.transition(
            apiContent: .init(
                staticContent: mockVerificationPage,
                sessionData: mockVerificationSessionData,
                lastError: nil
            ),
            sheetController: mockSheetController,
            transitionNextScreen: { _ in
                exp.fulfill()
            }
        )
        XCTAssertTrue(mockSheetController.didRequestSubmit)
        wait(for: [exp], timeout: 1)
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
            isSubmitted: false,
            lastError: mockError,
            sheetController: mockSheetController
        )
        XCTAssertIs(nextVC, ErrorViewController.self)
        XCTAssertEqual((nextVC as? ErrorViewController)?.model, .error(mockError))

        // No requirements
        nextVC = flowController.nextViewController(
            missingRequirements: [],
            staticContent: VerificationSheetFlowControllerTest.mockVerificationPage,
            requiredDataErrors: [],
            isSubmitted: false,
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
            isSubmitted: false,
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
            isSubmitted: false,
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
            missingRequirements: [],
            isSubmitted: true
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

    func testShouldSubmit() throws {
        let verificationPageMock = VerificationPageMock.response200
        let verificationSessionDataMock = VerificationSessionDataMock.response200
        let mockRequirementError = VerificationSessionDataRequirementError(
            code: .consentDeclined,
            requirement: .biometricConsent,
            title: "",
            body: "",
            buttonText: "",
            _allResponseFieldsStorage: nil
        )
        let mockServerError = NSError(domain: "", code: 0, userInfo: nil)


        // Should fail with requirement error
        XCTAssertFalse(VerificationSheetFlowController.shouldSubmit(apiContent: .init(
            staticContent: try verificationPageMock.make(),
            sessionData: try verificationSessionDataMock.makeWithModifications(
                requirements: [],
                errors: [mockRequirementError]
            ),
            lastError: nil
        )))
        // Should fail with server error
        XCTAssertFalse(VerificationSheetFlowController.shouldSubmit(apiContent: .init(
            staticContent: try verificationPageMock.make(),
            sessionData: try verificationSessionDataMock.makeWithModifications(
                requirements: [],
                errors: []
            ),
            lastError: mockServerError
        )))
        // Should fail with non-empty missing fields
        XCTAssertFalse(VerificationSheetFlowController.shouldSubmit(apiContent: .init(
            staticContent: try verificationPageMock.make(),
            sessionData: try verificationSessionDataMock.makeWithModifications(
                requirements: [.biometricConsent],
                errors: []
            ),
            lastError: nil
        )))
        // Should fail if already submitted
        XCTAssertFalse(VerificationSheetFlowController.shouldSubmit(apiContent: .init(
            staticContent: try verificationPageMock.make(),
            sessionData: try verificationSessionDataMock.makeWithModifications(
                requirements: [.biometricConsent],
                errors: [],
                submitted: true
            ),
            lastError: nil
        )))
        // Otherwise, should pass
        XCTAssertTrue(VerificationSheetFlowController.shouldSubmit(apiContent: .init(
            staticContent: try verificationPageMock.make(),
            sessionData: try verificationSessionDataMock.makeWithModifications(
                requirements: [],
                errors: [],
                submitted: false
            ),
            lastError: nil
        )))
    }
}

private extension VerificationSheetFlowControllerTest {
    func nextViewController(
        missingRequirements: Set<VerificationPageRequirements.Missing>,
        isSubmitted: Bool = false
    ) -> UIViewController {
        return flowController.nextViewController(
            missingRequirements: missingRequirements,
            staticContent: VerificationSheetFlowControllerTest.mockVerificationPage,
            requiredDataErrors: [],
            isSubmitted: isSubmitted,
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
