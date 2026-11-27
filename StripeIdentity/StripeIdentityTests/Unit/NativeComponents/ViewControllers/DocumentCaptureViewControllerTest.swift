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

    func testScanningTimeoutCapturesEarlierBlurryFrameWithItsMetadata() throws {
        // Given a matching blurry frame followed by a worse frame and a lost document
        let vc = makeViewController(state: .scanning(.front, nil))
        let bestImage = try XCTUnwrap(CapturedImageMock.frontDriversLicense.image.cgImage)
        let laterImage = try XCTUnwrap(bestImage.copy())
        let bestOutput = makeTimeoutCandidateOutput(variance: 90)
        let bestExif = CameraExifMetadata(brightnessValue: 1, focalLength: 2, lensModel: "Best frame")
        mockConcurrencyManager.mockAverageFPSMetric = 30
        mockConcurrencyManager.mockNumFramesScannedMetric = 3
        mockDocumentScanner.mlModelMetricsTrackers = [
            MLDetectorMetricsTrackerMock(
                modelName: "mock_model",
                mockAverageMetrics: .init(inference: 0.005, postProcess: 0.01),
                mockNumFrames: 3
            ),
        ]
        deliverScanResult(vc, output: bestOutput, image: bestImage, exifMetadata: bestExif)
        deliverScanResult(vc, output: makeTimeoutCandidateOutput(variance: 10), image: laterImage)
        deliverScanResult(vc, output: nil, image: laterImage)
        XCTAssertNil(mockDocumentUploader.uploadedSide)

        // When auto-capture times out
        vc.imageScanningSession.startTimeoutTimer(expectedClassification: .front)
        try XCTUnwrap(vc.imageScanningSession.timeoutTimer).fire()

        // Then the cached frame and its metadata are uploaded together
        verify(vc, expectedState: .scanned(.front, UIImage()), expectedButtonState: .enabled)
        XCTAssertTrue(mockDocumentUploader.uploadedOriginalImage === bestImage)
        XCTAssertEqual(mockDocumentUploader.uploadedDocumentScannerOutput, bestOutput)
        XCTAssertEqual(mockDocumentUploader.uploadedExifMetadata, bestExif)
        XCTAssertEqual(mockDocumentUploader.uploadedSide, .front)
        XCTAssertEqual(mockDocumentUploader.uploadMethod, .autoCapture)
        XCTAssertEqual(mockSheetController.analyticsClient.blurScoreFront, 90)
        XCTAssertEqual(vc.imageScanningSession.timeoutTimer?.isValid, false)
        guard case .scanned(_, let capturedImage) = vc.imageScanningSession.state else {
            return XCTFail("Expected scanned state")
        }
        XCTAssertTrue(capturedImage.cgImage === bestImage)
        waitForCameraSessionToStop()
        XCTAssertEqual(mockAnalyticsClient.loggedAnalyticPayloads(withEventName: "average_fps").count, 1)
        XCTAssertEqual(mockAnalyticsClient.loggedAnalyticPayloads(withEventName: "model_performance").count, 1)
    }

    func testScanningTimeoutDoesNotCaptureWrongSideOrInvalidFrames() throws {
        // Given frames that never match the requested front side
        let vc = makeViewController(state: .scanning(.front, nil))
        deliverScanResult(vc, output: makeTimeoutCandidateOutput(classification: .idCardBack))
        deliverScanResult(vc, output: makeTimeoutCandidateOutput(classification: .invalid))
        deliverScanResult(vc, output: nil)

        // When auto-capture times out
        vc.imageScanningSession.startTimeoutTimer(expectedClassification: .front)
        try XCTUnwrap(vc.imageScanningSession.timeoutTimer).fire()

        // Then the existing timeout flow remains available
        verify(vc, expectedState: .timeout(.front), expectedButtonState: .enabled)
        XCTAssertNil(mockDocumentUploader.uploadedSide)
        XCTAssertEqual(mockAnalyticsClient.loggedAnalyticPayloads(withEventName: "document_timeout").count, 1)
    }

    func testScanningTimeoutKeepsBestFramesSeparateForEachSide() throws {
        // Given a front frame with a higher score than the back frame
        let vc = makeViewController(state: .scanning(.front, nil))
        deliverScanResult(vc, output: makeTimeoutCandidateOutput(variance: 200))
        vc.imageScanningSession.startScanning(expectedClassification: .back)
        let backOutput = makeTimeoutCandidateOutput(classification: .idCardBack, variance: 20)
        deliverScanResult(vc, output: backOutput, side: .back)

        // When back capture times out
        vc.imageScanningSession.startTimeoutTimer(expectedClassification: .back)
        try XCTUnwrap(vc.imageScanningSession.timeoutTimer).fire()

        // Then the back frame is captured regardless of the front frame's score
        XCTAssertStateEqual(vc.imageScanningSession.state, .scanned(.back, UIImage()))
        XCTAssertEqual(mockDocumentUploader.uploadedSide, .back)
        XCTAssertEqual(mockDocumentUploader.uploadedDocumentScannerOutput, backOutput)
        XCTAssertEqual(mockSheetController.analyticsClient.blurScoreBack, 20)
    }

    func testScanningTimeoutDoesNotReuseFrontFrameForBack() throws {
        // Given a front candidate and no matching back candidate
        let vc = makeViewController(state: .scanning(.front, nil))
        deliverScanResult(vc, output: makeTimeoutCandidateOutput())
        vc.imageScanningSession.startScanning(expectedClassification: .back)

        // When back capture times out
        vc.imageScanningSession.startTimeoutTimer(expectedClassification: .back)
        try XCTUnwrap(vc.imageScanningSession.timeoutTimer).fire()

        // Then the user can retry the back without uploading the front again
        verify(vc, expectedState: .timeout(.back), expectedButtonState: .enabled)
        XCTAssertNil(mockDocumentUploader.uploadedSide)
    }

    func testScanningTimeoutRetainsBestFrameWhenScanningRestarts() throws {
        // Given a passport candidate from an earlier scan attempt
        let vc = makeViewController(state: .scanning(.front, nil))
        let bestOutput = makeTimeoutCandidateOutput(classification: .passport, variance: 90)
        deliverScanResult(vc, output: bestOutput)

        // When scanning restarts and times out after a worse frame
        vc.imageScanningSession.startScanning(expectedClassification: .front)
        deliverScanResult(vc, output: makeTimeoutCandidateOutput(classification: .passport, variance: 10))
        vc.imageScanningSession.startTimeoutTimer(expectedClassification: .front)
        try XCTUnwrap(vc.imageScanningSession.timeoutTimer).fire()

        // Then the earlier candidate remains available for this session
        XCTAssertStateEqual(vc.imageScanningSession.state, .scanned(.front, UIImage()))
        XCTAssertEqual(mockDocumentUploader.uploadedDocumentScannerOutput, bestOutput)
    }

    func testResetClearsTimeoutFallbackFrames() throws {
        // Given a matching blurry candidate
        let vc = makeViewController(state: .scanning(.front, nil))
        deliverScanResult(vc, output: makeTimeoutCandidateOutput())

        // When the verification data is reset and a new scan times out
        vc.reset()
        vc.imageScanningSession.startTimeoutTimer(expectedClassification: .front)
        try XCTUnwrap(vc.imageScanningSession.timeoutTimer).fire()

        // Then the old document is not captured
        verify(vc, expectedState: .timeout(.front), expectedButtonState: .enabled)
        XCTAssertNil(mockDocumentUploader.uploadedSide)
    }

    func testManualFramesAreNotCachedForAutomaticTimeout() throws {
        // Given a matching frame collected in manual mode
        let vc = makeViewController(state: .scanning(.front, nil))
        let control = try switchToManualCapture(vc)
        deliverScanResult(vc, output: makeTimeoutCandidateOutput())

        // When the user returns to live capture and it times out without another frame
        control.selectedSegmentIndex = 0
        vc.didChangeCaptureMode(control)
        try XCTUnwrap(vc.imageScanningSession.timeoutTimer).fire()

        // Then manual frames do not become automatic captures
        verify(vc, expectedState: .timeout(.front), expectedButtonState: .enabled)
        XCTAssertNil(mockDocumentUploader.uploadedSide)
    }

    func testManualModeDoesNotUseCachedTimeoutFallback() throws {
        // Given a live candidate followed by a switch to manual capture
        let vc = makeViewController(state: .scanning(.front, nil))
        deliverScanResult(vc, output: makeTimeoutCandidateOutput())
        _ = try switchToManualCapture(vc)

        // When a timeout is delivered while manual mode is active
        vc.imageScanningSession.startTimeoutTimer(expectedClassification: .front)
        try XCTUnwrap(vc.imageScanningSession.timeoutTimer).fire()

        // Then capturing still requires the user's explicit action
        XCTAssertNil(mockDocumentUploader.uploadedSide)
        XCTAssertStateEqual(vc.imageScanningSession.state, .timeout(.front))
    }

    func testNormalCaptureDoesNotPickBlurryTimeoutCandidate() {
        // Given a blurry frame with a higher fallback score
        let vc = makeViewController(state: .scanning(.front, nil))
        deliverScanResult(vc, output: makeTimeoutCandidateOutput(variance: 200))
        XCTAssertNil(mockDocumentUploader.uploadedSide)

        // When a lower-scoring frame passes normal capture requirements
        let validOutput = makeTimeoutCandidateOutput(variance: 20, isBlurry: false)
        deliverScanResult(vc, output: validOutput)

        // Then normal capture uses the valid frame
        XCTAssertStateEqual(vc.imageScanningSession.state, .scanned(.front, UIImage()))
        XCTAssertEqual(mockDocumentUploader.uploadedDocumentScannerOutput, validOutput)
        XCTAssertEqual(mockDocumentUploader.uploadMethod, .autoCapture)
    }

    func testNormalCaptureKeepsOriginalScoringAndAcceptsSmallImprovements() throws {
        // Given two qualifying frames that the normal and timeout scorers rank differently
        let vc = makeViewController(state: .scanning(.front, nil), bestFrameWindow: 1)
        let firstImage = try XCTUnwrap(CapturedImageMock.frontDriversLicense.image.cgImage)
        let bestImage = try XCTUnwrap(CapturedImageMock.backDriversLicense.image.cgImage)
        let firstOutput = makeTimeoutCandidateOutput(variance: 200, isBlurry: false, confidence: 0.95, iou: 0.85)
        let bestOutput = makeTimeoutCandidateOutput(variance: 20, isBlurry: false, confidence: 0.94, iou: 0.88)
        let firstExif = CameraExifMetadata(brightnessValue: 1, focalLength: 2, lensModel: "First frame")
        let bestExif = CameraExifMetadata(brightnessValue: 3, focalLength: 4, lensModel: "Normal best frame")
        XCTAssertTrue(firstOutput.isHighQuality(side: .front))
        XCTAssertTrue(bestOutput.isHighQuality(side: .front))
        XCTAssertGreaterThan(firstOutput.timeoutQualityScore(side: .front), bestOutput.timeoutQualityScore(side: .front))
        // Motion stability improves the normal score by less than the cache's 0.02 threshold.
        let improvement = bestOutput.qualityScore(side: .front) - firstOutput.qualityScore(side: .front)
        XCTAssertGreaterThan(improvement, 0)
        XCTAssertLessThan(improvement, 0.02)
        mockTimeoutTimer(vc)
        deliverScanResult(vc, output: firstOutput, image: firstImage, exifMetadata: firstExif)
        deliverScanResult(vc, output: bestOutput, image: bestImage, exifMetadata: bestExif)
        XCTAssertNil(mockDocumentUploader.uploadedSide)
        XCTAssertEqual(vc.imageScanningSession.state, .scanning(.front, bestOutput))

        // When the normal one-second window expires and another lower-scoring frame arrives
        let windowExpired = expectation(description: "Normal best frame window expired")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            windowExpired.fulfill()
        }
        wait(for: [windowExpired], timeout: 2)
        deliverScanResult(vc, output: firstOutput, image: firstImage, exifMetadata: firstExif)

        // Then normal capture uses the original ranking and the selected frame's metadata
        verify(vc, expectedState: .scanned(.front, UIImage()), expectedButtonState: .enabled)
        XCTAssertTrue(mockDocumentUploader.uploadedOriginalImage === bestImage)
        XCTAssertEqual(mockDocumentUploader.uploadedDocumentScannerOutput, bestOutput)
        XCTAssertEqual(mockDocumentUploader.uploadedExifMetadata, bestExif)
        XCTAssertEqual(mockDocumentUploader.uploadMethod, .autoCapture)
        XCTAssertEqual(vc.imageScanningSession.timeoutTimer?.isValid, false)
        XCTAssertTrue(mockAnalyticsClient.loggedAnalyticPayloads(withEventName: "document_timeout").isEmpty)
        waitForCameraSessionToStop()
    }

    func testBlurryTimeoutCandidateDoesNotStartNormalCaptureWindow() {
        // Given a blurry candidate cached more than one normal capture window ago
        let vc = makeViewController(state: .scanning(.front, nil), bestFrameWindow: 1)
        deliverScanResult(vc, output: makeTimeoutCandidateOutput(variance: 200))
        let windowExpired = expectation(description: "Blurry frame is older than the capture window")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            windowExpired.fulfill()
        }
        wait(for: [windowExpired], timeout: 2)

        // When the first qualifying frame arrives
        let validOutput = makeTimeoutCandidateOutput(variance: 20, isBlurry: false)
        deliverScanResult(vc, output: validOutput)

        // Then it starts a new normal window instead of immediately capturing a frame
        XCTAssertNil(mockDocumentUploader.uploadedSide)
        XCTAssertEqual(vc.imageScanningSession.state, .scanning(.front, validOutput))
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

    fileprivate func deliverScanResult(
        _ vc: DocumentCaptureViewController,
        output: DocumentScannerOutput?,
        image: CGImage = CapturedImageMock.frontDriversLicense.image.cgImage!,
        exifMetadata: CameraExifMetadata? = nil,
        side: DocumentSide = .front
    ) {
        vc.imageScanningSessionDidScanImage(
            vc.imageScanningSession,
            image: image,
            scannerOutput: output,
            exifMetadata: exifMetadata,
            expectedClassification: side
        )
    }

    fileprivate func makeTimeoutCandidateOutput(
        classification: IDDetectorOutput.Classification = .idCardFront,
        variance: Float = 50,
        isBlurry: Bool = true,
        confidence: Float = 0.9,
        iou: Float? = nil
    ) -> DocumentScannerOutput {
        return .legacy(
            .init(
                classification: classification,
                documentBounds: CGRect(x: 0.1, y: 0.33, width: 0.8, height: 0.33),
                allClassificationScores: [classification: confidence]
            ),
            nil,
            .init(hasMotionBlur: false, iou: iou, frameCount: 0, duration: 0),
            nil,
            .init(isBlurry: isBlurry, variance: variance)
        )
    }

    fileprivate func makeDocumentScannerOutputLegacyWithIddetectorOutput(
        _ output: IDDetectorOutput
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
            .init(isBlurry: false, variance: 0.1)
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
