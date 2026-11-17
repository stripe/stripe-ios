//
//  DocumentCaptureViewControllerTest.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 11/11/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import AVKit
import Foundation
@_spi(InternalOnlyAPI) import StripeCameraCoreTestUtils
@_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripeCoreTestUtils
import XCTest

@testable@_spi(InternalOnlyAPI) import StripeCameraCore
@testable import StripeIdentity

final class DocumentCaptureViewControllerTest: XCTestCase {

    let mockCameraSession = MockTestCameraSession()

    static var mockVerificationPage: StripeAPI.VerificationPage!
    var mockFlowController: VerificationSheetFlowControllerMock!
    var mockSheetController: VerificationSheetControllerMock!
    var mockDocumentUploader: DocumentUploaderMock!
    var mockDocumentScanner: ImageScannerMock<DocumentScannerOutput?>!
    var mockAnalyticsClient: MockAnalyticsClientV2!
    let mockConcurrencyManager = ImageScanningConcurrencyManagerMock()
    let mockCameraPermissionsManager = MockCameraPermissionsManager()
    let mockAppSettingsHelper = MockAppSettingsHelper()

    let mockVideoOutput = AVCaptureVideoDataOutput()
    lazy var mockCaptureConnection = AVCaptureConnection(inputPorts: [], output: mockVideoOutput)

    static var mockSampleBuffer: CMSampleBuffer!

    let mockError = NSError(domain: "mock_error", code: 100, userInfo: nil)

    override static func setUp() {
        super.setUp()
        mockSampleBuffer = CapturedImageMock.frontDriversLicense.image.convertToSampleBuffer()
        guard let mockVerificationPage = try? VerificationPageMock.response200.make() else {
            return XCTFail("Could not load VerificationPageMock")
        }
        self.mockVerificationPage = mockVerificationPage
    }

    override func setUp() {
        super.setUp()
        mockFlowController = .init()
        mockDocumentUploader = .init()
        mockAnalyticsClient = .init()
        mockSheetController = .init(
            flowController: mockFlowController,
            analyticsClient: IdentityAnalyticsClient(
                verificationSessionId: "",
                analyticsClient: mockAnalyticsClient
            )
        )
        mockDocumentScanner = .init()
    }

    func testInitialState() {
        let vc = makeViewController(documentType: .idCard)
        verify(
            vc,
            expectedState: .initial,
            expectedButtonState: .disabled
        )
    }

    func testTransitionFromInitialCardFront() {
        let vc = makeViewController(state: .initial)
        // Mock that view appeared
        vc.viewWillAppear(false)
        // Verify camera access requested
        grantCameraAccess()
        // Verify camera configured
        waitForCameraSessionToConfigure(setupResult: .success)
        // Verify camera session started
        waitForCameraSessionToStart()
        // Verify state is scanning
        verify(
            vc,
            expectedState: .scanning(.front, nil),
            expectedButtonState: .disabled
        )
    }

    func testTransitionFromScanningCardFrontLegacy() {
        let vc = makeViewController(
            state: .scanning(.front, nil)
        )
        let mockDocumentScannerOutput = makeDocumentScannerOutputLegacy(with: .idCardFront)
        // Mock timer so we can verify it was invalidated
        mockTimeoutTimer(vc)
        mockCameraFrameCaptured(vc)
        // Mock that scanner found desired classification
        mockConcurrencyManager.respondToScan(output: mockDocumentScannerOutput)
        verify(
            vc,
            expectedState: .scanned(.front, UIImage()),
            expectedButtonState: .enabled
        )
        // Verify timeout timer was invalidated
        XCTAssertEqual(vc.imageScanningSession.timeoutTimer?.isValid, false)
        waitForCameraSessionToStop()
        XCTAssertTrue(mockDocumentScanner.didReset)
        XCTAssertTrue(mockConcurrencyManager.didReset)
        // Verify image started uploading
        XCTAssertEqual(mockDocumentUploader.uploadedSide, .front)
        XCTAssertEqual(mockDocumentUploader.uploadMethod, .autoCapture)
        XCTAssertEqual(
            mockDocumentUploader.uploadedDocumentScannerOutput,
            mockDocumentScannerOutput
        )
    }

    func testTransitionFromScanningCardFrontLegacyPicksBestFrameWithinBestFrameWindow() {
        let vc = DocumentCaptureViewController(
            apiConfig: DocumentCaptureViewControllerTest.mockVerificationPage.documentCapture,
            initialState: .scanning(.front, nil),
            sheetController: mockSheetController,
            cameraSession: mockCameraSession,
            cameraPermissionsManager: mockCameraPermissionsManager,
            documentUploader: mockDocumentUploader,
            anyDocumentScanner: .init(mockDocumentScanner),
            concurrencyManager: mockConcurrencyManager,
            appSettingsHelper: mockAppSettingsHelper,
            avaialableIDTypes: DocumentCaptureViewControllerTest.mockVerificationPage.documentSelect.idDocumentTypeAllowlistKeys,
            bestFramePicker: .init(window: 1.0)
        )

        func makeOutput(frontScore: Float) -> DocumentScannerOutput {
            return makeDocumentScannerOutputLegacyWithIddetectorOutput(
                .init(
                    classification: .idCardFront,
                    documentBounds: CGRect(x: 0.1, y: 0.33, width: 0.8, height: 0.33),
                    allClassificationScores: [
                        .idCardFront: frontScore
                    ]
                )
            )
        }

        let outputs = [
            makeOutput(frontScore: 0.3),
            makeOutput(frontScore: 0.6),
            makeOutput(frontScore: 0.4),
            makeOutput(frontScore: 0.9),
            makeOutput(frontScore: 0.5),
        ]
        let expectedBestOutput = outputs[3]

        for output in outputs {
            mockCameraFrameCaptured(vc)
            mockConcurrencyManager.respondToScan(output: output)
        }

        let windowExp = expectation(description: "Best frame window expired")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            windowExp.fulfill()
        }
        wait(for: [windowExp], timeout: 2)

        // Next frame triggers the pick + upload. Use a lower score so it doesn't replace the best.
        mockCameraFrameCaptured(vc)
        mockConcurrencyManager.respondToScan(output: makeOutput(frontScore: 0.1))

