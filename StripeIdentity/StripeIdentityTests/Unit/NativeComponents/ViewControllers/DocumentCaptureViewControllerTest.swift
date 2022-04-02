//
//  DocumentCaptureViewControllerTest.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 11/11/21.
//

import Foundation
import XCTest
import AVKit
@testable @_spi(STP) import StripeCameraCore
@_spi(STP) import StripeCore
@_spi(STP) import StripeCameraCoreTestUtils
import StripeCoreTestUtils
@testable import StripeIdentity

final class DocumentCaptureViewControllerTest: XCTestCase {

    let mockCameraSession = MockTestCameraSession()

    static var mockVerificationPage: VerificationPage!
    var mockFlowController: VerificationSheetFlowControllerMock!
    var mockSheetController: VerificationSheetControllerMock!
    var mockDocumentUploader: DocumentUploaderMock!
    let mockDocumentScanner = DocumentScannerMock()
    let mockCameraPermissionsManager = MockCameraPermissionsManager()
    let mockAppSettingsHelper = MockAppSettingsHelper()

    let mockVideoOutput = AVCaptureVideoDataOutput()
    lazy var mockCaptureConnection = AVCaptureConnection(inputPorts: [], output: mockVideoOutput)

    static var mockSampleBuffer: CMSampleBuffer!

