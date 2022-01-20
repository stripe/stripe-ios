//
//  DocumentCaptureViewControllerTest.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 11/11/21.
//

import Foundation
import XCTest
import AVKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeCameraCoreTestUtils
@testable import StripeIdentity

final class DocumentCaptureViewControllerTest: XCTestCase {

    let mockCameraFeed = MockIdentityDocumentCameraFeed(
        imageFiles: CapturedImageMock.frontDriversLicense.url
    )

    static var mockVerificationPage: VerificationPage!
    var dataStore: VerificationPageDataStore!
    var mockFlowController: VerificationSheetFlowControllerMock!
    var mockSheetController: VerificationSheetControllerMock!
    var mockDocumentUploader: DocumentUploaderMock!
    let mockDocumentScanner = DocumentScannerMock()
    let mockCameraPermissionsManager = MockCameraPermissionsManager()
    let mockAppSettingsHelper = MockAppSettingsHelper()

    static var mockPixelBuffer: CVPixelBuffer!

    override class func setUp() {
        super.setUp()
        mockPixelBuffer = CapturedImageMock.frontDriversLicense.image.convertToBuffer()
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
            isButtonDisabled: false,
            isScanning: false
        )
    }

    func testInitialStateLicense() {
        let vc = makeViewController(documentType: .drivingLicense)
        verify(
            vc,
            expectedState: .interstitial(.idCardFront),
            isButtonDisabled: false,
            isScanning: false
        )
    }

    func testTransitionFromInterstitialCardFront() {
        let vc = makeViewController(state: .interstitial(.idCardFront))
        vc.buttonViewModels.first!.didTap()
        grantCameraAccess()
        verify(
            vc,
            expectedState: .scanning(.idCardFront),
            isButtonDisabled: true,
            isScanning: true
        )
    }

    func testTransitionFromScanningCardFront() {
        let vc = makeViewController(state: .scanning(.idCardFront))
        // Mock that scanner is scanning
        vc.startScanning(for: .idCardFront)
        // Mock that scanner found something
        mockDocumentScanner.scanImagePromise.resolve(with: DocumentCaptureViewControllerTest.mockPixelBuffer)
        verify(
            vc,
            expectedState: .scanned(.idCardFront, UIImage()),
            isButtonDisabled: false,
            isScanning: false
        )
        // Verify image started uploading
        XCTAssertTrue(mockDocumentUploader.didUploadImages)
    }

    func testTransitionFromScannedCardFront() {
        let vc = makeViewController(state: .scanned(.idCardFront, UIImage()))
        vc.buttonViewModels.first!.didTap()
        verify(
            vc,
            expectedState: .interstitial(.idCardBack),
            isButtonDisabled: false,
            isScanning: false
        )
    }

    func testTransitionFromTimeoutCardFront() {
        let vc = makeViewController(state: .timeout(.idCardFront))
        vc.buttonViewModels.last!.didTap()
        verify(
            vc,
            expectedState: .scanning(.idCardFront),
            isButtonDisabled: true,
            isScanning: true
        )
    }

    func testTransitionFromInterstitialCardBack() {
        let vc = makeViewController(state: .interstitial(.idCardBack))
        vc.buttonViewModels.first!.didTap()
        grantCameraAccess()
        verify(
            vc,
            expectedState: .scanning(.idCardBack),
            isButtonDisabled: true,
            isScanning: true
        )
    }

    func testTransitionFromScanningCardBack() {
        let vc = makeViewController(state: .scanning(.idCardBack))
        // Mock that scanner is scanning
        vc.startScanning(for: .idCardBack)
        // Mock that scanner found something
        mockDocumentScanner.scanImagePromise.resolve(with: DocumentCaptureViewControllerTest.mockPixelBuffer)
        verify(
            vc,
            expectedState: .scanned(.idCardBack, UIImage()),
            isButtonDisabled: false,
            isScanning: false
        )
        // Verify timeout timer was invalidated
        XCTAssertEqual(vc.timeoutTimer?.isValid, false)
        // Verify image started uploading
        XCTAssertTrue(mockDocumentUploader.didUploadImages)
    }

    func testTransitionFromScannedCardBack() {
        let vc = makeViewController(state: .scanned(.idCardBack, UIImage()))
        vc.buttonViewModels.first!.didTap()
        verify(
            vc,
            expectedState: .saving(lastImage: UIImage()),
            isButtonDisabled: true,
            isScanning: false
        )
        // Mock that upload finishes
        mockDocumentUploader.frontBackUploadPromise.resolve(with: (front: nil, back: nil))

        wait(for: [mockSheetController.didFinishSaveDataExp], timeout: 1)
        XCTAssertTrue(mockSheetController.didRequestSaveData)
    }

    func testTransitionFromTimeoutCardBack() {
        let vc = makeViewController(state: .timeout(.idCardBack))
        vc.buttonViewModels.last!.didTap()
        verify(
            vc,
            expectedState: .scanning(.idCardBack),
            isButtonDisabled: true,
            isScanning: true
        )
    }

    func testInitialStatePassport() {
        let vc = makeViewController(documentType: .passport)
        verify(
            vc,
            expectedState: .interstitial(.passport),
            isButtonDisabled: false,
            isScanning: false
        )
    }

    func testTransitionFromInterstitialPassport() {
        let vc = makeViewController(state: .interstitial(.passport))
        vc.buttonViewModels.first!.didTap()
        grantCameraAccess()
        verify(
            vc,
            expectedState: .scanning(.passport),
            isButtonDisabled: true,
            isScanning: true
        )
    }

    func testTransitionFromScanningPassport() {
        let vc = makeViewController(state: .scanning(.passport))
        // Mock that scanner is scanning
        vc.startScanning(for: .passport)
        // Mock that scanner found something
        mockDocumentScanner.scanImagePromise.resolve(with: DocumentCaptureViewControllerTest.mockPixelBuffer)
        verify(
            vc,
            expectedState: .scanned(.passport, UIImage()),
            isButtonDisabled: false,
            isScanning: false
        )
        // Verify timeout timer was invalidated
        XCTAssertEqual(vc.timeoutTimer?.isValid, false)
        // Verify image started uploading
        XCTAssertTrue(mockDocumentUploader.didUploadImages)
    }

    func testTransitionFromScannedPassport() {
        let vc = makeViewController(state: .scanned(.passport, UIImage()))
        vc.buttonViewModels.first!.didTap()
        verify(
            vc,
            expectedState: .saving(lastImage: UIImage()),
            isButtonDisabled: true,
            isScanning: false
        )
        // Mock that upload finishes
        mockDocumentUploader.frontBackUploadPromise.resolve(with: (front: nil, back: nil))

        wait(for: [mockSheetController.didFinishSaveDataExp], timeout: 1)
        XCTAssertTrue(mockSheetController.didRequestSaveData)
    }

    func testTransitionFromTimeoutPassport() {
        let vc = makeViewController(state: .timeout(.passport))
        vc.buttonViewModels.last!.didTap()
        verify(
            vc,
            expectedState: .scanning(.passport),
            isButtonDisabled: true,
            isScanning: true
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
        vc.saveDataAndTransition(lastClassification: mockLastClassification, lastImage: mockBackImage)

        // Verify data saved and transitioned to next screen
        wait(for: [mockSheetController.didFinishSaveDataExp, mockFlowController.didTransitionToNextScreenExp], timeout: 1)

        // Verify state
        verify(
            vc,
            expectedState: .scanned(mockLastClassification, mockBackImage),
            isButtonDisabled: false,
            isScanning: false
        )
    }

    func testRequestCameraAccessGranted() {
        let vc = makeViewController(state: .interstitial(.idCardFront))
        vc.buttonViewModels.first!.didTap()

        // Should trigger camera access request
        XCTAssertTrue(mockCameraPermissionsManager.didRequestCameraAccess)

        // Verify VC is still in `interstitial` state until camera access is granted/denied
        verify(
            vc,
            expectedState: .interstitial(.idCardFront),
            isButtonDisabled: false,
            isScanning: false
        )

        // Grant access
        mockCameraPermissionsManager.respondToRequest(granted: true)
        wait(for: [mockCameraPermissionsManager.didCompleteExpectation], timeout: 1)

        // Verify VC starts scanning
        verify(
            vc,
            expectedState: .scanning(.idCardFront),
            isButtonDisabled: true,
            isScanning: true
        )
    }

    func testRequestCameraAccessDenied() {
        let vc = makeViewController(state: .interstitial(.idCardFront))
        vc.buttonViewModels.first!.didTap()

        // Deny access
        mockCameraPermissionsManager.respondToRequest(granted: false)
        wait(for: [mockCameraPermissionsManager.didCompleteExpectation], timeout: 1)

        // Verify no camera access state
        verify(
            vc,
            expectedState: .noCameraAccess,
            isButtonDisabled: false,
            isScanning: false
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
            isButtonDisabled: false,
            isScanning: false
        )
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
            isButtonDisabled: false,
            isScanning: false
        )
        XCTAssertTrue(mockDocumentScanner.didCancel)
    }
}

