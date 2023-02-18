//
//  VerificationSheetFlowControllerTest.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 11/3/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
import StripeCoreTestUtils
import Vision
import XCTest

// swift-format-ignore
@_spi(STP) @testable import StripeIdentity

private let mockError = NSError(domain: "", code: 0, userInfo: nil)

final class VerificationSheetFlowControllerTest: XCTestCase {

    let mockCollectedFields: [Set<StripeAPI.VerificationPageFieldType>] = [
        [.biometricConsent], [.idDocumentType], [.idDocumentFront, .idDocumentBack],
    ]

    let flowController = VerificationSheetFlowController(brandLogo: UIImage())
    var mockMLModelLoader: IdentityMLModelLoaderMock!
    var mockSheetController: VerificationSheetControllerMock!

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
        XCTAssertIs(
            flowController.navigationController.viewControllers.first as Any,
            LoadingViewController.self
        )
    }

    // Tests the navigation stack between screen transitions
    func testTransitionToNextScreen() throws {
        let mockVerificationPage = try VerificationPageMock.response200.make()
        let mockNextViewController1 = UIViewController(nibName: nil, bundle: nil)
        let mockNextViewController2 = UIViewController(nibName: nil, bundle: nil)
        let mockSuccessViewController = SuccessViewController(
            successContent: mockVerificationPage.success,
            sheetController: mockSheetController
        )

        let exp1 = expectation(description: "1st transition")
        let exp2 = expectation(description: "2nd transition")
        let exp3 = expectation(description: "3rd transition")

        // Verify first transition replaces loading screen with next view controller
        flowController.transition(
            to: mockNextViewController1,
            shouldAnimate: false,
            completion: { exp1.fulfill() }
        )
        XCTAssertEqual(
            flowController.navigationController.viewControllers,
            [mockNextViewController1]
        )

        // Verify following transition pushes view controller
        flowController.transition(
            to: mockNextViewController2,
            shouldAnimate: false,
            completion: { exp2.fulfill() }
        )
        XCTAssertEqual(
            flowController.navigationController.viewControllers,
            [mockNextViewController1, mockNextViewController2]
        )

        // Verify transitioning to success screen replaces navigation stack
        flowController.transition(
            to: mockSuccessViewController,
            shouldAnimate: false,
            completion: { exp3.fulfill() }
        )
        XCTAssertEqual(
            flowController.navigationController.viewControllers,
            [mockSuccessViewController]
        )

        wait(for: [exp1, exp2, exp3], timeout: 1)
    }

    func testNextViewControllerError() throws {
        // API error on data save
        let staticAPIErrExp = expectation(description: "Static API error")
        flowController.nextViewController(
            staticContentResult: .failure(mockError),
            updateDataResult: nil,
            sheetController: mockSheetController,
            completion: { nextVC in
                XCTAssertIs(nextVC, ErrorViewController.self)
                XCTAssertEqual((nextVC as? ErrorViewController)?.model, .error(mockError))
                staticAPIErrExp.fulfill()
            }
        )

        // API error on data save
        let updateAPIErrExp = expectation(description: "Update API error")
        flowController.nextViewController(
            staticContentResult: .success(try VerificationPageMock.response200.make()),
            updateDataResult: .failure(mockError),
            sheetController: mockSheetController,
            completion: { nextVC in
                XCTAssertIs(nextVC, ErrorViewController.self)
                XCTAssertEqual((nextVC as? ErrorViewController)?.model, .error(mockError))
                updateAPIErrExp.fulfill()
            }
        )

        // requiredDataErrors
        let reqDataErrExp = expectation(description: "requiredDataErrors")
        flowController.nextViewController(
            staticContentResult: .success(try VerificationPageMock.response200.make()),
            updateDataResult: .success(try VerificationPageDataMock.response200.make()),
            sheetController: mockSheetController,
            completion: { nextVC in
                XCTAssertIs(nextVC, ErrorViewController.self)
                guard case .inputError = (nextVC as? ErrorViewController)?.model else {
                    return XCTFail("Expected input error")
                }
                reqDataErrExp.fulfill()
            }
        )

        wait(for: [staticAPIErrExp, updateAPIErrExp, reqDataErrExp], timeout: 1)
    }

    func testNoMoreMissingFieldsError() throws {
        let exp = expectation(description: "No more missing fields")
        flowController.nextViewController(
            staticContentResult: .success(try VerificationPageMock.response200.make()),
            updateDataResult: .success(try VerificationPageDataMock.noErrors.make()),
            sheetController: mockSheetController,
            completion: { nextVC in
                XCTAssertIs(nextVC, ErrorViewController.self)
                XCTAssertEqual(
                    (nextVC as? ErrorViewController)?.model,
                    .error(VerificationSheetFlowControllerError.noScreenForRequirements([]))
                )
                exp.fulfill()
            }
        )
        wait(for: [exp], timeout: 1)
    }

    // Requires document photo but user has not selected type
    func testDocumentPhotoNoTypeError() throws {
        // Mock that document ML models successfully loaded
        mockMLModelLoader.documentModelsPromise.resolve(with: .init(DocumentScannerMock()))

        let exp = expectation(description: "testDocumentPhotoNoTypeError")
        try nextViewController(
            missingRequirements: [.idDocumentFront],
            completion: { nextVC in
                XCTAssertIs(nextVC, ErrorViewController.self)
                XCTAssertEqual(
                    (nextVC as? ErrorViewController)?.model,
                    .error(
                        VerificationSheetFlowControllerError.missingRequiredInput([.idDocumentType])
                    )
                )
                exp.fulfill()
            }
        )
        wait(for: [exp], timeout: 1)
    }

    func testNoSelfieConfigError() throws {
        let exp = expectation(description: "testNoSelfieConfigError")
        try nextViewController(
            missingRequirements: [.face],
            staticContentResult: .success(try VerificationPageMock.noSelfie.make()),
            completion: { nextVC in
                XCTAssertIs(nextVC, ErrorViewController.self)
                XCTAssertEqual(
                    (nextVC as? ErrorViewController)?.model,
                    .error(VerificationSheetFlowControllerError.missingSelfieConfig)
                )
                exp.fulfill()
            }
        )
        wait(for: [exp], timeout: 1)
    }

    func testMLModelsNeverLoadedError() throws {
        let exp = expectation(description: "testMLModelsNeverLoadedError")

        try nextViewController(
            missingRequirements: [.face],
            completion: { nextVC in
                XCTAssertIs(nextVC, ErrorViewController.self)
                XCTAssertEqual(
                    (nextVC as? ErrorViewController)?.model,
                    .error(
                        VerificationSheetFlowControllerError.unknown(
                            IdentityMLModelLoaderError.mlModelNeverLoaded
                        )
                    )
                )
                exp.fulfill()
            }
        )
        wait(for: [exp], timeout: 1)
    }

    func testDocumentMLModelsNotLoadedError() throws {
        let exp = expectation(description: "testDocumentMLModelsNotLoadedError")

        // Mock that user has selected document type
        mockSheetController.collectedData = .init(idDocumentType: .idCard)

        // Mock that document ML models failed to load
        mockMLModelLoader.documentModelsPromise.reject(with: mockError)

        try nextViewController(
            missingRequirements: [.idDocumentFront],
            completion: { nextVC in
                XCTAssertIs(nextVC, DocumentFileUploadViewController.self)
                exp.fulfill()
            }
        )
        wait(for: [exp], timeout: 1)
    }

    func testNextViewControllerSuccess() throws {
        let exp = expectation(description: "testNextViewControllerSuccess")
        try nextViewController(
            missingRequirements: [],
            isSubmitted: true,
            completion: { nextVC in
                XCTAssertIs(nextVC, SuccessViewController.self)
                exp.fulfill()
            }
        )
        wait(for: [exp], timeout: 1)
    }

    func testNextViewControllerBiometricConsent() throws {
        let exp = expectation(description: "testNextViewControllerBiometricConsent")
        try nextViewController(
            missingRequirements: [.biometricConsent],
            completion: { nextVC in
                XCTAssertIs(nextVC, BiometricConsentViewController.self)
                exp.fulfill()
            }
        )
        wait(for: [exp], timeout: 1)
    }

    // When verification type is document and requires Address, both .biometricConsent, .address will be missing
    // should navigate to BiometricConsent
    func testNextViewControllerBiometricConsentWithMissingAddress() throws {
        let exp = expectation(description: "testNextViewControllerBiometricConsent")
        try nextViewController(
            missingRequirements: [.biometricConsent, .address],
            completion: { nextVC in
                XCTAssertIs(nextVC, BiometricConsentViewController.self)
                exp.fulfill()
            }
        )
        wait(for: [exp], timeout: 1)
    }

    // When verification type is document and requires Address, both .biometricConsent, .idNumber will be missing
    // should navigate to BiometricConsent
    func testNextViewControllerBiometricConsentWithMissingIdNumber() throws {
        let exp = expectation(description: "testNextViewControllerBiometricConsent")
        try nextViewController(
            missingRequirements: [.biometricConsent, .idNumber],
            completion: { nextVC in
                XCTAssertIs(nextVC, BiometricConsentViewController.self)
                exp.fulfill()
            }
        )
        wait(for: [exp], timeout: 1)
    }

    func testNextViewControllerDocumentSelect() throws {
        let exp = expectation(description: "testNextViewControllerDocumentSelect")
        try nextViewController(
            missingRequirements: [.idDocumentType],
            completion: { nextVC in
                XCTAssertIs(nextVC, DocumentTypeSelectViewController.self)
                exp.fulfill()
            }
        )
        wait(for: [exp], timeout: 1)
    }

    func testNextViewControllerIndividualFields() throws {
        // When verification type is document and address/idNumber is requested,
        // after user submitted consent and document, missing should only remain .address or .idNumber.
        // should navigate to IndividualController
        try verifyIndividualViewController([.address])
        try verifyIndividualViewController([.idNumber])
    }

    func testNextViewControllerIndividualWelcome() throws {
        // When verification type is not document, .name or .dob will be missing,
        // should navigate to IndividualWelcomeViewController
        try verifyIndividualWelcomeViewController([.name, .dob, .idNumber])
        try verifyIndividualWelcomeViewController([.name, .dob, .address])
    }

    func verifyIndividualViewController(_ missingRequirements: Set<StripeAPI.VerificationPageFieldType>) throws {
        let exp = expectation(description: "testNextViewControllerIndividual")
        try nextViewController(
            missingRequirements: missingRequirements,
            completion: { nextVC in
                XCTAssertIs(nextVC, IndividualViewController.self)
                exp.fulfill()
            }
        )
        wait(for: [exp], timeout: 1)
    }

    func verifyIndividualWelcomeViewController(_ missingRequirements: Set<StripeAPI.VerificationPageFieldType>) throws {
        let exp = expectation(description: "testNextViewControllerIndividualWelcome")
        try nextViewController(
            missingRequirements: missingRequirements,
            completion: { nextVC in
                XCTAssertIs(nextVC, IndividualWelcomeViewController.self)
                exp.fulfill()
            }
        )
        wait(for: [exp], timeout: 1)
    }

    func testNextViewControllerDocumentCapture() throws {
        // Mock that user has selected document type
        mockSheetController.collectedData = .init(idDocumentType: .idCard)

        // Mock that document ML models successfully loaded
        mockMLModelLoader.documentModelsPromise.resolve(with: .init(DocumentScannerMock()))

        let frontExp = expectation(description: "front")
        try nextViewController(
            missingRequirements: [.idDocumentFront],
            completion: { nextVC in
                XCTAssertIs(nextVC, DocumentCaptureViewController.self)
                frontExp.fulfill()
            }
        )

        let backExp = expectation(description: "back")
        try nextViewController(
            missingRequirements: [.idDocumentBack],
            completion: { nextVC in
                XCTAssertIs(nextVC, DocumentCaptureViewController.self)
                backExp.fulfill()
            }
        )

        wait(for: [frontExp, backExp], timeout: 1)
    }

    func testNextViewControllerDocumentFileUpload() throws {
        // Mock that user has selected document type
        mockSheetController.collectedData = .init(idDocumentType: .idCard)

        // Mock that document ML models failed to load
        mockMLModelLoader.documentModelsPromise.reject(with: mockError)

        let frontExp = expectation(description: "front")
        try nextViewController(
            missingRequirements: [.idDocumentFront],
            completion: { nextVC in
                XCTAssertIs(nextVC, DocumentFileUploadViewController.self)
                frontExp.fulfill()
            }
        )

        let backExp = expectation(description: "back")
        try nextViewController(
            missingRequirements: [.idDocumentBack],
            completion: { nextVC in
                XCTAssertIs(nextVC, DocumentFileUploadViewController.self)
                backExp.fulfill()
            }
        )

        wait(for: [frontExp, backExp], timeout: 1)
    }

    func testNextViewControllerSelfie() throws {
        // Mock that face ML models successfully loaded
        mockMLModelLoader.faceModelsPromise.resolve(with: .init(FaceScannerMock()))

        let exp = expectation(description: "testNextViewControllerSelfie")
        try nextViewController(
            missingRequirements: [.face],
            completion: { nextVC in
                XCTAssertIs(nextVC, SelfieCaptureViewController.self)
                exp.fulfill()
            }
        )

        wait(for: [exp], timeout: 1)
    }

    func testDelegateChain() {
        let mockNavigationController = IdentityFlowNavigationController(
            rootViewController: UIViewController(nibName: nil, bundle: nil)
        )
        let mockDelegate = MockDelegate()
        flowController.delegate = mockDelegate
        flowController.identityFlowNavigationControllerDidDismiss(mockNavigationController)
        XCTAssertTrue(mockDelegate.didDismissCalled)
    }

    func testCanPopToScreen() {
        let mockViewController = MockIdentityDataCollectingViewController(
            fields: Set(StripeAPI.VerificationPageFieldType.allCases).subtracting([
                .idDocumentFront, .idDocumentBack,
            ])
        )
        flowController.navigationController.setViewControllers(
            [mockViewController],
            animated: false
        )

        XCTAssertTrue(flowController.canPopToScreen(withField: .biometricConsent))
        XCTAssertTrue(flowController.canPopToScreen(withField: .idDocumentType))
        XCTAssertFalse(flowController.canPopToScreen(withField: .idDocumentFront))
        XCTAssertFalse(flowController.canPopToScreen(withField: .idDocumentBack))
    }

    func testPopToFirstScreen() {
        let viewControllers = popToScreen(
            mockCollectedFields: mockCollectedFields,
            popToField: .biometricConsent,
            shouldResetViewController: false
        )
        XCTAssertEqual(viewControllers.map { $0.collectedFields }, [[.biometricConsent]])
        XCTAssertEqual(viewControllers.first?.didReset, false)
    }

    func testPopToMiddleScreenAndReset() {
        let viewControllers = popToScreen(
            mockCollectedFields: mockCollectedFields,
            popToField: .idDocumentType,
            shouldResetViewController: true
        )
        XCTAssertEqual(
            viewControllers.map { $0.collectedFields },
            [[.biometricConsent], [.idDocumentType]]
        )
        XCTAssertEqual(viewControllers.last?.didReset, true)
    }

    func testPopToLastScreenAndReset() {
        let viewControllers = popToScreen(
            mockCollectedFields: mockCollectedFields,
            popToField: .idDocumentBack,
            shouldResetViewController: true
        )
        XCTAssertEqual(viewControllers.map { $0.collectedFields }, mockCollectedFields)
        XCTAssertEqual(viewControllers.last?.didReset, true)
    }

}