    let mockError = NSError(domain: "", code: 0, userInfo: nil)

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
        mockSheetController = .init(
            flowController: mockFlowController
        )
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
            expectedState: .scanning(.front, foundClassification: nil),
            expectedButtonState: .disabled
        )
    }

    func testTransitionFromScanningCardFront() {
        let vc = makeViewController(
            state: .scanning(.front, foundClassification: nil),
            documentType: .idCard
        )
        let mockDocumentScannerOutput = makeDocumentScannerOutput(with: .idCardFront)
        // Mock timer so we can verify it was invalidated
        mockTimeoutTimer(vc)
        mockCameraFrameCaptured(vc)
        // Mock that scanner found desired classification
        mockDocumentScanner.respondToScan(output: mockDocumentScannerOutput)
        verify(
            vc,
            expectedState: .scanned(.front, UIImage()),
            expectedButtonState: .enabled
        )
        // Verify timeout timer was invalidated
        XCTAssertEqual(vc.timeoutTimer?.isValid, false)
        XCTAssertTrue(mockCameraSession.didStopSession)
        XCTAssertTrue(mockDocumentScanner.didReset)
        // Verify image started uploading
        XCTAssertEqual(mockDocumentUploader.uploadedSide, .front)
        XCTAssertEqual(mockDocumentUploader.uploadMethod, .autoCapture)
        XCTAssertEqual(mockDocumentUploader.uploadedDocumentScannerOutput, mockDocumentScannerOutput)
    }

    func testTransitionFromScannedCardFront() {
        let vc = makeViewController(
            state: .scanned(.front, UIImage()),
            documentType: .idCard
        )
        vc.buttonViewModels.first!.didTap()
        // Verify camera session started
        waitForCameraSessionToStart()
        // Verify state is scanning
        verify(
            vc,
            expectedState: .scanning(.back, foundClassification: nil),
            expectedButtonState: .disabled
        )
    }

    func testTransitionFromTimeoutCardFront() {
        let vc = makeViewController(state: .timeout(.front), documentType: .idCard)
        vc.buttonViewModels.last!.didTap()
        // Verify camera session started
        waitForCameraSessionToStart()
        verify(
            vc,
            expectedState: .scanning(.front, foundClassification: nil),
            expectedButtonState: .disabled
        )
    }

    func testTransitionFromScanningCardBack() {
        let vc = makeViewController(
            state: .scanning(.back, foundClassification: nil),
            documentType: .idCard
        )
        let mockDocumentScannerOutput = makeDocumentScannerOutput(with: .idCardBack)
        // Mock timer so we can verify it was invalidated
        mockTimeoutTimer(vc)
        mockCameraFrameCaptured(vc)
        // Mock that scanner found desired classification
        mockDocumentScanner.respondToScan(output: mockDocumentScannerOutput)
        verify(
            vc,
            expectedState: .scanned(.back, UIImage()),
            expectedButtonState: .enabled
        )
        // Verify timeout timer was invalidated
        XCTAssertEqual(vc.timeoutTimer?.isValid, false)
        XCTAssertTrue(mockCameraSession.didStopSession)
        XCTAssertTrue(mockDocumentScanner.didReset)
        // Verify image started uploading
        XCTAssertEqual(mockDocumentUploader.uploadedSide, .back)
        XCTAssertEqual(mockDocumentUploader.uploadMethod, .autoCapture)
        XCTAssertEqual(mockDocumentUploader.uploadedDocumentScannerOutput, mockDocumentScannerOutput)
    }

    func testTransitionFromScannedCardBack() {
        let vc = makeViewController(
            state: .scanned(.back, UIImage()),
            documentType: .idCard
        )
        vc.buttonViewModels.first!.didTap()
        verify(
            vc,
            expectedState: .saving(lastImage: UIImage()),
            expectedButtonState: .loading
        )
        // Mock that upload finishes
        mockDocumentUploader.frontBackUploadPromise.resolve(with: (front: nil, back: nil))
        guard case .success = mockSheetController.uploadedDocumentsResult else {
            return XCTFail("Expected success result")
        }
    }

    func testTransitionFromTimeoutCardBack() {
        let vc = makeViewController(state: .timeout(.back), documentType: .idCard)
        vc.buttonViewModels.last!.didTap()
        waitForCameraSessionToStart()
        verify(
            vc,
            expectedState: .scanning(.back, foundClassification: nil),
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
            expectedState: .scanning(.front, foundClassification: nil),
            expectedButtonState: .disabled
        )
    }

    func testTransitionFromScanningPassport() {
        let vc = makeViewController(
            state: .scanning(.front, foundClassification: nil),
            documentType: .passport
        )
        let mockDocumentScannerOutput = makeDocumentScannerOutput(with: .passport)
        // Mock timer so we can verify it was invalidated
        mockTimeoutTimer(vc)
        mockCameraFrameCaptured(vc)
        // Mock that scanner found desired classification
        mockDocumentScanner.respondToScan(output: mockDocumentScannerOutput)
        verify(
            vc,
            expectedState: .scanned(.front, UIImage()),
            expectedButtonState: .enabled
        )
        // Verify timeout timer was invalidated
        XCTAssertEqual(vc.timeoutTimer?.isValid, false)
        XCTAssertTrue(mockCameraSession.didStopSession)
        XCTAssertTrue(mockDocumentScanner.didReset)
        // Verify image started uploading
        XCTAssertEqual(mockDocumentUploader.uploadedSide, .front)
        XCTAssertEqual(mockDocumentUploader.uploadMethod, .autoCapture)
        XCTAssertEqual(mockDocumentUploader.uploadedDocumentScannerOutput, mockDocumentScannerOutput)
    }

    func testTransitionFromScannedPassport() {
        let vc = makeViewController(
            state: .scanned(.front, UIImage()),
            documentType: .passport
        )
        vc.buttonViewModels.first!.didTap()
        verify(
            vc,
            expectedState: .saving(lastImage: UIImage()),
            expectedButtonState: .loading
        )
        // Mock that upload finishes
        mockDocumentUploader.frontBackUploadPromise.resolve(with: (front: nil, back: nil))
        guard case .success = mockSheetController.uploadedDocumentsResult else {
            return XCTFail("Expected success result")
        }
    }

    func testTransitionFromTimeoutPassport() {
        let vc = makeViewController(state: .timeout(.front), documentType: .passport)
        vc.buttonViewModels.last!.didTap()
        waitForCameraSessionToStart()
        verify(
            vc,
            expectedState: .scanning(.front, foundClassification: nil),
            expectedButtonState: .disabled
        )
    }

    func testSaveDataAndTransition() {
        let mockCombinedFileData = VerificationPageDataUpdateMock.default.collectedData.map { (front: $0.idDocumentFront!, back: $0.idDocumentBack!) }!
        let mockBackImage = UIImage()

        // Mock that file has been captured and upload has begun
        let vc = makeViewController(documentType: .drivingLicense)
        mockDocumentUploader.frontBackUploadPromise.resolve(with: mockCombinedFileData)

        // Request to save data
        vc.saveDataAndTransitionToNextScreen(lastDocumentSide: .back, lastImage: mockBackImage)

        // Verify data saved and transitioned to next screen
        guard case .success = mockSheetController.uploadedDocumentsResult else {
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
    }

    func testCameraSessionFailedConfigure() {
        let vc = makeViewController(state: .initial, documentType: .idCard)
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
        XCTAssertIs(mockFlowController.replacedWithViewController as Any, DocumentFileUploadViewController.self)
    }

    func testFileUploadButtonTimeout() {
        let vc = makeViewController(state: .timeout(.front), documentType: .idCard)
        vc.buttonViewModels.first!.didTap()
        // Should open File Upload screen
        XCTAssertIs(mockFlowController.replacedWithViewController as Any, DocumentFileUploadViewController.self)
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
        let vc = makeViewController(
            state: .scanning(.front, foundClassification: nil),
            documentType: .idCard
        )
        let startedScanningDate = Date()
        // Mock that scanner is scanning
        vc.startScanning(documentSide: .front)
        waitForCameraSessionToStart()

        guard let timer = vc.timeoutTimer else {
            return XCTFail("Expected timeout timer to be set")
        }

        /*
         `autocapture_timeout` in mock API response is 1000ms.
         We want to test that the timer will fire 10s after `startScanning()` is
         called. Since `Timer.timeInterval` is always 0 for non-repeating timers,
         we'll check the delta between the timer's firing date and when
         `startScanning` was called. Using an accuracy of 0.2s to account for
         processing time of calling `startScanning`.
         */
        XCTAssertEqual(timer.fireDate.timeIntervalSince(startedScanningDate), 10, accuracy: 0.2)

        // Simulate time out
        timer.fire()

        verify(
            vc,
            expectedState: .timeout(.front),
            expectedButtonState: .enabled
        )
        XCTAssertEqual(vc.timeoutTimer?.isValid, false)
        XCTAssertTrue(mockCameraSession.didStopSession)
        XCTAssertTrue(mockDocumentScanner.didReset)
    }

    func testScanningUpdatesState() {
        let vc = makeViewController(
            state: .scanning(.front, foundClassification: nil),
            documentType: .idCard
        )
        // Mock that scanner is scanning
        vc.startScanning(documentSide: .front)
        waitForCameraSessionToStart()
        mockCameraFrameCaptured(vc)

        // Mock that scanner found a classification that was not desired and
        // verify the state is updated accordingly
        mockDocumentScanner.respondToScan(output: makeDocumentScannerOutput(with: .invalid))
        XCTAssertStateEqual(vc.state, .scanning(.front, foundClassification: .invalid))

        mockDocumentScanner.respondToScan(output: makeDocumentScannerOutput(with: .idCardBack))
        XCTAssertStateEqual(vc.state, .scanning(.front, foundClassification: .idCardBack))

        mockDocumentScanner.respondToScan(output: makeDocumentScannerOutput(with: .passport))
        XCTAssertStateEqual(vc.state, .scanning(.front, foundClassification: .passport))

        mockDocumentScanner.respondToScan(output: nil)
        XCTAssertStateEqual(vc.state, .scanning(.front, foundClassification: nil))

        // Mock that scanner found desired classification, but is blurry
        mockDocumentScanner.respondToScan(output: makeDocumentScannerOutput(with: .idCardFront, isHighQuality: false))
        XCTAssertStateEqual(vc.state, .scanning(.front, foundClassification: .idCardFront))

        // Mock that scanner found desired classification
        mockDocumentScanner.respondToScan(output: makeDocumentScannerOutput(with: .idCardFront))
        XCTAssertStateEqual(vc.state, .scanned(.front, UIImage()))
    }

    func testAppBackgrounded() {
        // Mock that vc is scanning
        let vc = makeViewController(
            state: .scanning(.front, foundClassification: nil),
            documentType: .idCard
        )
        vc.startScanning(documentSide: .front)
        waitForCameraSessionToStart()

        // Mock that app is backgrounded
        vc.appDidEnterBackground()

        XCTAssertEqual(vc.timeoutTimer?.isValid, false)
        XCTAssertTrue(mockCameraSession.didStopSession)
        XCTAssertTrue(mockDocumentScanner.didReset)
    }

    func testAppForegrounded() {
        // Mock that vc is in background
        let vc = makeViewController(
            state: .scanning(.front, foundClassification: nil),
            documentType: .idCard
        )
        vc.appDidEnterBackground()

        // Mock that app is foregrounded
        vc.appDidEnterForeground()

        waitForCameraSessionToStart()
        XCTAssertEqual(vc.timeoutTimer?.isValid, true)
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
        XCTAssertStateEqual(vc.state, .scanning(.front, foundClassification: nil))
        XCTAssertTrue(mockDocumentUploader.didReset)
    }

    func testResetFromScanning() {
        // Mock that vc is scanning
        let vc = makeViewController(
            state: .scanning(.front, foundClassification: nil),
            documentType: .idCard
        )
        vc.startScanning(documentSide: .front)
        waitForCameraSessionToStart()

        // Reset
        vc.reset()

        // Verify VC starts scanning
        XCTAssertStateEqual(vc.state, .scanning(.front, foundClassification: nil))
        XCTAssertTrue(mockDocumentUploader.didReset)
    }
}

