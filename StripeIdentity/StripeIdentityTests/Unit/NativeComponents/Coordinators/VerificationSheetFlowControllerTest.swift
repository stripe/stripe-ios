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

    @MainActor
    func testNetworkedIdentityReuseWaitsForConsentAndRoutesOnlyOnce() throws {
        // Given preview is enabled and reuse is available
        let api = IdentityAPIClientTestMock()
        api.supportsNetworkedIdentity = true
        let linkAPI = NetworkedIdentityAPIClientTestMock()
        var receivedKey: String?
        let flow = VerificationSheetFlowController(brandLogo: UIImage()) { key in
            receivedKey = key
            return linkAPI
        }
        let sheet = VerificationSheetControllerMock(apiClient: api, flowController: flow)
        let page = try makeNetworkedIdentityPage()

        // When the initial page still requires the sharing/biometric disclosure
        flow.nextViewController(
            skipTestMode: true, staticContentResult: .success(page), updateDataResult: nil,
            sheetController: sheet
        ) { XCTAssertIs($0, BiometricConsentViewController.self) }
        XCTAssertNil(receivedKey)

        // Then accepting consent opens NI before manual document capture
        let update = try VerificationPageDataMock.noErrorsWithMissings(with: [.idDocumentFront, .face])
        let appeared = expectation(description: "NI reuse screen")
        flow.nextViewController(
            skipTestMode: true, staticContentResult: .success(page), updateDataResult: .success(update),
            sheetController: sheet
        ) { screen in
            XCTAssertIs(screen, NetworkedIdentityFlowViewController.self)
            XCTAssertEqual((screen as? NetworkedIdentityFlowViewController)?.emailView.emailAddress, "consumer@example.com")
            appeared.fulfill()
        }
        wait(for: [appeared], timeout: 1)
        XCTAssertEqual(receivedKey, "pk_test_merchant")
        XCTAssertTrue(linkAPI.lookup.requestHistory.isEmpty)

        // ...and a subsequent transition cannot restart Link authentication
        flow.nextViewController(
            skipTestMode: true, staticContentResult: .success(page), updateDataResult: .success(update),
            sheetController: sheet
        ) { XCTAssertIs($0, DocumentWarmupViewController.self) }
    }

    func testNetworkedIdentityRequiresPreviewAndMerchantKey() throws {
        for (preview, key) in [(false, "pk_test_merchant"), (true, ""), (true, "   ")] {
            let api = IdentityAPIClientTestMock()
            api.supportsNetworkedIdentity = preview
            let flow = VerificationSheetFlowController(brandLogo: UIImage()) { _ in
                XCTFail("Link client should not be created")
                return NetworkedIdentityAPIClientTestMock()
            }
            let sheet = VerificationSheetControllerMock(apiClient: api, flowController: flow)
            let page = try makeNetworkedIdentityPage(merchantKey: key)
            let update = try VerificationPageDataMock.noErrorsWithMissings(with: [.idDocumentFront])

            flow.nextViewController(
                skipTestMode: true, staticContentResult: .success(page), updateDataResult: .success(update),
                sheetController: sheet
            ) { XCTAssertIs($0, DocumentWarmupViewController.self) }
        }
    }

    @MainActor
    func testNetworkedIdentityNewPresentationCanOfferReuseAfterCancellation() throws {
        // Given an eligible session whose first presentation was canceled without persisting skip
        let api = IdentityAPIClientTestMock()
        api.supportsNetworkedIdentity = true
        let flow = VerificationSheetFlowController(brandLogo: UIImage()) { _ in NetworkedIdentityAPIClientTestMock() }
        let sheet = VerificationSheetControllerMock(apiClient: api, flowController: flow)
        let page = try makeNetworkedIdentityPage().copyWithNewMissings(newMissings: [.idDocumentFront])
        var firstScreen: NetworkedIdentityFlowViewController?
        let firstAppeared = expectation(description: "First NI presentation")
        flow.nextViewController(
            skipTestMode: true, staticContentResult: .success(page), updateDataResult: nil,
            sheetController: sheet
        ) {
            firstScreen = $0 as? NetworkedIdentityFlowViewController
            firstAppeared.fulfill()
        }
        wait(for: [firstAppeared], timeout: 1)
        let previousScreen = try XCTUnwrap(firstScreen)
        flow.networkedIdentityFlowViewControllerDidCancel(previousScreen)

        // When the same sheet is presented again with a fresh, still-eligible bootstrap
        flow.resetNetworkedIdentityForNewPresentation()
        var secondScreen: NetworkedIdentityFlowViewController?
        let secondAppeared = expectation(description: "Second NI presentation")
        flow.nextViewController(
            skipTestMode: true, staticContentResult: .success(page), updateDataResult: nil,
            sheetController: sheet
        ) {
            secondScreen = $0 as? NetworkedIdentityFlowViewController
            secondAppeared.fulfill()
        }
        wait(for: [secondAppeared], timeout: 1)
        let currentScreen = try XCTUnwrap(secondScreen)
        XCTAssertFalse(currentScreen === previousScreen)
        XCTAssertTrue(api.networkedIdentitySkip.requestHistory.isEmpty)

        // Then late callbacks from the old screen cannot finish or detach the new presentation
        let result = try VerificationPageDataMock.noErrorsWithMissings(with: [.face])
        flow.networkedIdentityFlowViewController(previousScreen, didCompleteWith: .success(result))
        flow.networkedIdentityFlowViewController(previousScreen, didRequestFullCapture: .unavailable)
        flow.networkedIdentityFlowViewControllerDidCancel(previousScreen)
        XCTAssertNil(sheet.networkedIdentityResult)

        flow.networkedIdentityFlowViewController(currentScreen, didCompleteWith: .success(result))
        XCTAssertEqual(try sheet.networkedIdentityResult?.get(), result)
    }

    @MainActor
    func testNetworkedIdentityQueuedEntryFromPreviousPresentationIsIgnored() throws {
        let api = IdentityAPIClientTestMock()
        api.supportsNetworkedIdentity = true
        var createdClients = 0
        let flow = VerificationSheetFlowController(brandLogo: UIImage()) { _ in
            createdClients += 1
            return NetworkedIdentityAPIClientTestMock()
        }
        let sheet = VerificationSheetControllerMock(apiClient: api, flowController: flow)
        let page = try makeNetworkedIdentityPage().copyWithNewMissings(newMissings: [.idDocumentFront])

        // Given an old NI entry is queued but has not created its screen
        flow.nextViewController(
            skipTestMode: true, staticContentResult: .success(page), updateDataResult: nil,
            sheetController: sheet
        ) { _ in XCTFail("A previous presentation must not show an NI screen") }

        // When a new presentation starts before that queued callback executes
        flow.resetNetworkedIdentityForNewPresentation()
        let appeared = expectation(description: "Only current NI presentation appears")
        flow.nextViewController(
            skipTestMode: true, staticContentResult: .success(page), updateDataResult: nil,
            sheetController: sheet
        ) {
            XCTAssertIs($0, NetworkedIdentityFlowViewController.self)
            appeared.fulfill()
        }
        wait(for: [appeared], timeout: 1)

        // Then only the current presentation creates a Link client
        XCTAssertEqual(createdClients, 1)
    }

    @MainActor
    func testNetworkedIdentityQueuedResumeFromPreviousPresentationDoesNotSubmit() throws {
        let api = IdentityAPIClientTestMock()
        api.supportsNetworkedIdentity = true
        let flow = VerificationSheetFlowController(brandLogo: UIImage())
        let sheet = VerificationSheetControllerMock(apiClient: api, flowController: flow)
        let page = try makeNetworkedIdentityPage(
            state: ["consented": true, "skipped": false, "direction": "consumer_to_merchant"]
        ).copyWithNewMissings(newMissings: [])

        // Given a resumable page has queued its normal submit continuation
        flow.nextViewController(
            skipTestMode: true, staticContentResult: .success(page), updateDataResult: nil,
            sheetController: sheet
        ) { XCTAssertIs($0, LoadingViewController.self) }

        // When another presentation starts before that continuation executes
        flow.resetNetworkedIdentityForNewPresentation()
        let drained = expectation(description: "Queued resume was evaluated")
        DispatchQueue.main.async { drained.fulfill() }
        wait(for: [drained], timeout: 1)

        // Then the stale bootstrap cannot cause a submit in the new presentation
        XCTAssertNil(sheet.networkedIdentityResult)
        XCTAssertTrue(api.verificationSessionSubmit.requestHistory.isEmpty)
    }

    func testNetworkedIdentityDoesNotInterruptRemainingIndividualFields() throws {
        let api = IdentityAPIClientTestMock()
        api.supportsNetworkedIdentity = true
        let flow = VerificationSheetFlowController(brandLogo: UIImage()) { _ in
            XCTFail("Link client should not be created")
            return NetworkedIdentityAPIClientTestMock()
        }
        let sheet = VerificationSheetControllerMock(apiClient: api, flowController: flow)
        let page = try makeNetworkedIdentityPage()
        let update = try VerificationPageDataMock.noErrorsWithMissings(with: [.address])

        flow.nextViewController(
            skipTestMode: true, staticContentResult: .success(page), updateDataResult: .success(update),
            sheetController: sheet
        ) { XCTAssertIs($0, IndividualViewController.self) }
    }

    func testNetworkedIdentityDoesNotEnterFromAnUnwritableUpdatedSession() throws {
        let cases: [(StripeAPI.VerificationPage.Status, Bool, Bool)] = [
            (.canceled, false, false),
            (.processing, false, false),
            (.verified, false, false),
            (.requiresInput, false, true),
            (.requiresInput, true, true),
        ]
        for (status, submitted, closed) in cases {
            // Given an eligible bootstrap that is now stale after the consent update
            let api = IdentityAPIClientTestMock()
            api.supportsNetworkedIdentity = true
            let flow = VerificationSheetFlowController(brandLogo: UIImage()) { _ in
                XCTFail("An unwritable session must not start Link")
                return NetworkedIdentityAPIClientTestMock()
            }
            let sheet = VerificationSheetControllerMock(apiClient: api, flowController: flow)
            let page = try makeNetworkedIdentityPage()
            let update = StripeAPI.VerificationPageData(
                id: page.id, requirements: .init(errors: [], missing: [.idDocumentFront]),
                status: status, submitted: submitted, closed: closed
            )

            // When the latest response is no longer writable
            var completedSynchronously = false
            flow.nextViewController(
                skipTestMode: true, staticContentResult: .success(page), updateDataResult: .success(update),
                sheetController: sheet
            ) {
                completedSynchronously = true
                XCTAssertFalse($0 is NetworkedIdentityFlowViewController)
            }

            // Then NI does not intercept the ordinary routing for that response
            XCTAssertTrue(completedSynchronously)
        }
    }

    @MainActor
    func testNetworkedIdentityCanEnterForWritableDocumentFallbackAfterSubmission() throws {
        let api = IdentityAPIClientTestMock()
        api.supportsNetworkedIdentity = true
        let flow = VerificationSheetFlowController(brandLogo: UIImage()) { _ in NetworkedIdentityAPIClientTestMock() }
        let sheet = VerificationSheetControllerMock(apiClient: api, flowController: flow)
        let page = try makeNetworkedIdentityPage()
        let update = StripeAPI.VerificationPageData(
            id: page.id, requirements: .init(errors: [], missing: [.idDocumentFront]),
            status: .requiresInput, submitted: true, closed: false
        )
        let appeared = expectation(description: "NI can serve writable document fallback")

        flow.nextViewController(
            skipTestMode: true, staticContentResult: .success(page), updateDataResult: .success(update),
            sheetController: sheet
        ) {
            XCTAssertIs($0, NetworkedIdentityFlowViewController.self)
            appeared.fulfill()
        }
        wait(for: [appeared], timeout: 1)
    }

    func testNetworkedIdentityResumedAndSkippedFlowsDoNotRestartLink() throws {
        let states: [[String: Any]] = [
            ["consented": true, "skipped": false, "direction": "consumer_to_merchant"],
            ["consented": true, "skipped": false, "direction": "merchant_to_consumer"],
            ["consented": false, "skipped": true, "direction": NSNull()],
        ]
        for state in states {
            let api = IdentityAPIClientTestMock()
            api.supportsNetworkedIdentity = true
            let flow = VerificationSheetFlowController(brandLogo: UIImage()) { _ in
                XCTFail("Resume and skip must not restart Link")
                return NetworkedIdentityAPIClientTestMock()
            }
            let sheet = VerificationSheetControllerMock(apiClient: api, flowController: flow)
            let page = try makeNetworkedIdentityPage(state: state).copyWithNewMissings(newMissings: [.idDocumentFront])

            flow.nextViewController(
                skipTestMode: true, staticContentResult: .success(page), updateDataResult: nil,
                sheetController: sheet
            ) { XCTAssertIs($0, DocumentWarmupViewController.self) }
        }
    }

    func testNetworkedIdentityResumeWithoutMissingFieldsUsesSubmitPipeline() throws {
        for direction in ["consumer_to_merchant", "merchant_to_consumer"] {
            let api = IdentityAPIClientTestMock()
            api.supportsNetworkedIdentity = true
            let flow = VerificationSheetFlowController(brandLogo: UIImage())
            let sheet = VerificationSheetControllerMock(apiClient: api, flowController: flow)
            let page = try makeNetworkedIdentityPage(
                state: ["consented": true, "skipped": false, "direction": direction]
            ).copyWithNewMissings(newMissings: [])

            // No SuccessViewController should be shown before submission
            flow.nextViewController(
                skipTestMode: true, staticContentResult: .success(page), updateDataResult: nil,
                sheetController: sheet
            ) { XCTAssertIs($0, LoadingViewController.self) }

            let continued = expectation(description: "Resume continues through the sheet")
            DispatchQueue.main.async { continued.fulfill() }
            wait(for: [continued], timeout: 1)
            let result = try XCTUnwrap(sheet.networkedIdentityResult).get()
            XCTAssertTrue(result.requirements.missing.isEmpty)
            XCTAssertFalse(result.submitted)
            XCTAssertFalse(result.closed)
        }
    }

    @MainActor
    func testNetworkedIdentityCompletionReturnsBackendResultToSheet() throws {
        let api = IdentityAPIClientTestMock()
        api.supportsNetworkedIdentity = true
        let flow = VerificationSheetFlowController(brandLogo: UIImage()) { _ in NetworkedIdentityAPIClientTestMock() }
        let sheet = VerificationSheetControllerMock(apiClient: api, flowController: flow)
        let page = try makeNetworkedIdentityPage().copyWithNewMissings(newMissings: [.idDocumentFront])
        let appeared = expectation(description: "NI reuse screen")
        var screen: NetworkedIdentityFlowViewController?
        flow.nextViewController(
            skipTestMode: true, staticContentResult: .success(page), updateDataResult: nil,
            sheetController: sheet
        ) {
            screen = $0 as? NetworkedIdentityFlowViewController
            appeared.fulfill()
        }
        wait(for: [appeared], timeout: 1)
        let result = try VerificationPageDataMock.noErrorsWithMissings(with: [.face])

        flow.networkedIdentityFlowViewController(try XCTUnwrap(screen), didCompleteWith: .success(result))

        XCTAssertEqual(try sheet.networkedIdentityResult?.get(), result)
        XCTAssertTrue(api.verificationSessionSubmit.requestHistory.isEmpty)
    }

    @MainActor
    func testNetworkedIdentityAutomaticFallbackRemovesCompletedScreen() throws {
        let api = IdentityAPIClientTestMock()
        api.supportsNetworkedIdentity = true
        let linkAPI = NetworkedIdentityAPIClientTestMock()
        let lookedUp = expectation(description: "NI begins lookup after appearing")
        linkAPI.lookup.callBackOnRequest { lookedUp.fulfill() }
        let flow = VerificationSheetFlowController(brandLogo: UIImage()) { _ in linkAPI }
        let sheet = VerificationSheetControllerMock(apiClient: api, flowController: flow)
        let page = try makeNetworkedIdentityPage().copyWithNewMissings(newMissings: [.idDocumentFront])
        let appeared = expectation(description: "NI reuse screen")
        var screen: NetworkedIdentityFlowViewController?
        flow.nextViewController(
            skipTestMode: true, staticContentResult: .success(page), updateDataResult: nil,
            sheetController: sheet
        ) {
            screen = $0 as? NetworkedIdentityFlowViewController
            appeared.fulfill()
        }
        wait(for: [appeared], timeout: 1)
        let niScreen = try XCTUnwrap(screen)
        flow.navigationController.setViewControllers([UIViewController(), niScreen], animated: false)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        window.rootViewController = flow.navigationController
        window.makeKeyAndVisible()
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }
        XCTAssertTrue(flow.navigationController.topViewController === niScreen)
        wait(for: [lookedUp], timeout: 1)

        // The real sheet owns its controller for the whole presentation; the flow captures it weakly.
        withExtendedLifetime(sheet) {
            // Drive the real coordinator, including terminal state and credential cleanup.
            linkAPI.lookup.respondToNext(with: .success(.notFound(.init(errorMessage: "No account"))))

            let replaced = XCTNSPredicateExpectation(
                predicate: NSPredicate { _, _ in
                    flow.navigationController.viewControllers.count == 1
                        && flow.navigationController.topViewController is DocumentWarmupViewController
                },
                object: nil
            )
            wait(for: [replaced], timeout: 3)
            XCTAssertEqual(
                flow.navigationController.viewControllers.count, 1,
                "Unexpected navigation stack: \(flow.navigationController.viewControllers.map { String(reflecting: type(of: $0)) })"
            )
            XCTAssertIs(flow.navigationController.topViewController as Any, DocumentWarmupViewController.self)
            XCTAssertTrue(api.networkedIdentitySkip.requestHistory.isEmpty)
        }
    }

    @MainActor
    func testNetworkedIdentityTransitionsReplaceTheNavigationStack() {
        let coordinator = NetworkedIdentityCoordinator(
            apiClient: NetworkedIdentityAPIClientTestMock(),
            documentRequirements: .init(allowedDocumentTypes: [.passport], requiresLiveCapture: false)
        )
        let screen = NetworkedIdentityFlowViewController(coordinator: coordinator)
        flowController.navigationController.setViewControllers([UIViewController(), UIViewController()], animated: false)

        flowController.transition(to: screen, shouldAnimate: false, completion: {})
        XCTAssertEqual(flowController.navigationController.viewControllers, [screen])

        let next = UIViewController()
        flowController.transition(to: next, shouldAnimate: false, completion: {})
        XCTAssertEqual(flowController.navigationController.viewControllers, [next])
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
            skipTestMode: false,
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
            skipTestMode: false,
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
            skipTestMode: false,
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

    func testNoMoreMissingFieldsReturnSuccessViewController() throws {
        let exp = expectation(description: "No more missing fields")
        flowController.nextViewController(
            skipTestMode: false,
            staticContentResult: .success(try VerificationPageMock.response200.make()),
            updateDataResult: .success(try VerificationPageDataMock.noErrors.make()),
            sheetController: mockSheetController,
            completion: { nextVC in
                XCTAssertIs(nextVC, SuccessViewController.self)
                exp.fulfill()
            }
        )
        wait(for: [exp], timeout: 1)
    }

    // Requires document photo without type - should return DocumentTypeSelectViewController
    func testMissingDocFrontNoType() throws {
        // Mock that document ML models successfully loaded
        mockMLModelLoader.documentModelsPromise.resolve(with: .init(DocumentScannerMock()))

        let exp = expectation(description: "testMissingDocFrontNoType")
        try nextViewController(
            missingRequirements: [.idDocumentFront],
            completion: { nextVC in
                XCTAssertIs(nextVC, DocumentWarmupViewController.self)
                exp.fulfill()
            }
        )
        wait(for: [exp], timeout: 1)
    }

    func testNoSelfieConfigError() throws {
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
        wait(for: [exp], timeout: 1)
    }

    func testMLModelsNeverLoadedError() throws {
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
        wait(for: [exp], timeout: 1)
    }

    func testTestMode() throws {
        let exp = expectation(description: "testTestMode")
        try nextViewController(
            missingRequirements: [.face],
            staticContentResult: .success(try VerificationPageMock.response200TestMode.make()),
            completion: { nextVC in
                XCTAssertIs(nextVC, DebugViewController.self)
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

    func testNextViewControllerDocumentWarmup() throws {
        // Mock that user has selected document type
        mockSheetController.collectedData = .init()

        // Mock that document ML models successfully loaded
        mockMLModelLoader.documentModelsPromise.resolve(with: .init(DocumentScannerMock()))

        let frontExp = expectation(description: "front")
        try nextViewController(
            missingRequirements: [.idDocumentFront],
            completion: { nextVC in
                XCTAssertIs(nextVC, DocumentWarmupViewController.self.self)
                frontExp.fulfill()
            }
        )

        let backExp = expectation(description: "back")
        try nextViewController(
            missingRequirements: [.idDocumentBack],
            completion: { nextVC in
                XCTAssertIs(nextVC, DocumentWarmupViewController.self)
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
                XCTAssertIs(nextVC, SelfieWarmupViewController.self)
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
            skipTestMode: false,
            staticContentResult: staticContentResult,
            updateDataResult: .success(dataResponse),
            sheetController: mockSheetController,
            completion: completion
        )
    }

    private func makeNetworkedIdentityPage(
        merchantKey: String = "pk_test_merchant",
        state: [String: Any] = ["consented": false, "skipped": false, "direction": NSNull()]
    ) throws -> StripeAPI.VerificationPage {
        var fixture = try XCTUnwrap(
            JSONSerialization.jsonObject(with: VerificationPageMock.response200.data()) as? [String: Any]
        )
        fixture["merchant_publishable_key"] = merchantKey
        fixture["networked_identity"] = [
            "save_available": true,
            "reuse_available": true,
            "email": "consumer@example.com",
            "state": state,
        ]
        return try StripeJSONDecoder().decode(
            StripeAPI.VerificationPage.self,
            from: JSONSerialization.data(withJSONObject: fixture)
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