private extension DocumentCaptureViewControllerTest {
    func verify(
        _ vc: DocumentCaptureViewController,
        expectedState: DocumentCaptureViewController.State,
        isButtonDisabled: Bool,
        isScanning: Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(vc.state, expectedState, "state", file: file, line: line)
        XCTAssertEqual(vc.buttonViewModels.first?.isEnabled, !isButtonDisabled, "isButtonDisabled", file: file, line: line)
        if isScanning {
            wait(for: [mockDocumentScanner.isScanningExp], timeout: 1)
        }
    }

    func grantCameraAccess() {
        mockCameraPermissionsManager.respondToRequest(granted: true)
        wait(for: [mockCameraPermissionsManager.didCompleteExpectation], timeout: 1)
    }

    func makeViewController(
        documentType: DocumentCaptureViewController.DocumentType
    ) -> DocumentCaptureViewController {
        return .init(
            apiConfig: DocumentCaptureViewControllerTest.mockVerificationPage.documentCapture,
            documentType: documentType,
            sheetController: mockSheetController,
            cameraFeed: mockCameraFeed,
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
            cameraFeed: mockCameraFeed,
            cameraPermissionsManager: mockCameraPermissionsManager,
            documentUploader: mockDocumentUploader,
            documentScanner: mockDocumentScanner,
            appSettingsHelper: mockAppSettingsHelper
        )
    }
}

extension DocumentCaptureViewController.State: Equatable {
    public static func == (lhs: DocumentCaptureViewController.State, rhs: DocumentCaptureViewController.State) -> Bool {
        switch (lhs, rhs) {
        case (.interstitial(let left), .interstitial(let right)),
             (.scanning(let left), .scanning(let right)),
             (.scanned(let left, _), .scanned(let right, _)),
             (.timeout(let left), .timeout(let right)):
            return left == right
        case (.saving, .saving),
             (.noCameraAccess, .noCameraAccess):
            return true
        default:
            return false
        }
    }
}
