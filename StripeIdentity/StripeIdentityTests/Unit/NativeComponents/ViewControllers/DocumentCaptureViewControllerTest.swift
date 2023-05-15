//
//  DocumentCaptureViewControllerTest.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 11/11/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import AVKit
import Foundation
@_spi(STP) import StripeCameraCoreTestUtils
@_spi(STP) import StripeCore
@_spi(STP) import StripeCoreTestUtils
import StripeCoreTestUtils
import XCTest

@testable@_spi(STP) import StripeCameraCore
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

    override class func setUp() {
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
        let vc = makeViewController(state: .initial, documentType: .idCard)
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

    func testTransitionFromScanningCardFront() {
        let vc = makeViewController(
            state: .scanning(.front, nil),
            documentType: .idCard
        )
        let mockDocumentScannerOutput = makeDocumentScannerOutput(with: .idCardFront)
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

    func testTransitionFromScannedCardFront() {
        let vc = makeViewController(
            state: .scanned(.front, UIImage()),
            documentType: .idCard
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
        let vc = makeViewController(state: .timeout(.front), documentType: .idCard)
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
            state: .scanning(.back, nil),
            documentType: .idCard
        )
        let mockDocumentScannerOutput = makeDocumentScannerOutput(with: .idCardBack)
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
            state: .scanned(.back, UIImage()),
            documentType: .idCard
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
        let vc = makeViewController(state: .timeout(.back), documentType: .idCard)
        vc.buttonViewModels.last!.didTap()
        waitForCameraSessionToStart()
        verify(
            vc,
            expectedState: .scanning(.back, nil),
            expectedButtonState: .disabled
        )
    }

    func testTransitionFromInitialPassport() {
        let vc = makeViewController(state: .initial, documentType: .passport)
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
            state: .scanning(.front, nil),
            documentType: .passport
        )
        let mockDocumentScannerOutput = makeDocumentScannerOutput(with: .passport)
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
            state: .scanned(.front, UIImage()),
            documentType: .passport
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
        let vc = makeViewController(state: .timeout(.front), documentType: .passport)
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
            state: .scanning(.front, .passport),
            documentType: .passport
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

        guard case .success = mockSheetController.frontUploadedDocumentsResult else {
            return XCTFail("Expected success result")
        }

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

        guard case .success = mockSheetController.backUploadedDocumentsResult else {
            return XCTFail("Expected success result")
        }

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

        let vc = makeViewController(state: .initial, documentType: .idCard)
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
        // Verify analytics
        let analytic = mockAnalyticsClient.loggedAnalyticPayloads(
            withEventName: "camera_permission_denied"
        ).first
        XCTAssert(analytic: analytic, hasMetadata: "scan_type", withValue: "driving_license")
        XCTAssertEqual(
            mockAnalyticsClient.loggedAnalyticPayloads(withEventName: "camera_permission_granted")
                .count,
            0
        )
    }

    func testCameraSessionFailedConfigure() {
        // Mock collected data for analytics
        mockSheetController.collectedData = VerificationPageDataUpdateMock.default.collectedData!

        let vc = makeViewController(state: .initial, documentType: .drivingLicense)
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
        XCTAssert(analytic: analytic, hasMetadata: "scan_type", withValue: "driving_license")
        XCTAssert(
            analytic: analytic,
            hasMetadataError: "error",
            withDomain: "mock_error",
            code: 100,
            fileName: "DocumentCaptureViewController.swift"
        )
    }

    func testCameraAccessGrantedAnalytic() {
        // Mock collected data for analytics
        mockSheetController.collectedData = VerificationPageDataUpdateMock.default.collectedData!

        let vc = makeViewController(state: .initial, documentType: .idCard)
        // Mock that view appeared
        vc.viewWillAppear(false)
        // Grant access
        grantCameraAccess(granted: true)

        // Verify analytics
        let analytic = mockAnalyticsClient.loggedAnalyticPayloads(
            withEventName: "camera_permission_granted"
        ).first
        XCTAssert(analytic: analytic, hasMetadata: "scan_type", withValue: "driving_license")
        XCTAssertEqual(
            mockAnalyticsClient.loggedAnalyticPayloads(withEventName: "camera_permission_denied")
                .count,
            0
        )
    }

    func testSettingsButton() {
        let vc = makeViewController(state: .noCameraAccess, documentType: .idCard)
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

    func testFileUploadButtonCameraAccess() {
        let vc = makeViewController(state: .noCameraAccess, documentType: .idCard)
        vc.buttonViewModels.first!.didTap()
        // Should open File Upload screen
        XCTAssertIs(
            mockFlowController.replacedWithViewController as Any,
            DocumentFileUploadViewController.self
        )
    }

    func testFileUploadButtonTimeout() {
        let vc = makeViewController(state: .timeout(.front), documentType: .idCard)
        vc.buttonViewModels.first!.didTap()
        // Should open File Upload screen
        XCTAssertIs(
            mockFlowController.replacedWithViewController as Any,
            DocumentFileUploadViewController.self
        )
    }

    func testNoCameraAccessButtonsReqLiveCapture() throws {
        // If requireLiveCapture is enabled, upload action should not display
        // without camera access
        let mockResponse = try VerificationPageMock.requireLiveCapture.make()
        let vc = makeViewController(
            state: .noCameraAccess,
            documentType: .idCard,
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
            documentType: .idCard,
            apiConfig: mockResponse.documentCapture
        )
        XCTAssertEqual(vc.buttonViewModels.count, 2)
    }

    func testScanningTimeout() {
        // Mock collected data for analytics
        mockSheetController.collectedData = VerificationPageDataUpdateMock.default.collectedData!

        let vc = makeViewController(
            state: .scanning(.front, nil),
            documentType: .drivingLicense
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
        XCTAssert(analytic: analytic, hasMetadata: "scan_type", withValue: "driving_license")
        XCTAssert(analytic: analytic, hasMetadata: "side", withValue: "front")
    }

    func testScanAttemptsFront() {
        let vc = makeViewController(
            state: .scanning(.front, nil),
            documentType: .drivingLicense
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

    func testScanningUpdatesState() {
        let vc = makeViewController(
            state: .scanning(.front, nil),
            documentType: .idCard
        )
        // Mock that scanner is scanning
        vc.imageScanningSession.startScanning(expectedClassification: .front)
        waitForCameraSessionToStart()
        mockCameraFrameCaptured(vc)

        // Mock that scanner found a classification that was not desired and
        // verify the state is updated accordingly
        mockConcurrencyManager.respondToScan(output: makeDocumentScannerOutput(with: .invalid))
        XCTAssertStateEqual(vc.imageScanningSession.state, .scanning(.front, .invalid))

        mockConcurrencyManager.respondToScan(output: makeDocumentScannerOutput(with: .idCardBack))
        XCTAssertStateEqual(vc.imageScanningSession.state, .scanning(.front, .idCardBack))

        mockConcurrencyManager.respondToScan(output: makeDocumentScannerOutput(with: .passport))
        XCTAssertStateEqual(vc.imageScanningSession.state, .scanning(.front, .passport))

        mockConcurrencyManager.respondToScan(output: nil)
        XCTAssertStateEqual(vc.imageScanningSession.state, .scanning(.front, nil))

        // Mock that scanner found desired classification, but is blurry
        mockConcurrencyManager.respondToScan(
            output: makeDocumentScannerOutput(with: .idCardFront, isHighQuality: false)
        )
        XCTAssertStateEqual(vc.imageScanningSession.state, .scanning(.front, .idCardFront))

        // Mock that scanner found desired classification
        mockConcurrencyManager.respondToScan(output: makeDocumentScannerOutput(with: .idCardFront))
        XCTAssertStateEqual(vc.imageScanningSession.state, .scanned(.front, UIImage()))
    }

    func testAppBackgrounded() {
        // Mock that vc is scanning
        let vc = makeViewController(
            state: .scanning(.front, nil),
            documentType: .idCard
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
            state: .scanning(.front, nil),
            documentType: .idCard
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
            state: .scanned(.back, UIImage()),
            documentType: .drivingLicense
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
            state: .scanning(.front, nil),
            documentType: .idCard
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
            state: .scanning(.front, nil),
            documentType: .idCard
        )
        vc.imageScanningSession.startScanning(expectedClassification: .front)
        waitForCameraSessionToStart()
        mockCameraFrameCaptured(vc)

        // Mock that scanner found desired classification
        mockConcurrencyManager.respondToScan(output: makeDocumentScannerOutput(with: .idCardFront))

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

    fileprivate func makeViewController(
        documentType: DocumentType
    ) -> DocumentCaptureViewController {
        return .init(
            apiConfig: DocumentCaptureViewControllerTest.mockVerificationPage.documentCapture,
            documentType: documentType,
            sheetController: mockSheetController,
            cameraSession: mockCameraSession,
            cameraPermissionsManager: mockCameraPermissionsManager,
            documentUploader: mockDocumentUploader,
            anyDocumentScanner: .init(mockDocumentScanner),
            concurrencyManager: mockConcurrencyManager,
            appSettingsHelper: mockAppSettingsHelper
        )
    }

    fileprivate func makeViewController(
        state: DocumentCaptureViewController.State,
        documentType: DocumentType,
        apiConfig: StripeAPI.VerificationPageStaticContentDocumentCapturePage =
            DocumentCaptureViewControllerTest.mockVerificationPage.documentCapture
    ) -> DocumentCaptureViewController {
        return .init(
            apiConfig: apiConfig,
            documentType: documentType,
            initialState: state,
            sheetController: mockSheetController,
            cameraSession: mockCameraSession,
            cameraPermissionsManager: mockCameraPermissionsManager,
            documentUploader: mockDocumentUploader,
            anyDocumentScanner: .init(mockDocumentScanner),
            concurrencyManager: mockConcurrencyManager,
            appSettingsHelper: mockAppSettingsHelper
        )
    }

    fileprivate func makeDocumentScannerOutput(
        with classification: IDDetectorOutput.Classification,
        isHighQuality: Bool = true
    ) -> DocumentScannerOutput {
        return .init(
            idDetectorOutput: .init(
                classification: classification,
                documentBounds: CGRect(x: 0.1, y: 0.33, width: 0.8, height: 0.33),
                allClassificationScores: [
                    classification: 0.9
                ]
            ),
            barcode: .init(
                hasBarcode: true,
                isTimedOut: false,
                symbology: .pdf417,
                timeTryingToFindBarcode: 1
            ),
            motionBlur: .init(
                hasMotionBlur: !isHighQuality,
                iou: nil,
                frameCount: 0,
                duration: 0
            ),
            cameraProperties: .init(
                exposureDuration: CMTime(),
                cameraDeviceType: .builtInDualCamera,
                isVirtualDevice: nil,
                lensPosition: 0,
                exposureISO: 0,
                isAdjustingFocus: !isHighQuality
            )
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
        case (.scanning(let lSide, let lClass), .scanning(let rSide, let rClass)):
            isEqual = (lSide == rSide) && (lClass == rClass)
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
