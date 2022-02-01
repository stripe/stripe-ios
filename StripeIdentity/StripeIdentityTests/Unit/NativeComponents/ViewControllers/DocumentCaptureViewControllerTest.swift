//
//  DocumentCaptureViewControllerTest.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 11/11/21.
//

import Foundation
import XCTest
import AVKit
@_spi(STP) import StripeCameraCore
@_spi(STP) import StripeCore
@_spi(STP) import StripeCameraCoreTestUtils
@testable import StripeIdentity

final class DocumentCaptureViewControllerTest: XCTestCase {

    let mockCameraSession = MockTestCameraSession()

    static var mockVerificationPage: VerificationPage!
    var dataStore: VerificationPageDataStore!
    var mockFlowController: VerificationSheetFlowControllerMock!
    var mockSheetController: VerificationSheetControllerMock!
    var mockDocumentUploader: DocumentUploaderMock!
    let mockDocumentScanner = DocumentScannerMock()
    let mockCameraPermissionsManager = MockCameraPermissionsManager()
    let mockAppSettingsHelper = MockAppSettingsHelper()

    let mockVideoOutput = AVCaptureVideoDataOutput()
    lazy var mockCaptureConnection = AVCaptureConnection(inputPorts: [], output: mockVideoOutput)

    static var mockPixelBuffer: CVPixelBuffer!
    static var mockSampleBuffer: CMSampleBuffer!

    let mockError = NSError(domain: "", code: 0, userInfo: nil)

    override class func setUp() {
        super.setUp()
        mockPixelBuffer = CapturedImageMock.frontDriversLicense.image.convertToPixelBuffer()
        mockSampleBuffer = CapturedImageMock.frontDriversLicense.image.convertToSampleBuffer()
        guard let mockVerificationPage = try? VerificationPageMock.response200.make() else {
            return XCTFail("Could not load VerificationPageMock")
        }
        self.mockVerificationPage = mockVerificationPage
    }

    override func setUp() {
        super.setUp()
        dataStore = .init()
        mockFlowController = .init()
        mockDocumentUploader = .init()
        mockSheetController = .init(
            ephemeralKeySecret: "",
            apiClient: IdentityAPIClientTestMock(),
            flowController: mockFlowController,
            dataStore: dataStore
        )
    }

    func testInitialStateIDCard() {
        let vc = makeViewController(documentType: .idCard)
        verify(
            vc,
            expectedState: .interstitial(.idCardFront),
            isButtonDisabled: false
        )
    }

    func testInitialStateLicense() {
        let vc = makeViewController(documentType: .drivingLicense)
        verify(
            vc,
            expectedState: .interstitial(.idCardFront),
            isButtonDisabled: false
        )
    }

    func testTransitionFromInterstitialCardFront() {
        let vc = makeViewController(state: .interstitial(.idCardFront))
        vc.buttonViewModels.first!.didTap()
        grantCameraAccess()
        waitForCameraSessionToConfigure(setupResult: .success)
        waitForCameraSessionToStart()
        verify(
            vc,
            expectedState: .scanning(.idCardFront),
            isButtonDisabled: true
        )
    }

    func testTransitionFromScanningCardFront() {
        let vc = makeViewController(state: .scanning(.idCardFront))
        // Mock timer so we can verify it was invalidated
        mockTimeoutTimer(vc)
        mockCameraFrameCaptured(vc)
        // Mock that scanner found something
        mockDocumentScanner.respondToScan(pixelBuffer: DocumentCaptureViewControllerTest.mockPixelBuffer)
        verify(
            vc,
            expectedState: .scanned(.idCardFront, UIImage()),
            isButtonDisabled: false
        )
        // Verify timeout timer was invalidated
        XCTAssertEqual(vc.timeoutTimer?.isValid, false)
        // Verify image started uploading
        XCTAssertEqual(mockDocumentUploader.uploadedSide, .front)
        XCTAssertEqual(mockDocumentUploader.uploadMethod, .autoCapture)
    }

    func testTransitionFromScannedCardFront() {
        let vc = makeViewController(state: .scanned(.idCardFront, UIImage()))
        vc.buttonViewModels.first!.didTap()
        verify(
            vc,
            expectedState: .interstitial(.idCardBack),
            isButtonDisabled: false
        )
    }

    func testTransitionFromTimeoutCardFront() {
        let vc = makeViewController(state: .timeout(.idCardFront))
        vc.buttonViewModels.last!.didTap()
        waitForCameraSessionToStart()
        verify(
            vc,
            expectedState: .scanning(.idCardFront),
            isButtonDisabled: true
        )
    }

    func testTransitionFromInterstitialCardBack() {
        let vc = makeViewController(state: .interstitial(.idCardBack))
        vc.buttonViewModels.first!.didTap()
        grantCameraAccess()
        waitForCameraSessionToConfigure(setupResult: .success)
        waitForCameraSessionToStart()
        verify(
            vc,
            expectedState: .scanning(.idCardBack),
            isButtonDisabled: true
        )
    }

