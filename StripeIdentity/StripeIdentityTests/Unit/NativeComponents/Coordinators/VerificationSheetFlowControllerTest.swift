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

@MainActor
final class VerificationSheetFlowControllerTest: XCTestCase {

    let mockCollectedFields: [Set<StripeAPI.VerificationPageFieldType>] = [
        [.biometricConsent], [.idDocumentFront, .idDocumentBack],
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
    func testTransitionToNextScreen() async throws {
        let mockVerificationPage = try VerificationPageMock.response200.make()
        let mockNextViewController1 = UIViewController(nibName: nil, bundle: nil)
        let mockNextViewController2 = UIViewController(nibName: nil, bundle: nil)
        let mockSuccessViewController = SuccessViewController(
            successContent: mockVerificationPage.success,
            sheetController: mockSheetController
        )

        // Verify first transition replaces loading screen with next view controller
        await flowController.transition(
            to: mockNextViewController1,
            shouldAnimate: false
        )
        XCTAssertEqual(
            flowController.navigationController.viewControllers,
            [mockNextViewController1]
        )

        // Verify following transition pushes view controller
        await flowController.transition(
            to: mockNextViewController2,
            shouldAnimate: false
        )
        XCTAssertEqual(
            flowController.navigationController.viewControllers,
            [mockNextViewController1, mockNextViewController2]
        )

        // Verify transitioning to success screen replaces navigation stack
        await flowController.transition(
            to: mockSuccessViewController,
            shouldAnimate: false
        )
        XCTAssertEqual(
            flowController.navigationController.viewControllers,
            [mockSuccessViewController]
        )
    }

    func testNextViewControllerError() async throws {
        // API error on data save
        let staticAPIErrVC = await flowController.nextViewController(
            skipTestMode: false,
            staticContentResult: .failure(mockError),
            updateDataResult: nil,
            sheetController: mockSheetController
        )
        XCTAssertIs(staticAPIErrVC as Any, ErrorViewController.self)
        XCTAssertEqual((staticAPIErrVC as? ErrorViewController)?.model, .error(mockError))

        // API error on data save
        let updateAPIErrVC = await flowController.nextViewController(
            skipTestMode: false,
            staticContentResult: .success(try VerificationPageMock.response200.make()),
            updateDataResult: .failure(mockError),
            sheetController: mockSheetController
        )
        XCTAssertIs(updateAPIErrVC as Any, ErrorViewController.self)
        XCTAssertEqual((updateAPIErrVC as? ErrorViewController)?.model, .error(mockError))

        // requiredDataErrors
        let requiredDataErrorVC = await flowController.nextViewController(
            skipTestMode: false,
            staticContentResult: .success(try VerificationPageMock.response200.make()),
            updateDataResult: .success(try VerificationPageDataMock.response200.make()),
            sheetController: mockSheetController
        )
        XCTAssertIs(requiredDataErrorVC as Any, ErrorViewController.self)
        guard case .inputError = (requiredDataErrorVC as? ErrorViewController)?.model else {
            return XCTFail("Expected input error")
        }
    }

    func testNoMoreMissingFieldsReturnSuccessViewController() async throws {
        let nextVC = await flowController.nextViewController(
            skipTestMode: false,
            staticContentResult: .success(try VerificationPageMock.response200.make()),
            updateDataResult: .success(try VerificationPageDataMock.noErrors.make()),
            sheetController: mockSheetController
        )
        XCTAssertIs(nextVC as Any, SuccessViewController.self)
    }

    // Requires document photo without type - should return DocumentTypeSelectViewController
    func testMissingDocFrontNoType() async throws {
        // Mock that document ML models successfully loaded
        mockMLModelLoader.documentModelsResult = .success(.init(DocumentScannerMock()))

        let exp = expectation(description: "testMissingDocFrontNoType")
        try await nextViewController(
            missingRequirements: [.idDocumentFront],
            completion: { nextVC in
                XCTAssertIs(nextVC, DocumentWarmupViewController.self)
                exp.fulfill()
            }
        )
        await fulfillment(of: [exp], timeout: 1)
    }

    func testNoSelfieConfigError() async throws {
        let exp = expectation(description: "testNoSelfieConfigError")

        let nextVC = flowController.makeSelfieCaptureViewController(
            faceScannerResult: .failure(IdentityMLModelLoaderError.mlModelNeverLoaded),
            staticContent: try VerificationPageMock.noSelfie.make(),
            sheetController: mockSheetController
        )
        XCTAssertIs(nextVC, ErrorViewController.self)
        XCTAssertEqual(
            (nextVC as? ErrorViewController)?.model,
            .error(VerificationSheetFlowControllerError.missingSelfieConfig)
        )
        exp.fulfill()
        await fulfillment(of: [exp], timeout: 1)
    }

    func testMLModelsNeverLoadedError() async throws {
        let exp = expectation(description: "testMLModelsNeverLoadedError")

        let nextVC = flowController.makeSelfieCaptureViewController(
            faceScannerResult: .failure(IdentityMLModelLoaderError.mlModelNeverLoaded),
            staticContent: try VerificationPageMock.response200.make(),
            sheetController: mockSheetController
        )
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
        await fulfillment(of: [exp], timeout: 1)
    }

    func testTestMode() async throws {
        let exp = expectation(description: "testTestMode")
        try await nextViewController(
            missingRequirements: [.face],
            staticContentResult: .success(try VerificationPageMock.response200TestMode.make()),
            completion: { nextVC in
                XCTAssertIs(nextVC, DebugViewController.self)
                exp.fulfill()
            }
        )
        await fulfillment(of: [exp], timeout: 1)
    }

    func testNextViewControllerSuccess() async throws {
        let exp = expectation(description: "testNextViewControllerSuccess")
        try await nextViewController(
            missingRequirements: [],
            isSubmitted: true,
            completion: { nextVC in
                XCTAssertIs(nextVC, SuccessViewController.self)
                exp.fulfill()
            }
        )
        await fulfillment(of: [exp], timeout: 1)
    }

    func testNextViewControllerBiometricConsent() async throws {
        let exp = expectation(description: "testNextViewControllerBiometricConsent")
        try await nextViewController(
            missingRequirements: [.biometricConsent],
            completion: { nextVC in
                XCTAssertIs(nextVC, BiometricConsentViewController.self)
                exp.fulfill()
            }
        )
        await fulfillment(of: [exp], timeout: 1)
    }

    // When verification type is document and requires Address, both .biometricConsent, .address will be missing
    // should navigate to BiometricConsent
    func testNextViewControllerBiometricConsentWithMissingAddress() async throws {
        let exp = expectation(description: "testNextViewControllerBiometricConsent")
        try await nextViewController(
            missingRequirements: [.biometricConsent, .address],
            completion: { nextVC in
                XCTAssertIs(nextVC, BiometricConsentViewController.self)
                exp.fulfill()
            }
        )
        await fulfillment(of: [exp], timeout: 1)
    }

    // When verification type is document and requires Address, both .biometricConsent, .idNumber will be missing
    // should navigate to BiometricConsent
    func testNextViewControllerBiometricConsentWithMissingIdNumber() async throws {
        let exp = expectation(description: "testNextViewControllerBiometricConsent")
        try await nextViewController(
            missingRequirements: [.biometricConsent, .idNumber],
            completion: { nextVC in
                XCTAssertIs(nextVC, BiometricConsentViewController.self)
                exp.fulfill()
            }
        )
        await fulfillment(of: [exp], timeout: 1)
    }

    func testNextViewControllerIndividualFields() async throws {
        // When verification type is document and address/idNumber is requested,
        // after user submitted consent and document, missing should only remain .address or .idNumber.
        // should navigate to IndividualController
        try await verifyIndividualViewController([.address])
        try await verifyIndividualViewController([.idNumber])
    }

    func testNextViewControllerIndividualWelcome() async throws {
        // When verification type is not document, .name or .dob will be missing,
        // should navigate to IndividualWelcomeViewController
        try await verifyIndividualWelcomeViewController([.name, .dob, .idNumber])
        try await verifyIndividualWelcomeViewController([.name, .dob, .address])
    }

    func verifyIndividualViewController(_ missingRequirements: Set<StripeAPI.VerificationPageFieldType>) async throws {
        let exp = expectation(description: "testNextViewControllerIndividual")
        try await nextViewController(
            missingRequirements: missingRequirements,
            completion: { nextVC in
                XCTAssertIs(nextVC, IndividualViewController.self)
                exp.fulfill()
            }
        )
        await fulfillment(of: [exp], timeout: 1)
    }

    func verifyIndividualWelcomeViewController(_ missingRequirements: Set<StripeAPI.VerificationPageFieldType>) async throws {
        let exp = expectation(description: "testNextViewControllerIndividualWelcome")
        try await nextViewController(
            missingRequirements: missingRequirements,
            completion: { nextVC in
                XCTAssertIs(nextVC, IndividualWelcomeViewController.self)
                exp.fulfill()
            }
        )
        await fulfillment(of: [exp], timeout: 1)
    }

    func testNextViewControllerDocumentWarmup() async throws {
        // Mock that user has selected document type
        mockSheetController.collectedData = .init()

        // Mock that document ML models successfully loaded
        mockMLModelLoader.documentModelsResult = .success(.init(DocumentScannerMock()))

        let frontExp = expectation(description: "front")
        try await nextViewController(
            missingRequirements: [.idDocumentFront],
            completion: { nextVC in
                XCTAssertIs(nextVC, DocumentWarmupViewController.self.self)
                frontExp.fulfill()
            }
        )

        let backExp = expectation(description: "back")
        try await nextViewController(
            missingRequirements: [.idDocumentBack],
            completion: { nextVC in
                XCTAssertIs(nextVC, DocumentWarmupViewController.self)
                backExp.fulfill()
            }
        )

        await fulfillment(of: [frontExp, backExp], timeout: 1)
    }

    func testNextViewControllerSelfie() async throws {
        // Mock that face ML models successfully loaded
        mockMLModelLoader.faceModelsResult = .success(.init(FaceScannerMock()))

        let exp = expectation(description: "testNextViewControllerSelfie")
        try await nextViewController(
            missingRequirements: [.face],
            completion: { nextVC in
                XCTAssertIs(nextVC, SelfieWarmupViewController.self)
                exp.fulfill()
            }
        )

        await fulfillment(of: [exp], timeout: 1)
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
            popToField: .idDocumentFront,
            shouldResetViewController: true
        )
        XCTAssertEqual(
            viewControllers.map { $0.collectedFields },
            [[.biometricConsent], [.idDocumentFront, .idDocumentBack]]
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
    ) async throws {
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

        guard let nextViewController = await flowController.nextViewController(
            skipTestMode: false,
            staticContentResult: staticContentResult,
            updateDataResult: .success(dataResponse),
            sheetController: mockSheetController
        ) else {
            XCTFail("Expected a view controller")
            return
        }

        completion(nextViewController)
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