        verify(
            vc,
            expectedState: .scanned(.front, UIImage()),
            expectedButtonState: .enabled
        )
        waitForCameraSessionToStop()
        XCTAssertTrue(mockDocumentScanner.didReset)
        XCTAssertTrue(mockConcurrencyManager.didReset)
        XCTAssertEqual(mockDocumentUploader.uploadedSide, .front)
        XCTAssertEqual(mockDocumentUploader.uploadMethod, .autoCapture)
        XCTAssertEqual(mockDocumentUploader.uploadedDocumentScannerOutput, expectedBestOutput)
    }

    func testTransitionFromScannedCardFront() {
        let vc = makeViewController(
            state: .scanned(.front, UIImage())
        )
        vc.buttonViewModels.first!.didTap()
        // Verify state is scanning
        verify(
            vc,
            expectedState: .saving(.back, UIImage()),
            expectedButtonState: .loading
        )
        // Verify decide back
        XCTAssertTrue(mockSheetController.didSaveDocumentFrontAndDecideBack)
    }

    func testTransitionFromTimeoutCardFront() {
        let vc = makeViewController(state: .timeout(.front))
        vc.buttonViewModels.last!.didTap()
        // Verify camera session started
        waitForCameraSessionToStart()
        verify(
            vc,
            expectedState: .scanning(.front, nil),
            expectedButtonState: .disabled
        )
    }

    func testTransitionFromScanningCardBack() {
        let vc = makeViewController(
            state: .scanning(.back, nil)
        )
        let mockDocumentScannerOutput = makeDocumentScannerOutputLegacy(with: .idCardBack)
        // Mock timer so we can verify it was invalidated
        mockTimeoutTimer(vc)
        mockCameraFrameCaptured(vc)
        // Mock that scanner found desired classification
        mockConcurrencyManager.respondToScan(output: mockDocumentScannerOutput)
        verify(
            vc,
            expectedState: .scanned(.back, UIImage()),
            expectedButtonState: .enabled
        )
        // Verify timeout timer was invalidated
        XCTAssertEqual(vc.imageScanningSession.timeoutTimer?.isValid, false)
        waitForCameraSessionToStop()
        XCTAssertTrue(mockDocumentScanner.didReset)
        XCTAssertTrue(mockConcurrencyManager.didReset)
        // Verify image started uploading
        XCTAssertEqual(mockDocumentUploader.uploadedSide, .back)
        XCTAssertEqual(mockDocumentUploader.uploadMethod, .autoCapture)
        XCTAssertEqual(
            mockDocumentUploader.uploadedDocumentScannerOutput,
            mockDocumentScannerOutput
        )
    }

    func testTransitionFromScannedCardBack() {
        let vc = makeViewController(
            state: .scanned(.back, UIImage())
        )
        vc.buttonViewModels.first!.didTap()
        verify(
            vc,
            expectedState: .saving(.back, UIImage()),
            expectedButtonState: .loading
        )
        // Verify save back and transition
        XCTAssertTrue(mockSheetController.didSaveDocumentBackAndTransition)
    }

    func testTransitionFromTimeoutCardBack() {
        let vc = makeViewController(state: .timeout(.back))
        vc.buttonViewModels.last!.didTap()
        waitForCameraSessionToStart()
        verify(
            vc,
            expectedState: .scanning(.back, nil),
            expectedButtonState: .disabled
        )
    }

    func testTransitionFromInitialPassport() {
        let vc = makeViewController(state: .initial)
        vc.buttonViewModels.first!.didTap()
        // Mock that view appeared
        vc.viewWillAppear(false)
        // Verify camera access requested
        grantCameraAccess()
        // Verify camera configured
        waitForCameraSessionToConfigure(setupResult: .success)
        // Verify camera session started
        waitForCameraSessionToStart()
        // Verify state is scanning
        verify(
            vc,
            expectedState: .scanning(.front, nil),
            expectedButtonState: .disabled
        )
    }

    func testTransitionFromScanningPassport() {
        let vc = makeViewController(
            state: .scanning(.front, nil)
        )
        let mockDocumentScannerOutput = makeDocumentScannerOutputLegacy(with: .passport)
        // Mock timer so we can verify it was invalidated
        mockTimeoutTimer(vc)
        mockCameraFrameCaptured(vc)
        // Mock that scanner found desired classification
        mockConcurrencyManager.respondToScan(output: mockDocumentScannerOutput)
        verify(
            vc,
            expectedState: .scanned(.front, UIImage()),
            expectedButtonState: .enabled
        )
        // Verify timeout timer was invalidated
        XCTAssertEqual(vc.imageScanningSession.timeoutTimer?.isValid, false)
        waitForCameraSessionToStop()
        XCTAssertTrue(mockDocumentScanner.didReset)
        XCTAssertTrue(mockConcurrencyManager.didReset)
        // Verify image started uploading
        XCTAssertEqual(mockDocumentUploader.uploadedSide, .front)
        XCTAssertEqual(mockDocumentUploader.uploadMethod, .autoCapture)
        XCTAssertEqual(
            mockDocumentUploader.uploadedDocumentScannerOutput,
            mockDocumentScannerOutput
        )
    }

    func testTransitionFromScannedPassport() {
        let vc = makeViewController(
            state: .scanned(.front, UIImage())
        )
        vc.buttonViewModels.first!.didTap()
        verify(
            vc,
            expectedState: .saving(.front, UIImage()),
            expectedButtonState: .loading
        )
        // Verify decide back
        XCTAssertTrue(mockSheetController.didSaveDocumentFrontAndDecideBack)
    }

    func testTransitionFromTimeoutPassport() {
        let vc = makeViewController(state: .timeout(.front))
        vc.buttonViewModels.last!.didTap()
        waitForCameraSessionToStart()
        verify(
            vc,
            expectedState: .scanning(.front, nil),
            expectedButtonState: .disabled
        )
    }

    func testResetTimeoutDuringScanning() {
        // Mock that existing sacnningState already found a desired classification
        let vc = makeViewController(
            state: .scanning(
                .front,
                makeDocumentScannerOutputLegacyWithIddetectorOutput(
                    .init(classification: .passport, documentBounds: CGRect(), allClassificationScores: [.invalid: 0])
                )
            )
        )

        // Mock that scanner found non-desired classification
        mockCameraFrameCaptured(vc)
        mockConcurrencyManager.respondToScan(output: nil)

        // verify imageScanningSession.startTimeoutTimer is reset and a new valid timer is set
        XCTAssertEqual(vc.imageScanningSession.timeoutTimer?.isValid, true)
    }

    func testSaveDataFrontAndTransition() {
        let frontFileData = (VerificationPageDataUpdateMock.default.collectedData?.idDocumentFront)!

        let mockFrontImage = UIImage()

        // Mock that file has been captured and upload has begun
        let vc = makeViewController(documentType: .drivingLicense)

        mockDocumentUploader.frontUploadPromise.resolve(with: frontFileData)

        // Request to save data
        vc.saveOrFlipDocument(scannedImage: mockFrontImage, documentSide: .front)
        let e = expectation(description: "back upload result")
        mockDocumentUploader.frontUploadPromise.observe { _ in
            guard case .success = self.mockSheetController.frontUploadedDocumentsResult else {
                return XCTFail("Expected success result")
            }
            e.fulfill()
        }
        waitForExpectations(timeout: 1)

        // Verify state
        verify(
            vc,
            expectedState: .scanning(.back, nil),
            expectedButtonState: .disabled
        )
    }

    func testSaveDataBackAndTransition() {
        let backFileData = (VerificationPageDataUpdateMock.default.collectedData?.idDocumentBack)!

        let mockBackImage = UIImage()

        // Mock that file has been captured and upload has begun
        let vc = makeViewController(documentType: .drivingLicense)

        mockDocumentUploader.backUploadPromise.resolve(with: backFileData)

        // Request to save data
        vc.saveOrFlipDocument(scannedImage: mockBackImage, documentSide: .back)

        let e = expectation(description: "back upload result")
        mockDocumentUploader.backUploadPromise.observe { _ in
            guard case .success = self.mockSheetController.backUploadedDocumentsResult else {
                return XCTFail("Expected success result")
            }
            e.fulfill()
        }
        waitForExpectations(timeout: 1)

        // Verify state
        verify(
            vc,
            expectedState: .scanned(.back, mockBackImage),
            expectedButtonState: .enabled
        )
    }

    func testRequestCameraAccessDenied() {
        // Mock collected data for analytics
        mockSheetController.collectedData = VerificationPageDataUpdateMock.default.collectedData!

        let vc = makeViewController(state: .initial)
        // Mock that view appeared
        vc.viewWillAppear(false)
        // Deny access
        grantCameraAccess(granted: false)
        // Verify no camera access state
        verify(
            vc,
            expectedState: .noCameraAccess,
            expectedButtonState: .enabled
        )
        let analytic = mockAnalyticsClient.loggedAnalyticPayloads(
            withEventName: "camera_permission_denied"
        ).first
        XCTAssert(analytic: analytic, hasMetadata: "screen_name", withValue: "live_capture")
        XCTAssert(
            analytic: analytic,
            hasMetadata: "camera_source",
            withValue: "camera_session"
        )
        XCTAssert(analytic: analytic, hasMetadata: "camera_event_kind", withValue: "permission")
        XCTAssert(analytic: analytic, hasMetadata: "camera_access_state", withValue: "denied")
        XCTAssertEqual(
            mockAnalyticsClient.loggedAnalyticPayloads(withEventName: "camera_permission_granted")
                .count,
            0
        )

        let errorAnalytic = mockAnalyticsClient.loggedAnalyticPayloads(withEventName: "camera_error")
            .first
        XCTAssert(analytic: errorAnalytic, hasMetadata: "screen_name", withValue: "live_capture")
        XCTAssert(
            analytic: errorAnalytic,
            hasMetadata: "camera_source",
            withValue: "camera_session"
        )
        XCTAssert(analytic: errorAnalytic, hasMetadata: "camera_event_kind", withValue: "permission")
        XCTAssert(analytic: errorAnalytic, hasMetadata: "camera_access_state", withValue: "denied")
        let error = (errorAnalytic?["event_metadata"] as? [String: Any])?["error"] as? [String: Any]
        XCTAssertEqual(error?["type"] as? String, "cameraPermissionDenied")
        XCTAssertEqual(error?["file"] as? String, "DocumentCaptureViewController.swift")
    }

    func testCameraSessionFailedConfigure() {
        // Mock collected data for analytics
        mockSheetController.collectedData = VerificationPageDataUpdateMock.default.collectedData!

        let vc = makeViewController(state: .initial)
        // Mock that view appeared
        vc.viewWillAppear(false)

        grantCameraAccess()

        // Mock that the camera session failed to get configured
        waitForCameraSessionToConfigure(setupResult: .failed(error: mockError))

        verify(
            vc,
            expectedState: .cameraError,
            expectedButtonState: .enabled
        )

        // Verify analytics
        let analytic = mockAnalyticsClient.loggedAnalyticPayloads(withEventName: "camera_error")
            .first
        XCTAssert(
            analytic: analytic,
            hasMetadataError: "error",
            withDomain: "mock_error",
            code: 100,
            fileName: "DocumentCaptureViewController.swift"
        )
        XCTAssert(analytic: analytic, hasMetadata: "screen_name", withValue: "live_capture")
        XCTAssert(
            analytic: analytic,
            hasMetadata: "camera_source",
            withValue: "camera_session"
        )
        XCTAssert(analytic: analytic, hasMetadata: "camera_event_kind", withValue: "runtime_error")
    }

    func testCameraAccessGrantedLogsExistingAnalytic() {
        // Mock collected data for analytics
        mockSheetController.collectedData = VerificationPageDataUpdateMock.default.collectedData!

        let vc = makeViewController(state: .initial)
        // Mock that view appeared
        vc.viewWillAppear(false)
        // Grant access
        grantCameraAccess(granted: true)

        // Verify analytics
        XCTAssertEqual(
            mockAnalyticsClient.loggedAnalyticPayloads(withEventName: "camera_permission_granted")
                .count,
            1
        )
        XCTAssertEqual(
            mockAnalyticsClient.loggedAnalyticPayloads(withEventName: "camera_permission_denied")
                .count,
            0
        )
        XCTAssertEqual(
            mockAnalyticsClient.loggedAnalyticPayloads(withEventName: "camera_error").count,
            0
        )
    }

    func testSettingsButton() {
        let vc = makeViewController(state: .noCameraAccess)
        vc.buttonViewModels.last!.didTap()
        // Should open settings
        XCTAssertTrue(mockAppSettingsHelper.didOpenAppSettings)
        // No state change is expected
        verify(
            vc,
            expectedState: .noCameraAccess,
            expectedButtonState: .enabled
        )
    }

    func testCaptureModeControlShownWhenManualCaptureIsAllowed() throws {
        let vc = makeViewController(state: .initial)
        XCTAssertNil(vc.navigationItem.titleView)
        let control = try XCTUnwrap(findCaptureModeControl(in: vc.documentCaptureView))
        XCTAssertEqual(control.selectedSegmentIndex, 0)
        XCTAssertTrue(control.isEnabled)
    }

    func testCaptureModeControlShownWhenLiveCaptureIsRequired() throws {
        let mockResponse = try VerificationPageMock.requireLiveCapture.make()
        let vc = makeViewController(
            state: .initial,
            apiConfig: mockResponse.documentCapture
        )
        let control = try XCTUnwrap(findCaptureModeControl(in: vc.documentCaptureView))
        XCTAssertEqual(control.selectedSegmentIndex, 0)
        XCTAssertTrue(control.isEnabled)

        XCTAssertNil(vc.navigationItem.titleView)
    }

    func testCaptureModeControlDisabledWhenScanned() throws {
        let vc = makeViewController(state: .scanned(.front, UIImage()))
        let control = try XCTUnwrap(findCaptureModeControl(in: vc.documentCaptureView))
        XCTAssertFalse(control.isEnabled)
    }

    func testCaptureModeControlHiddenWhenTimedOut() throws {
        let vc = makeViewController(state: .timeout(.front))

        XCTAssertNil(findCaptureModeControl(in: vc.documentCaptureView))
    }

    func testManualCaptureSwitchUpdatesModeWithoutTransitioning() throws {
        let vc = makeViewController(state: .scanning(.front, nil))
        let control = try switchToManualCapture(vc)

        XCTAssertEqual(control.selectedSegmentIndex, 1)
        XCTAssertNil(mockFlowController.replacedWithViewController)
        XCTAssertEqual(vc.buttonViewModels.count, 1)
        XCTAssertEqual(vc.buttonViewModels.first?.text, "Take Photo")
        XCTAssertEqual(vc.buttonViewModels.first?.state, .disabled)
    }

    func testManualCaptureRequiresExplicitTakePhoto() throws {
        let vc = makeViewController(state: .scanning(.front, nil))
        let mockDocumentScannerOutput = makeDocumentScannerOutputLegacy(with: .idCardFront)

        _ = try switchToManualCapture(vc)

        mockCameraFrameCaptured(vc)
        mockConcurrencyManager.respondToScan(output: mockDocumentScannerOutput)

        XCTAssertStateEqual(
            vc.imageScanningSession.state,
            .scanning(.front, nil)
        )
        XCTAssertNil(mockDocumentUploader.uploadedSide)
        XCTAssertEqual(vc.buttonViewModels.first?.state, .enabled)
        guard case .scan(let viewModel) = vc.viewModel else {
            return XCTFail("Expected scan view model")
        }
        guard case .videoPreview(_, let animateBorder) = viewModel.scanningViewModel else {
            return XCTFail("Expected video preview while scanning")
        }
        XCTAssertFalse(animateBorder)
        XCTAssertEqual(
            viewModel.instructionalText,
            vc.scanningTextWithNoInput(
                availableIDTypes: DocumentCaptureViewControllerTest.mockVerificationPage
                    .documentSelect.idDocumentTypeAllowlistKeys,
                for: .front
            )
        )

        vc.buttonViewModels.first?.didTap()

        XCTAssertStateEqual(
            vc.imageScanningSession.state,
            .scanned(.front, UIImage())
        )
        XCTAssertEqual(mockDocumentUploader.uploadedSide, .front)
        XCTAssertEqual(mockDocumentUploader.uploadMethod, .manualCapture)
        XCTAssertEqual(
            mockDocumentUploader.uploadedDocumentScannerOutput,
            mockDocumentScannerOutput
        )
        guard case .scan(let scannedViewModel) = vc.viewModel else {
            return XCTFail("Expected scan view model after manual capture")
        }
        XCTAssertEqual(
            scannedViewModel.instructionalText,
            DocumentCaptureViewController.imageTakenInstructionalText
        )
        XCTAssertEqual(vc.buttonViewModels.count, 1)
        XCTAssertEqual(vc.buttonViewModels.first?.text, "Continue")
    }

    func testManualCaptureCanBeActivatedWhenLiveCaptureIsRequired() throws {
        let mockResponse = try VerificationPageMock.requireLiveCapture.make()
        let vc = makeViewController(
            state: .scanning(.front, nil),
            apiConfig: mockResponse.documentCapture
        )
        let mockDocumentScannerOutput = makeDocumentScannerOutputLegacy(with: .idCardFront)

        let control = try switchToManualCapture(vc)

        XCTAssertEqual(control.selectedSegmentIndex, 1)
        XCTAssertEqual(vc.buttonViewModels.count, 1)
        XCTAssertEqual(vc.buttonViewModels.first?.text, "Take Photo")
        XCTAssertEqual(vc.buttonViewModels.first?.state, .disabled)

        mockCameraFrameCaptured(vc)
        mockConcurrencyManager.respondToScan(output: mockDocumentScannerOutput)

        XCTAssertStateEqual(
            vc.imageScanningSession.state,
            .scanning(.front, nil)
        )
        XCTAssertNil(mockDocumentUploader.uploadedSide)
        XCTAssertEqual(vc.buttonViewModels.first?.state, .enabled)

        vc.buttonViewModels.first?.didTap()

        XCTAssertStateEqual(
            vc.imageScanningSession.state,
            .scanned(.front, UIImage())
        )
        XCTAssertEqual(mockDocumentUploader.uploadedSide, .front)
        XCTAssertEqual(mockDocumentUploader.uploadMethod, .manualCapture)
        XCTAssertEqual(
            mockDocumentUploader.uploadedDocumentScannerOutput,
            mockDocumentScannerOutput
        )
        guard case .scan(let scannedViewModel) = vc.viewModel else {
            return XCTFail("Expected scan view model after manual capture")
        }
        XCTAssertEqual(
            scannedViewModel.instructionalText,
            DocumentCaptureViewController.imageTakenInstructionalText
        )
    }

    func testFileUploadButtonCameraAccess() {
        let vc = makeViewController(state: .noCameraAccess)
        vc.buttonViewModels.first!.didTap()
        // Should open File Upload screen
        XCTAssertIs(
            mockFlowController.replacedWithViewController as Any,
            DocumentFileUploadViewController.self
        )
    }

    func testFileUploadButtonTimeout() {
        let vc = makeViewController(state: .timeout(.front))
        vc.buttonViewModels.first!.didTap()
        // Should open File Upload screen
        XCTAssertIs(
            mockFlowController.replacedWithViewController as Any,
            DocumentFileUploadViewController.self
        )
    }

    func testTimeoutButtonsWhenLiveCaptureIsRequired() throws {
        let mockResponse = try VerificationPageMock.requireLiveCapture.make()
        let vc = makeViewController(
            state: .timeout(.front),
            apiConfig: mockResponse.documentCapture
        )

        XCTAssertEqual(vc.buttonViewModels.count, 1)
        XCTAssertEqual(vc.buttonViewModels.first?.text, "Try Again")
        XCTAssertEqual(vc.buttonViewModels.first?.state, .enabled)

        vc.buttonViewModels.first?.didTap()

        waitForCameraSessionToStart()
        XCTAssertStateEqual(
            vc.imageScanningSession.state,
            .scanning(.front, nil)
        )
        XCTAssertEqual(vc.buttonViewModels.first?.state, .disabled)
    }

    func testNoCameraAccessButtonsReqLiveCapture() throws {
        // If requireLiveCapture is enabled, upload action should not display
        // without camera access
        let mockResponse = try VerificationPageMock.requireLiveCapture.make()
        let vc = makeViewController(
            state: .noCameraAccess,
            apiConfig: mockResponse.documentCapture
        )
        XCTAssertEqual(vc.buttonViewModels.count, 1)
    }

    func testNoCameraAccessButtonsNoReqLiveCapture() throws {
        // If requireLiveCapture is disabled, upload action **should** display
        // without camera access
        let mockResponse = try VerificationPageMock.response200.make()
        let vc = makeViewController(
            state: .noCameraAccess,
            apiConfig: mockResponse.documentCapture
        )
        XCTAssertEqual(vc.buttonViewModels.count, 2)
    }

    func testScanningTimeout() {
        // Mock collected data for analytics
        mockSheetController.collectedData = VerificationPageDataUpdateMock.default.collectedData!

        let vc = makeViewController(
            state: .scanning(.front, nil)
        )
        let startedScanningDate = Date()
        // Mock that scanner is scanning
        vc.imageScanningSession.startScanning(expectedClassification: .front)
        waitForCameraSessionToStart()

        guard let timer = vc.imageScanningSession.timeoutTimer else {
            return XCTFail("Expected timeout timer to be set")
        }

        // `autocapture_timeout` in mock API response is 1000ms.
        // We want to test that the timer will fire 10s after `startScanning()` is
        // called. Since `Timer.timeInterval` is always 0 for non-repeating timers,
        // we'll check the delta between the timer's firing date and when
        // `startScanning` was called. Using an accuracy of 0.2s to account for
        // processing time of calling `startScanning`.
        XCTAssertEqual(timer.fireDate.timeIntervalSince(startedScanningDate), 10, accuracy: 0.2)

        // Simulate time out
        timer.fire()

        verify(
            vc,
            expectedState: .timeout(.front),
            expectedButtonState: .enabled
        )
        XCTAssertEqual(vc.imageScanningSession.timeoutTimer?.isValid, false)
        waitForCameraSessionToStop()
        XCTAssertTrue(mockDocumentScanner.didReset)
        XCTAssertTrue(mockConcurrencyManager.didReset)

        // Verify analytic logged
        let analytic = mockAnalyticsClient.loggedAnalyticPayloads(withEventName: "document_timeout")
            .first
        XCTAssert(analytic: analytic, hasMetadata: "side", withValue: "front")
    }

    func testScanningTimeoutUploadsBestMatchingFrame() throws {
        // Given several matching frames that do not pass the quality checks
        let vc = makeViewController(state: .scanning(.front, nil))
        let bestImage = try XCTUnwrap(CapturedImageMock.frontDriversLicense.image.cgImage)
        let otherImage = try XCTUnwrap(CapturedImageMock.backDriversLicense.image.cgImage)
        let bestExif = CameraExifMetadata(brightnessValue: 2, focalLength: 4, lensModel: "best frame")
        let scores: [Float] = [0.4, 0.9, 0.6]
        var bestOutput: DocumentScannerOutput?
        for score in scores {
            let output = makeDocumentScannerOutputLegacyWithIddetectorOutput(
                .init(
                    classification: .idCardFront,
                    documentBounds: CGRect(x: 0.1, y: 0.33, width: 0.8, height: 0.33),
                    allClassificationScores: [.idCardFront: score]
                ),
                isBlurry: true
            )
            XCTAssertFalse(output.isHighQuality(side: .front))
            if score == 0.9 {
                bestOutput = output
            }
            vc.imageScanningSessionDidScanImage(
                vc.imageScanningSession,
                image: score == 0.9 ? bestImage : otherImage,
                scannerOutput: output,
                exifMetadata: score == 0.9 ? bestExif : nil,
                expectedClassification: .front
            )
        }
        XCTAssertEqual(mockDocumentUploader.uploadCount, 0)
        mockTimeoutTimer(vc)
        // ...and another frame is still being processed when the timer fires
        mockCameraFrameCaptured(vc)

        // When scanning times out
        try XCTUnwrap(vc.imageScanningSession.timeoutTimer).fire()

        // Then the highest-scoring frame and its metadata are uploaded together
        verify(vc, expectedState: .scanned(.front, UIImage()), expectedButtonState: .enabled)
        XCTAssertTrue(mockDocumentUploader.uploadedImage === bestImage)
        XCTAssertEqual(mockDocumentUploader.uploadedDocumentScannerOutput, bestOutput)
        XCTAssertEqual(mockDocumentUploader.uploadedExifMetadata, bestExif)
        XCTAssertEqual(mockDocumentUploader.uploadedSide, .front)
        XCTAssertEqual(mockDocumentUploader.uploadMethod, .autoCapture)
        XCTAssertEqual(mockSheetController.analyticsClient.blurScoreFront, 0.1)
        XCTAssertEqual(vc.imageScanningSession.timeoutTimer?.isValid, false)
        guard case .scanned(_, let capturedImage) = vc.imageScanningSession.state else {
            return XCTFail("Expected scanned image")
        }
        XCTAssertTrue(capturedImage.cgImage === bestImage)
        let analytic = mockAnalyticsClient.loggedAnalyticPayloads(withEventName: "document_timeout").first
        XCTAssert(analytic: analytic, hasMetadata: "side", withValue: "front")

        // ...and the late scanner result cannot upload or replace the image again
        mockConcurrencyManager.respondToScan(output: makeDocumentScannerOutputLegacy(with: .idCardFront))
        XCTAssertEqual(mockDocumentUploader.uploadCount, 1)
        XCTAssertTrue(mockDocumentUploader.uploadedImage === bestImage)
        waitForCameraSessionToStop()
        XCTAssertTrue(mockDocumentScanner.didReset)
        XCTAssertTrue(mockConcurrencyManager.didReset)
    }

    func testScanningTimeoutUploadsMatchingBackFrame() throws {
        // Given a back frame that does not pass the quality checks
        let vc = makeViewController(state: .scanning(.back, nil))
        let output = makeDocumentScannerOutputLegacy(with: .idCardBack, isBlurry: false)
        XCTAssertFalse(output.isHighQuality(side: .back))
        mockCameraFrameCaptured(vc)
        mockConcurrencyManager.respondToScan(output: output)
        vc.imageScanningSession.startTimeoutTimer(expectedClassification: .back)

        // When scanning the back times out
        try XCTUnwrap(vc.imageScanningSession.timeoutTimer).fire()

        // Then the cached frame is submitted for the back
        verify(vc, expectedState: .scanned(.back, UIImage()), expectedButtonState: .enabled)
        XCTAssertEqual(mockDocumentUploader.uploadedSide, .back)
        XCTAssertEqual(mockDocumentUploader.uploadedDocumentScannerOutput, output)
        XCTAssertEqual(mockDocumentUploader.uploadMethod, .autoCapture)
    }

    func testScanningTimeoutWithoutMatchingFrameDoesNotUpload() throws {
        // Given frames with no detection or the wrong document side
        let vc = makeViewController(state: .scanning(.front, nil))
        mockCameraFrameCaptured(vc)
        mockConcurrencyManager.respondToScan(output: nil)
        mockConcurrencyManager.respondToScan(output: makeDocumentScannerOutputLegacy(with: .invalid))
        mockConcurrencyManager.respondToScan(output: makeDocumentScannerOutputLegacy(with: .idCardBack))
        mockTimeoutTimer(vc)

        // When scanning times out
        try XCTUnwrap(vc.imageScanningSession.timeoutTimer).fire()

        // Then the existing timeout screen is shown without an upload
        verify(vc, expectedState: .timeout(.front), expectedButtonState: .enabled)
        XCTAssertEqual(mockDocumentUploader.uploadCount, 0)
    }

    func testScanningTimeoutKeepsMatchingFrameAfterDetectionIsLost() throws {
        // Given a matching frame followed by the wrong side and then no detection
        let vc = makeViewController(state: .scanning(.front, nil))
        let output = makeDocumentScannerOutputLegacy(with: .idCardFront, isBlurry: false)
        mockCameraFrameCaptured(vc)
        mockConcurrencyManager.respondToScan(output: output)
        mockConcurrencyManager.respondToScan(output: makeDocumentScannerOutputLegacy(with: .idCardBack))
        mockConcurrencyManager.respondToScan(output: nil)
        mockTimeoutTimer(vc)

        // When the scan times out after losing the document
        try XCTUnwrap(vc.imageScanningSession.timeoutTimer).fire()

        // Then the earlier matching frame is still available for submission
        verify(vc, expectedState: .scanned(.front, UIImage()), expectedButtonState: .enabled)
        XCTAssertEqual(mockDocumentUploader.uploadedDocumentScannerOutput, output)
        XCTAssertEqual(mockDocumentUploader.uploadedSide, .front)
        XCTAssertEqual(mockDocumentUploader.uploadCount, 1)
    }

    func testTimeoutForPreviousSideDoesNotInterruptCurrentScan() throws {
        // Given a cached back frame and a timeout callback for the previous side
        let vc = makeViewController(state: .scanning(.back, nil))
        let output = makeDocumentScannerOutputLegacy(with: .idCardBack, isBlurry: false)
        mockCameraFrameCaptured(vc)
        mockConcurrencyManager.respondToScan(output: output)
        vc.imageScanningSession.startTimeoutTimer(expectedClassification: .front)

        // When the old side's timeout fires
        try XCTUnwrap(vc.imageScanningSession.timeoutTimer).fire()

        // Then the current scan continues without uploading or reporting a timeout
        XCTAssertStateEqual(vc.imageScanningSession.state, .scanning(.back, output))
        XCTAssertEqual(mockDocumentUploader.uploadCount, 0)
        XCTAssertTrue(mockAnalyticsClient.loggedAnalyticPayloads(withEventName: "document_timeout").isEmpty)

        // ...and the current side can still submit its cached frame on timeout
        vc.imageScanningSession.startTimeoutTimer(expectedClassification: .back)
        try XCTUnwrap(vc.imageScanningSession.timeoutTimer).fire()
        verify(vc, expectedState: .scanned(.back, UIImage()), expectedButtonState: .enabled)
        XCTAssertEqual(mockDocumentUploader.uploadedDocumentScannerOutput, output)
        XCTAssertEqual(mockDocumentUploader.uploadedSide, .back)
        XCTAssertEqual(mockDocumentUploader.uploadCount, 1)
    }

    func testScanningTimeoutUploadsFrameWhileBestFrameWindowIsPending() throws {
        // Given an approved frame between higher-scoring blurry frames while the selection window is open
        let vc = makeViewController(state: .scanning(.front, nil), bestFrameWindow: 60)
        let output = makeDocumentScannerOutputLegacyWithIddetectorOutput(
            .init(
                classification: .idCardFront,
                documentBounds: CGRect(x: 0.1, y: 0.33, width: 0.8, height: 0.33),
                allClassificationScores: [.idCardFront: 0.4]
            )
        )
        let blurryOutput = makeDocumentScannerOutputLegacyWithIddetectorOutput(
            .init(
                classification: .idCardFront,
                documentBounds: CGRect(x: 0.1, y: 0.33, width: 0.8, height: 0.33),
                allClassificationScores: [.idCardFront: 0.9]
            ),
            isBlurry: true
        )
        XCTAssertTrue(output.isHighQuality(side: .front))
        XCTAssertFalse(blurryOutput.isHighQuality(side: .front))
        XCTAssertGreaterThan(blurryOutput.qualityScore(side: .front), output.qualityScore(side: .front))
        for frame in [blurryOutput, output, blurryOutput] {
            mockCameraFrameCaptured(vc)
            mockConcurrencyManager.respondToScan(output: frame)
        }
        XCTAssertEqual(mockDocumentUploader.uploadCount, 0)
        mockTimeoutTimer(vc)

        // When scanning times out before another frame completes the window
        try XCTUnwrap(vc.imageScanningSession.timeoutTimer).fire()

        // Then the approved frame is submitted despite its lower score
        verify(vc, expectedState: .scanned(.front, UIImage()), expectedButtonState: .enabled)
        XCTAssertEqual(mockDocumentUploader.uploadedDocumentScannerOutput, output)
        XCTAssertEqual(mockDocumentUploader.uploadCount, 1)
    }

    func testLateTimeoutDoesNotReplaceCapturedFrame() throws {
        // Given capture finishes before the camera start completion arrives
        let vc = makeViewController(state: .scanning(.front, nil))
        vc.imageScanningSession.startScanning(expectedClassification: .front)
        mockCameraFrameCaptured(vc)
        mockConcurrencyManager.respondToScan(output: makeDocumentScannerOutputLegacy(with: .idCardFront))
        verify(vc, expectedState: .scanned(.front, UIImage()), expectedButtonState: .enabled)
        let capturedState = vc.imageScanningSession.state

        // When the delayed start completion creates a timer and it fires
        waitForCameraSessionToStart()
        let timer = try XCTUnwrap(vc.imageScanningSession.timeoutTimer)
        XCTAssertTrue(timer.isValid)
        timer.fire()

        // Then the captured frame is preserved without another upload or timeout event
        XCTAssertEqual(vc.imageScanningSession.state, capturedState)
        XCTAssertEqual(mockDocumentUploader.uploadCount, 1)
        XCTAssertTrue(mockAnalyticsClient.loggedAnalyticPayloads(withEventName: "document_timeout").isEmpty)
        waitForCameraSessionToStop()
    }

    func testLateTimeoutDoesNotInterruptSaving() throws {
        // Given capture has reached saving before the camera start completion arrives
        let vc = makeViewController(state: .scanning(.front, nil))
        vc.imageScanningSession.startScanning(expectedClassification: .front)
        mockCameraFrameCaptured(vc)
        mockConcurrencyManager.respondToScan(output: makeDocumentScannerOutputLegacy(with: .idCardFront))
        let capturedImage = UIImage(cgImage: try XCTUnwrap(mockDocumentUploader.uploadedImage))
        vc.imageScanningSession.setStateSaving(expectedClassification: .front, capturedData: capturedImage)

        // When the delayed start completion creates a timer and it fires
        waitForCameraSessionToStart()
        let timer = try XCTUnwrap(vc.imageScanningSession.timeoutTimer)
        XCTAssertTrue(timer.isValid)
        timer.fire()

        // Then saving continues without another upload or timeout event
        XCTAssertEqual(vc.imageScanningSession.state, .saving(.front, capturedImage))
        XCTAssertEqual(mockDocumentUploader.uploadCount, 1)
        XCTAssertTrue(mockAnalyticsClient.loggedAnalyticPayloads(withEventName: "document_timeout").isEmpty)
        waitForCameraSessionToStop()
    }

    func testResetClearsTimeoutFallback() throws {
        // Given a cached frame from the previous scan attempt
        let vc = makeViewController(state: .scanning(.front, nil))
        mockCameraFrameCaptured(vc)
        mockConcurrencyManager.respondToScan(output: makeDocumentScannerOutputLegacy(with: .idCardFront, isBlurry: false))

        // When the scan resets and the next attempt times out without a frame
        vc.reset()
        mockTimeoutTimer(vc)
        try XCTUnwrap(vc.imageScanningSession.timeoutTimer).fire()

        // Then the old frame is not submitted
        verify(vc, expectedState: .timeout(.front), expectedButtonState: .enabled)
        XCTAssertEqual(mockDocumentUploader.uploadCount, 0)
    }

    func testStartingNewSideClearsTimeoutFallback() throws {
        // Given a cached front frame
        let vc = makeViewController(state: .scanning(.front, nil))
        mockCameraFrameCaptured(vc)
        mockConcurrencyManager.respondToScan(output: makeDocumentScannerOutputLegacy(with: .idCardFront, isBlurry: false))

        // When scanning the back starts and times out without a frame
        vc.imageScanningSession.startScanning(expectedClassification: .back)
        vc.imageScanningSession.startTimeoutTimer(expectedClassification: .back)
        try XCTUnwrap(vc.imageScanningSession.timeoutTimer).fire()

        // Then the front frame is not submitted as the back
        verify(vc, expectedState: .timeout(.back), expectedButtonState: .enabled)
        XCTAssertEqual(mockDocumentUploader.uploadCount, 0)
    }

    func testChangingCaptureModeClearsTimeoutFallback() throws {
        // Given a cached frame from live capture
        let vc = makeViewController(state: .scanning(.front, nil))
        mockCameraFrameCaptured(vc)
        mockConcurrencyManager.respondToScan(output: makeDocumentScannerOutputLegacy(with: .idCardFront, isBlurry: false))

        // When the user switches to manual capture, returns to live capture, and times out
        let control = try switchToManualCapture(vc)
        control.selectedSegmentIndex = 0
        vc.didChangeCaptureMode(control)
        try XCTUnwrap(vc.imageScanningSession.timeoutTimer).fire()

        // Then a frame from before the mode change is not submitted
        verify(vc, expectedState: .timeout(.front), expectedButtonState: .enabled)
        XCTAssertEqual(mockDocumentUploader.uploadCount, 0)
    }

    func testBackgroundingDoesNotSubmitTimeoutFallback() {
        // Given a cached frame from live capture
        let vc = makeViewController(state: .scanning(.front, nil))
        mockCameraFrameCaptured(vc)
        let output = makeDocumentScannerOutputLegacy(with: .idCardFront, isBlurry: false)
        mockConcurrencyManager.respondToScan(output: output)
        mockTimeoutTimer(vc)

        // When the app enters the background
        vc.imageScanningSession.appDidEnterBackground()

        // Then stopping the camera does not submit a fallback
        XCTAssertStateEqual(vc.imageScanningSession.state, .scanning(.front, output))
        XCTAssertEqual(mockDocumentUploader.uploadCount, 0)
        XCTAssertEqual(vc.imageScanningSession.timeoutTimer?.isValid, false)
    }

    func testForegroundingClearsTimeoutFallback() throws {
        // Given a matching frame was cached before the app entered the background
        let vc = makeViewController(state: .scanning(.front, nil))
        mockCameraFrameCaptured(vc)
        mockConcurrencyManager.respondToScan(output: makeDocumentScannerOutputLegacy(with: .idCardFront, isBlurry: false))
        mockTimeoutTimer(vc)
        vc.imageScanningSession.appDidEnterBackground()
        waitForCameraSessionToStop()

        // When the app resumes and the new scan times out without receiving a frame
        vc.imageScanningSession.appDidEnterForeground()
        waitForCameraSessionToStart()
        try XCTUnwrap(vc.imageScanningSession.timeoutTimer).fire()

        // Then the old frame is not submitted
        verify(vc, expectedState: .timeout(.front), expectedButtonState: .enabled)
        XCTAssertEqual(mockDocumentUploader.uploadCount, 0)
        XCTAssertEqual(mockAnalyticsClient.loggedAnalyticPayloads(withEventName: "document_timeout").count, 1)
    }

    func testScanAttemptsFront() {
        let vc = makeViewController(
            state: .scanning(.front, nil)
        )
        // Mock that scanner is scanning
        vc.imageScanningSession.startScanning(expectedClassification: .front)
        XCTAssertEqual(mockSheetController.analyticsClient.numDocumentFrontScanAttempts, 1)
        XCTAssertEqual(mockSheetController.analyticsClient.numDocumentBackScanAttempts, 0)

        // Mock that scanner starts again
        vc.imageScanningSession.startScanning(expectedClassification: .front)
        XCTAssertEqual(mockSheetController.analyticsClient.numDocumentFrontScanAttempts, 2)
        XCTAssertEqual(mockSheetController.analyticsClient.numDocumentBackScanAttempts, 0)

        // Mock that scanner scans back
        vc.imageScanningSession.startScanning(expectedClassification: .back)
        XCTAssertEqual(mockSheetController.analyticsClient.numDocumentFrontScanAttempts, 2)
        XCTAssertEqual(mockSheetController.analyticsClient.numDocumentBackScanAttempts, 1)

        // Mock that scanner scans back again
        vc.imageScanningSession.startScanning(expectedClassification: .back)
        XCTAssertEqual(mockSheetController.analyticsClient.numDocumentFrontScanAttempts, 2)
        XCTAssertEqual(mockSheetController.analyticsClient.numDocumentBackScanAttempts, 2)
    }

    func testScanningUpdatesStateLegacy() {
        let vc = makeViewController(
            state: .scanning(.front, nil)
        )
        // Mock that scanner is scanning
        vc.imageScanningSession.startScanning(expectedClassification: .front)
        waitForCameraSessionToStart()
        mockCameraFrameCaptured(vc)

        // Mock that scanner found a classification that was not desired and
        // verify the state is updated accordingly
        mockConcurrencyManager.respondToScan(output: makeDocumentScannerOutputLegacy(with: .invalid))

        XCTAssertStateEqual(vc.imageScanningSession.state, .scanning(.front, makeDocumentScannerOutputLegacyWithIddetectorOutput(.init(classification: .invalid, documentBounds: CGRect(), allClassificationScores: [.invalid: 0]))))

        mockConcurrencyManager.respondToScan(output: makeDocumentScannerOutputLegacy(with: .idCardBack))
        XCTAssertStateEqual(vc.imageScanningSession.state, .scanning(.front, makeDocumentScannerOutputLegacyWithIddetectorOutput(.init(classification: .idCardBack, documentBounds: CGRect(), allClassificationScores: [.invalid: 0]))))

        mockConcurrencyManager.respondToScan(output: nil)
        XCTAssertStateEqual(vc.imageScanningSession.state, .scanning(.front, nil))

        // Mock that scanner found desired classification, but is blurry
        mockConcurrencyManager.respondToScan(
            output: makeDocumentScannerOutputLegacy(with: .idCardFront, isBlurry: false)
        )
        XCTAssertStateEqual(vc.imageScanningSession.state, .scanning(.front, makeDocumentScannerOutputLegacyWithIddetectorOutput(.init(classification: .idCardFront, documentBounds: CGRect(), allClassificationScores: [.invalid: 0]))))

        // Mock that scanner found desired classification
        mockConcurrencyManager.respondToScan(output: makeDocumentScannerOutputLegacy(with: .idCardFront))
        XCTAssertStateEqual(vc.imageScanningSession.state, .scanned(.front, UIImage()))
    }

    func testScanningWithBarcode() {
        let vc = makeViewController(
            state: .scanning(.front, nil)
        )
        // Mock that scanner is scanning
        vc.imageScanningSession.startScanning(expectedClassification: .front)
        waitForCameraSessionToStart()
        mockCameraFrameCaptured(vc)

        // Mock that scanner found a classification that was not desired and
        // verify the state is updated accordingly
        mockConcurrencyManager.respondToScan(output: makeDocumentScannerOutputLegacy(with: .invalid))

        XCTAssertStateEqual(vc.imageScanningSession.state, .scanning(.front, makeDocumentScannerOutputLegacyWithIddetectorOutput(.init(classification: .invalid, documentBounds: CGRect(), allClassificationScores: [.invalid: 0]))))

        mockConcurrencyManager.respondToScan(output: makeDocumentScannerOutputLegacy(with: .idCardBack))
        XCTAssertStateEqual(vc.imageScanningSession.state, .scanning(.front, makeDocumentScannerOutputLegacyWithIddetectorOutput(.init(classification: .idCardBack, documentBounds: CGRect(), allClassificationScores: [.invalid: 0]))))

        mockConcurrencyManager.respondToScan(output: nil)
        XCTAssertStateEqual(vc.imageScanningSession.state, .scanning(.front, nil))

        // Mock that scanner found desired classification, and has barcode
        mockConcurrencyManager.respondToScan(
            output: makeDocumentScannerOutputLegacy(with: .idCardFront, hasBarcode: true)
        )
        // Mock that scanner found desired classification
        mockConcurrencyManager.respondToScan(output: makeDocumentScannerOutputLegacy(with: .idCardFront))
        XCTAssertStateEqual(vc.imageScanningSession.state, .scanned(.front, UIImage()))
    }

    func testAppBackgrounded() {
        // Mock that vc is scanning
        let vc = makeViewController(
            state: .scanning(.front, nil)
        )
        vc.imageScanningSession.startScanning(expectedClassification: .front)
        waitForCameraSessionToStart()

        // Mock that app is backgrounded
        vc.imageScanningSession.appDidEnterBackground()

        XCTAssertEqual(vc.imageScanningSession.timeoutTimer?.isValid, false)
        waitForCameraSessionToStop()
        XCTAssertTrue(mockDocumentScanner.didReset)
        XCTAssertTrue(mockConcurrencyManager.didReset)
    }

    func testAppForegrounded() {
        // Mock that vc is in background
        let vc = makeViewController(
            state: .scanning(.front, nil)
        )
        vc.imageScanningSession.appDidEnterBackground()

        // Mock that app is foregrounded
        vc.imageScanningSession.appDidEnterForeground()

        waitForCameraSessionToStart()
        XCTAssertEqual(vc.imageScanningSession.timeoutTimer?.isValid, true)
    }

    func testResetFromScanned() {
        // Mock that vc is done scanning
        let vc = makeViewController(
            state: .scanned(.back, UIImage())
        )

        // Reset
        vc.reset()

        // Verify VC starts scanning
        XCTAssertStateEqual(vc.imageScanningSession.state, .scanning(.front, nil))
        XCTAssertTrue(mockDocumentUploader.didReset)
    }

    func testResetFromScanning() {
        // Mock that vc is scanning
        let vc = makeViewController(
            state: .scanning(.front, nil)
        )
        vc.imageScanningSession.startScanning(expectedClassification: .front)
        waitForCameraSessionToStart()

        // Reset
        vc.reset()

        // Verify VC starts scanning
        XCTAssertStateEqual(vc.imageScanningSession.state, .scanning(.front, nil))
        XCTAssertTrue(mockDocumentUploader.didReset)
    }

    func testModelPerformanceLogged() {
        // Mock metrics
        mockConcurrencyManager.mockAverageFPSMetric = 30
        mockConcurrencyManager.mockNumFramesScannedMetric = 50
        mockDocumentScanner.mlModelMetricsTrackers = [
            MLDetectorMetricsTrackerMock(
                modelName: "mock_model",
                mockAverageMetrics: .init(
                    inference: 0.005,
                    postProcess: 0.01
                ),
                mockNumFrames: 50
            ),
        ]

        // Mock that vc is scanning
        let vc = makeViewController(
            state: .scanning(.front, nil)
        )
        vc.imageScanningSession.startScanning(expectedClassification: .front)
        waitForCameraSessionToStart()
        mockCameraFrameCaptured(vc)

        // Mock that scanner found desired classification
        mockConcurrencyManager.respondToScan(output: makeDocumentScannerOutputLegacy(with: .idCardFront))

        // Verify average_fps analytic sent
        let averageFPSAnalytics = mockAnalyticsClient.loggedAnalyticPayloads(
            withEventName: "average_fps"
        )
        let averageFPSAnalytic = averageFPSAnalytics.first
        XCTAssertEqual(averageFPSAnalytics.count, 1)
        XCTAssert(analytic: averageFPSAnalytic, hasMetadata: "type", withValue: "document")
        XCTAssert(analytic: averageFPSAnalytic, hasMetadata: "value", withValue: Double(30))
        XCTAssert(analytic: averageFPSAnalytic, hasMetadata: "frames", withValue: 50)

        // Verify model_performance analytic sent
        let modelPerfAnalytics = mockAnalyticsClient.loggedAnalyticPayloads(
            withEventName: "model_performance"
        )
        let modelPerfAnalytic = modelPerfAnalytics.first
        XCTAssertEqual(modelPerfAnalytics.count, 1)
        XCTAssert(analytic: modelPerfAnalytic, hasMetadata: "inference", withValue: Double(5))
        XCTAssert(analytic: modelPerfAnalytic, hasMetadata: "postprocess", withValue: Double(10))
        XCTAssert(analytic: modelPerfAnalytic, hasMetadata: "ml_model", withValue: "mock_model")
        XCTAssert(analytic: modelPerfAnalytic, hasMetadata: "frames", withValue: 50)
    }
}

