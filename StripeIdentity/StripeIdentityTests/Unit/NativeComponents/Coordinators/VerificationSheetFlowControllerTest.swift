//
//  VerificationSheetFlowControllerTest.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 11/3/21.
//

import XCTest
import StripeCoreTestUtils
import Vision
@_spi(STP) import StripeCore
@_spi(STP) @testable import StripeIdentity

private let mockError = NSError(domain: "", code: 0, userInfo: nil)
private let mockRequiredDataError = VerificationPageDataRequirementError(
    body: "",
    buttonText: "",
    requirement: .biometricConsent,
    title: "",
    _allResponseFieldsStorage: nil
)

final class VerificationSheetFlowControllerTest: XCTestCase {

    let flowController = VerificationSheetFlowController()
    var mockMLModelLoader: IdentityMLModelLoaderMock!
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

        mockMLModelLoader = .init()

        mockSheetController = VerificationSheetControllerMock(
            flowController: flowController,
            mlModelLoader: mockMLModelLoader
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
            sheetController: mockSheetController,
            completion: {}
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
        // API error
        let apiErrExp = expectation(description: "API error")
        flowController.nextViewController(
            missingRequirements: [.biometricConsent],
            staticContent: VerificationSheetFlowControllerTest.mockVerificationPage,
            requiredDataErrors: [],
            isSubmitted: false,
            lastError: mockError,
            sheetController: mockSheetController,
            completion: { nextVC in
                XCTAssertIs(nextVC, ErrorViewController.self)
                XCTAssertEqual((nextVC as? ErrorViewController)?.model, .error(mockError))
                apiErrExp.fulfill()
            }
        )

        // No requirements
        let noReqExp = expectation(description: "No requirements")
        flowController.nextViewController(
            missingRequirements: [],
            staticContent: VerificationSheetFlowControllerTest.mockVerificationPage,
            requiredDataErrors: [],
            isSubmitted: false,
            lastError: nil,
            sheetController: mockSheetController,
            completion: { nextVC in
                XCTAssertIs(nextVC, ErrorViewController.self)
                XCTAssertEqual((nextVC as? ErrorViewController)?.model, .error(NSError.stp_genericConnectionError()))
                noReqExp.fulfill()
            }
        )

        // No staticContent
        let noStaticContentExp = expectation(description: "No staticContent")
        flowController.nextViewController(
            missingRequirements: [.biometricConsent],
            staticContent: nil,
            requiredDataErrors: [],
            isSubmitted: false,
            lastError: nil,
            sheetController: mockSheetController,
            completion: { nextVC in
                XCTAssertIs(nextVC, ErrorViewController.self)
                XCTAssertEqual((nextVC as? ErrorViewController)?.model, .error(NSError.stp_genericConnectionError()))
                noStaticContentExp.fulfill()
            }
        )

        // requiredDataErrors
        let reqDataErrExp = expectation(description: "requiredDataErrors")
        flowController.nextViewController(
            missingRequirements: [.biometricConsent],
            staticContent: VerificationSheetFlowControllerTest.mockVerificationPage,
            requiredDataErrors: [mockRequiredDataError],
            isSubmitted: false,
            lastError: nil,
            sheetController: mockSheetController,
            completion: { nextVC in
                XCTAssertIs(nextVC, ErrorViewController.self)
                XCTAssertEqual((nextVC as? ErrorViewController)?.model, .inputError(mockRequiredDataError))
                reqDataErrExp.fulfill()
            }
        )

        wait(for: [apiErrExp, noReqExp, noStaticContentExp, reqDataErrExp], timeout: 1)
    }

    // Requires document photo but user has not selected type
    func testDocumentPhotoNoTypeError() {
        // Mock that document ML models successfully loaded
        mockMLModelLoader.documentModelsPromise.resolve(with: DocumentScannerMock())

        let exp = expectation(description: "testDocumentPhotoNoTypeError")
        nextViewController(
            missingRequirements: [.idDocumentFront],
            completion: { nextVC in
                XCTAssertIs(nextVC, ErrorViewController.self)
                XCTAssertEqual(
                    (nextVC as? ErrorViewController)?.model,
                    .error(VerificationSheetFlowControllerError.missingRequiredInput([.idDocumentType]))
                )
                exp.fulfill()
            }
        )
        wait(for: [exp], timeout: 1)
    }