extension VerificationSheetFlowControllerTest {
    fileprivate func nextViewController(
        missingRequirements: Set<StripeAPI.VerificationPageFieldType>,
        staticContentResult: Result<StripeAPI.VerificationPage, Error> = .success(
            try! VerificationPageMock.response200.make()
        ),
        isSubmitted: Bool = false,
        completion: @escaping (UIViewController) -> Void
    ) throws {
        let mockViewController = MockIdentityDataCollectingViewController(
            fields: Set()
        )
        flowController.navigationController.setViewControllers(
            [mockViewController],
            animated: false
        )

        let dataResponse =
            isSubmitted
            ? try VerificationPageDataMock.submitted.make()
            : try VerificationPageDataMock.noErrorsWithMissings(with: missingRequirements)

        flowController.nextViewController(
            staticContentResult: staticContentResult,
            updateDataResult: .success(dataResponse),
            sheetController: mockSheetController,
            completion: completion
        )
    }

    fileprivate func popToScreen(
        mockCollectedFields: [Set<StripeAPI.VerificationPageFieldType>],
        popToField: StripeAPI.VerificationPageFieldType,
        shouldResetViewController: Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> [MockIdentityDataCollectingViewController] {
        // Mock a VC for each collected field
        let viewControllers = mockCollectedFields.map { fields in
            return MockIdentityDataCollectingViewController(fields: fields)
        }
        flowController.navigationController.setViewControllers(viewControllers, animated: false)

        flowController.popToScreen(
            withField: popToField,
            shouldResetViewController: shouldResetViewController,
            animated: false
        )

        return flowController.navigationController.viewControllers.compactMap {
            $0 as? MockIdentityDataCollectingViewController
        }
    }
}

extension ErrorViewController.Model: Equatable {
    public static func == (lhs: ErrorViewController.Model, rhs: ErrorViewController.Model) -> Bool {
        switch (lhs, rhs) {
        case (.error(let lError), .error(let rError)):
            let lNSError = lError as NSError
            let rNSError = rError as NSError
            return lNSError.code == rNSError.code
                && lNSError.domain == rNSError.domain
                && (lNSError.userInfo as NSDictionary).isEqual(to: rNSError.userInfo)
        case (.inputError(let lError), .inputError(let rError)):
            return lError == rError
        default:
            return false
        }
    }
}

private class MockDelegate: VerificationSheetFlowControllerDelegate {
    private(set) var didDismissCalled = false

    func verificationSheetFlowControllerDidDismissNativeView(
        _ flowController: VerificationSheetFlowControllerProtocol
    ) {
        didDismissCalled = true
    }

    func verificationSheetFlowControllerDidDismissWebView(
        _ flowController: VerificationSheetFlowControllerProtocol
    ) {
        didDismissCalled = true
    }
}

private class MockIdentityDataCollectingViewController: UIViewController, IdentityDataCollecting {

    let collectedFields: Set<StripeAPI.VerificationPageFieldType>

    private(set) var didReset = false

    init(
        fields: Set<StripeAPI.VerificationPageFieldType>
    ) {
        self.collectedFields = fields
        super.init(nibName: nil, bundle: nil)
    }

    required init?(
        coder: NSCoder
    ) {
        fatalError("init(coder:) has not been implemented")
    }

    func reset() {
        didReset = true
    }
}