    func testTransitionFromScanningCardBack() {
        let vc = makeViewController(state: .scanning(.idCardBack))
        // Mock timer so we can verify it was invalidated
        mockTimeoutTimer(vc)
        mockCameraFrameCaptured(vc)
        // Mock that scanner found something
        mockDocumentScanner.respondToScan(pixelBuffer: DocumentCaptureViewControllerTest.mockPixelBuffer)
        verify(
            vc,
            expectedState: .scanned(.idCardBack, UIImage()),
            isButtonDisabled: false
        )
        // Verify timeout timer was invalidated
        XCTAssertEqual(vc.timeoutTimer?.isValid, false)
        // Verify image started uploading
        XCTAssertEqual(mockDocumentUploader.uploadedSide, .back)
        XCTAssertEqual(mockDocumentUploader.uploadMethod, .autoCapture)
    }

    func testTransitionFromScannedCardBack() {
        let vc = makeViewController(state: .scanned(.idCardBack, UIImage()))
        vc.buttonViewModels.first!.didTap()
        verify(
            vc,
            expectedState: .saving(lastImage: UIImage()),
            isButtonDisabled: true
        )
        // Mock that upload finishes
        mockDocumentUploader.frontBackUploadPromise.resolve(with: (front: nil, back: nil))

        wait(for: [mockSheetController.didFinishSaveDataExp], timeout: 1)
        XCTAssertTrue(mockSheetController.didRequestSaveData)
    }

    func testTransitionFromTimeoutCardBack() {
        let vc = makeViewController(state: .timeout(.idCardBack))
        vc.buttonViewModels.last!.didTap()
        waitForCameraSessionToStart()
        verify(
            vc,
            expectedState: .scanning(.idCardBack),
            isButtonDisabled: true
        )
    }

    func testInitialStatePassport() {
        let vc = makeViewController(documentType: .passport)
        verify(
            vc,
            expectedState: .interstitial(.passport),
            isButtonDisabled: false
        )
    }

    func testTransitionFromInterstitialPassport() {
        let vc = makeViewController(state: .interstitial(.passport))
        vc.buttonViewModels.first!.didTap()
        grantCameraAccess()
        waitForCameraSessionToConfigure(setupResult: .success)
        waitForCameraSessionToStart()
        verify(
            vc,
            expectedState: .scanning(.passport),
            isButtonDisabled: true
        )
    }

    func testTransitionFromScanningPassport() {
        let vc = makeViewController(state: .scanning(.passport))
        // Mock timer so we can verify it was invalidated
        mockTimeoutTimer(vc)
        mockCameraFrameCaptured(vc)
        // Mock that scanner found something
        mockDocumentScanner.respondToScan(pixelBuffer: DocumentCaptureViewControllerTest.mockPixelBuffer)
        verify(
            vc,
            expectedState: .scanned(.passport, UIImage()),
            isButtonDisabled: false
        )
        // Verify timeout timer was invalidated
        XCTAssertEqual(vc.timeoutTimer?.isValid, false)
        // Verify image started uploading
        XCTAssertEqual(mockDocumentUploader.uploadedSide, .front)
        XCTAssertEqual(mockDocumentUploader.uploadMethod, .autoCapture)
    }

    func testTransitionFromScannedPassport() {
        let vc = makeViewController(state: .scanned(.passport, UIImage()))
        vc.buttonViewModels.first!.didTap()
        verify(
            vc,
            expectedState: .saving(lastImage: UIImage()),
            isButtonDisabled: true
        )
        // Mock that upload finishes
        mockDocumentUploader.frontBackUploadPromise.resolve(with: (front: nil, back: nil))

        wait(for: [mockSheetController.didFinishSaveDataExp], timeout: 1)
        XCTAssertTrue(mockSheetController.didRequestSaveData)
    }

    func testTransitionFromTimeoutPassport() {
        let vc = makeViewController(state: .timeout(.passport))
        vc.buttonViewModels.last!.didTap()
        waitForCameraSessionToStart()
        verify(
            vc,
            expectedState: .scanning(.passport),
            isButtonDisabled: true
        )
    }

    func testSaveDataAndTransition() {
        let mockCombinedFileData = VerificationPageDataUpdateMock.default.collectedData.idDocument.map { (front: $0.front!, back: $0.back!) }!
        let mockBackImage = UIImage()
        let mockLastClassification = DocumentScanner.Classification.idCardBack

        // Mock that file has been captured and upload has begun
        let vc = makeViewController(documentType: .drivingLicense)
        mockDocumentUploader.frontBackUploadPromise.resolve(with: mockCombinedFileData)

        // Request to save data
        vc.saveDataAndTransitionToNextScreen(lastClassification: mockLastClassification, lastImage: mockBackImage)

        // Verify data saved and transitioned to next screen
        wait(for: [mockSheetController.didFinishSaveDataExp, mockFlowController.didTransitionToNextScreenExp], timeout: 1)

        // Verify state
        verify(
            vc,
            expectedState: .scanned(mockLastClassification, mockBackImage),
            isButtonDisabled: false
        )
    }