    func testDocumentMLModelsNotLoadedError() {
        let exp = expectation(description: "testDocumentMLModelsNotLoadedError")

        // Mock that user has selected document type
        mockSheetController.dataStore.idDocumentType = .idCard

        // Mock that document ML models failed to load
        mockMLModelLoader.documentModelsPromise.reject(with: mockError)

        nextViewController(
            missingRequirements: [.idDocumentFront],
            completion: { nextVC in
                XCTAssertIs(nextVC, ErrorViewController.self)
                XCTAssertEqual((nextVC as? ErrorViewController)?.model, .error(NSError.stp_genericConnectionError()))
                exp.fulfill()
            }
        )
        wait(for: [exp], timeout: 1)
    }

    func testNextViewControllerSuccess() {
        let exp = expectation(description: "testNextViewControllerSuccess")
        nextViewController(
            missingRequirements: [],
            isSubmitted: true,
            completion: { nextVC in
                XCTAssertIs(nextVC, SuccessViewController.self)
                exp.fulfill()
            }
        )
        wait(for: [exp], timeout: 1)
    }

    func testNextViewControllerBiometricConsent() {
        let exp = expectation(description: "testNextViewControllerBiometricConsent")
        nextViewController(
            missingRequirements: [.biometricConsent],
            completion: { nextVC in
                XCTAssertIs(nextVC, BiometricConsentViewController.self)
                exp.fulfill()
            }
        )
        wait(for: [exp], timeout: 1)
    }

    func testNextViewControllerDocumentSelect() {
        let exp = expectation(description: "testNextViewControllerDocumentSelect")
        nextViewController(
            missingRequirements: [.idDocumentType],
            completion: { nextVC in
                XCTAssertIs(nextVC, DocumentTypeSelectViewController.self)
                exp.fulfill()
            }
        )
        wait(for: [exp], timeout: 1)
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

        // Mock that document ML models successfully loaded
        mockMLModelLoader.documentModelsPromise.resolve(with: DocumentScannerMock())

        let frontExp = expectation(description: "front")
        nextViewController(
            missingRequirements: [.idDocumentFront],
            completion: { nextVC in
                XCTAssertIs(nextVC, DocumentCaptureViewController.self)
                frontExp.fulfill()
            }
        )

        let backExp = expectation(description: "back")
        nextViewController(
            missingRequirements: [.idDocumentBack],
            completion: { nextVC in
                XCTAssertIs(nextVC, DocumentCaptureViewController.self)
                backExp.fulfill()
            }
        )

        wait(for: [frontExp, backExp], timeout: 1)
    }

    func testShouldSubmit() throws {
        let verificationPageMock = VerificationPageMock.response200
        let verificationPageDataMock = VerificationPageDataMock.response200
        let mockRequirementError = VerificationPageDataRequirementError(
            body: "",
            buttonText: "",
            requirement: .biometricConsent,
            title: "",
            _allResponseFieldsStorage: nil
        )
        let mockServerError = NSError(domain: "", code: 0, userInfo: nil)


        // Should fail with requirement error
        XCTAssertFalse(VerificationSheetFlowController.shouldSubmit(apiContent: .init(
            staticContent: try verificationPageMock.make(),
            sessionData: try verificationPageDataMock.makeWithModifications(
                requirements: [],
                errors: [mockRequirementError]
            ),
            lastError: nil
        )))
        // Should fail with server error
        XCTAssertFalse(VerificationSheetFlowController.shouldSubmit(apiContent: .init(
            staticContent: try verificationPageMock.make(),
            sessionData: try verificationPageDataMock.makeWithModifications(
                requirements: [],
                errors: []
            ),
            lastError: mockServerError
        )))
        // Should fail with non-empty missing fields
        XCTAssertFalse(VerificationSheetFlowController.shouldSubmit(apiContent: .init(
            staticContent: try verificationPageMock.make(),
            sessionData: try verificationPageDataMock.makeWithModifications(
                requirements: [.biometricConsent],
                errors: []
            ),
            lastError: nil
        )))
        // Should fail if already submitted
        XCTAssertFalse(VerificationSheetFlowController.shouldSubmit(apiContent: .init(
            staticContent: try verificationPageMock.make(),
            sessionData: try verificationPageDataMock.makeWithModifications(
                requirements: [.biometricConsent],
                errors: [],
                submitted: true
            ),
            lastError: nil
        )))
        // Otherwise, should pass
        XCTAssertTrue(VerificationSheetFlowController.shouldSubmit(apiContent: .init(
            staticContent: try verificationPageMock.make(),
            sessionData: try verificationPageDataMock.makeWithModifications(
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
        isSubmitted: Bool = false,
        completion: @escaping (UIViewController) -> Void
    ) {
        flowController.nextViewController(
            missingRequirements: missingRequirements,
            staticContent: VerificationSheetFlowControllerTest.mockVerificationPage,
            requiredDataErrors: [],
            isSubmitted: isSubmitted,
            lastError: nil,
            sheetController: mockSheetController,
            completion: completion
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