extension DocumentCaptureViewControllerTest {
    fileprivate func verify(
        _ vc: DocumentCaptureViewController,
        expectedState: DocumentCaptureViewController.State,
        expectedButtonState: IdentityFlowView.ViewModel.Button.State?,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertStateEqual(
            vc.imageScanningSession.state,
            expectedState,
            "state",
            file: file,
            line: line
        )
        XCTAssertEqual(
            vc.buttonViewModels.first?.state,
            expectedButtonState,
            "buttonState",
            file: file,
            line: line
        )
    }

    fileprivate func grantCameraAccess(granted: Bool = true) {
        mockCameraPermissionsManager.respondToRequest(granted: granted)
        wait(for: [mockCameraPermissionsManager.didCompleteExpectation], timeout: 1)
    }

    fileprivate func waitForCameraSessionToConfigure(setupResult: CameraSession.SetupResult) {
        mockCameraSession.respondToConfigureSession(setupResult: setupResult)
        wait(for: [mockCameraSession.configureSessionCompletionExp], timeout: 1)
    }

    fileprivate func waitForCameraSessionToStart() {
        mockCameraSession.respondToStartSession()
        wait(for: [mockCameraSession.startSessionCompletionExp], timeout: 1)
    }

    fileprivate func waitForCameraSessionToStop() {
        mockCameraSession.respondToStopSession()
        wait(for: [mockCameraSession.stopSessionCompletionExp], timeout: 1)
    }

