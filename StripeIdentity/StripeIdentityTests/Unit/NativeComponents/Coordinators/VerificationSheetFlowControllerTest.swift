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
            dataStore: VerificationPageDataStore()
        )
    }

    func testInitialStateIsLoading() {
        XCTAssertEqual(flowController.navigationController.viewControllers.count, 1)
        XCTAssertIs(flowController.navigationController.viewControllers.first as Any,
                    LoadingViewController.self)
    }

    // Tests that `transition` calls the `submit` method on the VerificationSheetController
    func testTransitionToNextScreenSubmits() throws {
        // Mock that user is done entering data but data hasn't been submitted yet
        let mockVerificationPageData = try VerificationPageDataMock.response200.makeWithModifications(
            requirements: [],
            errors: [],
            submitted: false
        )
        let mockVerificationPage = try VerificationPageMock.response200.make()
        flowController.transitionToNextScreen(
            apiContent: .init(
                staticContent: mockVerificationPage,
                sessionData: mockVerificationPageData,
                lastError: nil
            ),
            sheetController: mockSheetController
        )
        wait(for: [mockSheetController.didFinishSubmitExp], timeout: 1)
    }

    // Tests the navigation stack between screen transitions
    func testTransitionToNextScreen() throws {
        let mockVerificationPage = try VerificationPageMock.response200.make()
        let mockNextViewController1 = UIViewController(nibName: nil, bundle: nil)
        let mockNextViewController2 = UIViewController(nibName: nil, bundle: nil)
        let mockSuccessViewController = SuccessViewController(successContent: mockVerificationPage.success)

        // Verify first transition replaces loading screen with next view controller
        flowController.transitionToNextScreen(
            withViewController: mockNextViewController1,
            shouldAnimate: false
        )
        XCTAssertEqual(flowController.navigationController.viewControllers,
                       [mockNextViewController1])

        // Verify following transition pushes view controller
        flowController.transitionToNextScreen(
            withViewController: mockNextViewController2,
            shouldAnimate: false
        )
        XCTAssertEqual(flowController.navigationController.viewControllers,
                       [mockNextViewController1, mockNextViewController2])

        // Verify transitioning to success screen replaces navigation stack
        flowController.transitionToNextScreen(
            withViewController: mockSuccessViewController,
            shouldAnimate: false
        )
        XCTAssertEqual(flowController.navigationController.viewControllers,
                       [mockSuccessViewController])
    }

    func testNextViewControllerError() {
        let mockError = NSError(domain: "", code: 0, userInfo: nil)
        let mockRequiredDataError = VerificationPageDataRequirementError(
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
        XCTAssertIs(nextViewController(
            missingRequirements: [],
            isSubmitted: true
        ), SuccessViewController.self)
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
        let VerificationPageDataMock = VerificationPageDataMock.response200
        let mockRequirementError = VerificationPageDataRequirementError(
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
            sessionData: try VerificationPageDataMock.makeWithModifications(
                requirements: [],
                errors: [mockRequirementError]
            ),
            lastError: nil
        )))
        // Should fail with server error
        XCTAssertFalse(VerificationSheetFlowController.shouldSubmit(apiContent: .init(
            staticContent: try verificationPageMock.make(),
            sessionData: try VerificationPageDataMock.makeWithModifications(
                requirements: [],
                errors: []
            ),
            lastError: mockServerError
        )))
        // Should fail with non-empty missing fields
        XCTAssertFalse(VerificationSheetFlowController.shouldSubmit(apiContent: .init(
            staticContent: try verificationPageMock.make(),
            sessionData: try VerificationPageDataMock.makeWithModifications(
                requirements: [.biometricConsent],
                errors: []
            ),
            lastError: nil
        )))
        // Should fail if already submitted
        XCTAssertFalse(VerificationSheetFlowController.shouldSubmit(apiContent: .init(
            staticContent: try verificationPageMock.make(),
            sessionData: try VerificationPageDataMock.makeWithModifications(
                requirements: [.biometricConsent],
                errors: [],
                submitted: true
            ),
            lastError: nil
        )))
        // Otherwise, should pass
        XCTAssertTrue(VerificationSheetFlowController.shouldSubmit(apiContent: .init(
            staticContent: try verificationPageMock.make(),
            sessionData: try VerificationPageDataMock.makeWithModifications(
                requirements: [],
                errors: [],
                submitted: false
            ),
            lastError: nil
        )))
    }

    func testDelegateChain() {
        let mockNavigationController = IdentityFlowNavigationController(rootViewController: UIViewController(nibName: nil, bundle: nil))
        let mockDelegate = MockDelegate()
        flowController.delegate = mockDelegate
        flowController.identityFlowNavigationControllerDidDismiss(mockNavigationController)
        XCTAssertTrue(mockDelegate.didDismissCalled)
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

private class MockDelegate: VerificationSheetFlowControllerDelegate {
    private(set) var didDismissCalled = false

    func verificationSheetFlowControllerDidDismiss(_ flowController: VerificationSheetFlowControllerProtocol) {
        didDismissCalled = true
    }
}