    func testRequestCameraAccessDenied() {
        let vc = makeViewController(state: .interstitial(.idCardFront))
        vc.buttonViewModels.first!.didTap()

        // Deny access
        grantCameraAccess(granted: false)

        // Verify no camera access state
        verify(
            vc,
            expectedState: .noCameraAccess,
            isButtonDisabled: false
        )
    }

    func testCameraSessionFailedConfigure() {
        let vc = makeViewController(state: .interstitial(.idCardFront))
        vc.buttonViewModels.first!.didTap()
        grantCameraAccess()

        // Mock that the camera session failed to get configured
        waitForCameraSessionToConfigure(setupResult: .failed(error: mockError))

        verify(
            vc,
            expectedState: .cameraError,
            isButtonDisabled: nil
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
            isButtonDisabled: false
        )
    }

    func testFileUploadButtonCameraAccess() {
        let vc = makeViewController(state: .noCameraAccess)
        vc.buttonViewModels.first!.didTap()
        // Should open File Upload screen
        XCTAssertIs(mockFlowController.replacedWithViewController as Any, DocumentFileUploadViewController.self)
    }

    func testFileUploadButtonTimeout() {
        let vc = makeViewController(state: .timeout(.idCardFront))
        vc.buttonViewModels.first!.didTap()
        // Should open File Upload screen
        XCTAssertIs(mockFlowController.replacedWithViewController as Any, DocumentFileUploadViewController.self)
    }

    func testNoCameraAccessButtonsReqLiveCapture() throws {
        // If requireLiveCapture is enabled, upload action should not display
        // without camera access
        let mockResponse = try VerificationPageMock.response200.makeWithModifications(requireLiveCapture: true)
        let vc = makeViewController(
            state: .noCameraAccess,
            apiConfig: mockResponse.documentCapture
        )
        XCTAssertEqual(vc.buttonViewModels.count, 1)
    }

    func testNoCameraAccessButtonsNoReqLiveCapture() throws {
        // If requireLiveCapture is disabled, upload action **should** display
        // without camera access
        let mockResponse = try VerificationPageMock.response200.makeWithModifications(requireLiveCapture: false)
        let vc = makeViewController(
            state: .noCameraAccess,
            apiConfig: mockResponse.documentCapture
        )
        XCTAssertEqual(vc.buttonViewModels.count, 2)
    }

    func testScanningTimeout() {
        let vc = makeViewController(state: .scanning(.idCardFront))
        let startedScanningDate = Date()
        // Mock that scanner is scanning
        vc.startScanning(for: .idCardFront)
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
            expectedState: .timeout(.idCardFront),
            isButtonDisabled: false
        )
        XCTAssertTrue(mockDocumentScanner.didCancel)
    }

    func testAppBackgrounded() {
        // Mock that vc is scanning
        let vc = makeViewController(state: .scanning(.idCardFront))
        vc.startScanning(for: .idCardFront)
        waitForCameraSessionToStart()

        // Mock that app is backgrounded
        vc.appDidEnterBackground()

        XCTAssertTrue(mockCameraSession.didStopSession)
        XCTAssertTrue(mockDocumentScanner.didCancel)
        XCTAssertEqual(vc.timeoutTimer?.isValid, false)
    }

    func testAppForegrounded() {
        // Mock that vc is in background
        let vc = makeViewController(state: .scanning(.idCardFront))
        vc.appDidEnterBackground()

        // Mock that app is foregrounded
        vc.appDidEnterForeground()

        waitForCameraSessionToStart()
        XCTAssertEqual(vc.timeoutTimer?.isValid, true)
    }
}

private extension DocumentCaptureViewControllerTest {
    func verify(
        _ vc: DocumentCaptureViewController,
        expectedState: DocumentCaptureViewController.State,
        isButtonDisabled: Bool?,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertStateEqual(vc.state, expectedState, "state", file: file, line: line)
        XCTAssertEqual(vc.buttonViewModels.first?.isEnabled, isButtonDisabled.map { !$0 }, "isButtonDisabled", file: file, line: line)
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
        documentType: DocumentCaptureViewController.DocumentType
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
        apiConfig: VerificationPageStaticContentDocumentCapturePage = DocumentCaptureViewControllerTest.mockVerificationPage.documentCapture
    ) -> DocumentCaptureViewController {
        return .init(
            apiConfig: apiConfig,
            documentType: .idCard,
            initialState: state,
            sheetController: mockSheetController,
            cameraSession: mockCameraSession,
            cameraPermissionsManager: mockCameraPermissionsManager,
            documentUploader: mockDocumentUploader,
            documentScanner: mockDocumentScanner,
            appSettingsHelper: mockAppSettingsHelper
        )
    }

    /// Same as XCTAssertEqual but ignores image pointer discrepencies
    func XCTAssertStateEqual(
        _ lhs: DocumentCaptureViewController.State,
        _ rhs: DocumentCaptureViewController.State,
        _ message: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let isEqual: Bool
        switch (lhs, rhs) {
        case (.interstitial(let left), .interstitial(let right)),
             (.scanning(let left), .scanning(let right)),
             (.scanned(let left, _), .scanned(let right, _)),
             (.timeout(let left), .timeout(let right)):
            isEqual = (left == right)
        case (.saving, .saving),
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