    fileprivate func mockTimeoutTimer(_ vc: DocumentCaptureViewController) {
        vc.imageScanningSession.startTimeoutTimer(expectedClassification: .front)
    }

    fileprivate func mockCameraFrameCaptured(_ vc: DocumentCaptureViewController) {
        vc.imageScanningSession.captureOutput(
            mockVideoOutput,
            didOutput: DocumentCaptureViewControllerTest.mockSampleBuffer,
            from: mockCaptureConnection
        )
    }

    @discardableResult
    fileprivate func switchToManualCapture(_ vc: DocumentCaptureViewController) throws -> UISegmentedControl {
        let control = try XCTUnwrap(findCaptureModeControl(in: vc.documentCaptureView))
        control.selectedSegmentIndex = 1
        vc.didChangeCaptureMode(control)
        return control
    }

    fileprivate func findCaptureModeControl(in view: UIView) -> UISegmentedControl? {
        if let control = view as? UISegmentedControl {
            return control
        }

        for subview in view.subviews {
            if let control = findCaptureModeControl(in: subview) {
                return control
            }
        }

        return nil
    }

    fileprivate func makeViewController(
        documentType: DocumentType
    ) -> DocumentCaptureViewController {
        return .init(
            apiConfig: DocumentCaptureViewControllerTest.mockVerificationPage.documentCapture,
            sheetController: mockSheetController,
            cameraSession: mockCameraSession,
            cameraPermissionsManager: mockCameraPermissionsManager,
            documentUploader: mockDocumentUploader,
            anyDocumentScanner: .init(mockDocumentScanner),
            concurrencyManager: mockConcurrencyManager,
            appSettingsHelper: mockAppSettingsHelper,
            avaialableIDTypes: DocumentCaptureViewControllerTest.mockVerificationPage.documentSelect.idDocumentTypeAllowlistKeys
        )
    }