private extension DocumentCaptureViewControllerTest {
    func verify(
        _ vc: DocumentCaptureViewController,
        expectedState: DocumentCaptureViewController.State,
        expectedButtonState: IdentityFlowView.ViewModel.Button.State?,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertStateEqual(vc.state, expectedState, "state", file: file, line: line)
        XCTAssertEqual(vc.buttonViewModels.first?.state, expectedButtonState, "buttonState", file: file, line: line)
    }

    func grantCameraAccess(granted: Bool = true) {
        mockCameraPermissionsManager.respondToRequest(granted: granted)
        wait(for: [mockCameraPermissionsManager.didCompleteExpectation], timeout: 1)
    }

    func waitForCameraSessionToConfigure(setupResult: CameraSession.SetupResult) {
        mockCameraSession.respondToConfigureSession(setupResult: setupResult)
        wait(for: [mockCameraSession.configureSessionCompletionExp], timeout: 1)
    }

    func waitForCameraSessionToStart() {
        mockCameraSession.respondToStartSession()
        wait(for: [mockCameraSession.startSessionCompletionExp], timeout: 1)
    }

    func mockTimeoutTimer(_ vc: DocumentCaptureViewController) {
        vc.timeoutTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false, block: { _ in })
    }

    func mockCameraFrameCaptured(_ vc: DocumentCaptureViewController) {
        vc.captureOutput(
            mockVideoOutput,
            didOutput: DocumentCaptureViewControllerTest.mockSampleBuffer,
            from: mockCaptureConnection
        )
    }

    func makeViewController(
        documentType: DocumentType
    ) -> DocumentCaptureViewController {
        return .init(
            apiConfig: DocumentCaptureViewControllerTest.mockVerificationPage.documentCapture,
            documentType: documentType,
            sheetController: mockSheetController,
            cameraSession: mockCameraSession,
            cameraPermissionsManager: mockCameraPermissionsManager,
            documentUploader: mockDocumentUploader,
            documentScanner: mockDocumentScanner,
            appSettingsHelper: mockAppSettingsHelper
        )
    }

    func makeViewController(
        state: DocumentCaptureViewController.State,
        documentType: DocumentType,
        apiConfig: VerificationPageStaticContentDocumentCapturePage = DocumentCaptureViewControllerTest.mockVerificationPage.documentCapture
    ) -> DocumentCaptureViewController {
        return .init(
            apiConfig: apiConfig,
            documentType: documentType,
            initialState: state,
            sheetController: mockSheetController,
            cameraSession: mockCameraSession,
            cameraPermissionsManager: mockCameraPermissionsManager,
            documentUploader: mockDocumentUploader,
            documentScanner: mockDocumentScanner,
            appSettingsHelper: mockAppSettingsHelper
        )
    }

    func makeDocumentScannerOutput(
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
    func XCTAssertStateEqual(
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