    fileprivate func makeViewController(
        state: DocumentCaptureViewController.State,
        apiConfig: StripeAPI.VerificationPageStaticContentDocumentCapturePage =
            DocumentCaptureViewControllerTest.mockVerificationPage.documentCapture,
        bestFrameWindow: TimeInterval = 0
    ) -> DocumentCaptureViewController {
        return .init(
            apiConfig: apiConfig,
            initialState: state,
            sheetController: mockSheetController,
            cameraSession: mockCameraSession,
            cameraPermissionsManager: mockCameraPermissionsManager,
            documentUploader: mockDocumentUploader,
            anyDocumentScanner: .init(mockDocumentScanner),
            concurrencyManager: mockConcurrencyManager,
            appSettingsHelper: mockAppSettingsHelper,
            avaialableIDTypes: DocumentCaptureViewControllerTest.mockVerificationPage.documentSelect.idDocumentTypeAllowlistKeys,
            bestFramePicker: .init(window: bestFrameWindow)
        )
    }

    fileprivate func makeDocumentScannerOutputLegacyWithIddetectorOutput(
        _ output: IDDetectorOutput,
        isBlurry: Bool = false
    ) -> DocumentScannerOutput {
        return .legacy(
            output,
            .init(
                hasBarcode: true,
                isTimedOut: false,
                symbology: .pdf417,
                timeTryingToFindBarcode: 1
            ),
            .init(
                hasMotionBlur: false,
                iou: nil,
                frameCount: 0,
                duration: 0
            ),
            .init(
                .init(
                    exposureDuration: CMTime(),
                    cameraDeviceType: .builtInDualCamera,
                    isVirtualDevice: nil,
                    lensPosition: 0,
                    exposureISO: 0,
                    isAdjustingFocus: false
                )
            ),
            .init(isBlurry: isBlurry, variance: 0.1)
        )
    }

    fileprivate func makeDocumentScannerOutputLegacy(
        with classification: IDDetectorOutput.Classification,
        isBlurry: Bool = true,
        hasBarcode: Bool = false
    ) -> DocumentScannerOutput {
        return .legacy(
            .init(
                classification: classification,
                documentBounds: CGRect(x: 0.1, y: 0.33, width: 0.8, height: 0.33),
                allClassificationScores: [
                    classification: 0.9
                ]
            ),
            .init(
                hasBarcode: hasBarcode,
                isTimedOut: false,
                symbology: .pdf417,
                timeTryingToFindBarcode: 1
            ),
            .init(
                hasMotionBlur: !isBlurry,
                iou: nil,
                frameCount: 0,
                duration: 0
            ),
            .init(
                .init(
                    exposureDuration: CMTime(),
                    cameraDeviceType: .builtInDualCamera,
                    isVirtualDevice: nil,
                    lensPosition: 0,
                    exposureISO: 0,
                    isAdjustingFocus: !isBlurry
                )
            ),
            .init(isBlurry: false, variance: 0.1)
        )
    }

    /// Same as XCTAssertEqual but ignores image pointer discrepencies
    fileprivate func XCTAssertStateEqual(
        _ lhs: DocumentCaptureViewController.State,
        _ rhs: DocumentCaptureViewController.State,
        _ message: String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let isEqual: Bool
        switch (lhs, rhs) {
        case (.scanning(let lSide, let lOutput), .scanning(let rSide, let rOutput)):
            isEqual = (lSide == rSide) && (lOutput?.idDetectorOutput.classification == rOutput?.idDetectorOutput.classification)
        case (.scanned(let left, _), .scanned(let right, _)),
            (.timeout(let left), .timeout(let right)):
            isEqual = (left == right)
        case (.initial, .initial),
            (.saving, .saving),
            (.noCameraAccess, .noCameraAccess),
            (.cameraError, .cameraError):
            isEqual = true
        default:
            isEqual = false
        }

        guard !isEqual else { return }
        XCTAssertEqual(lhs, rhs, message, file: file, line: line)
    }
}
