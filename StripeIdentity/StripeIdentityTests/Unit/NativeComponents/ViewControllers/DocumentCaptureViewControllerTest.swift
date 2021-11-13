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
@testable import StripeIdentity

final class DocumentCaptureViewControllerTest: XCTestCase {

    let mockCameraFeed = MockIdentityDocumentCameraFeed(
        imageFiles: CapturedImageMock.frontDriversLicense.url
    )

    var dataStore: VerificationSessionDataStore!
    var mockFlowController: VerificationSheetFlowControllerMock!
    var mockSheetController: VerificationSheetControllerMock!
    var mockDocumentScanner = DocumentScannerMock()

    static var mockPixelBuffer: CVPixelBuffer!

    override class func setUp() {
        super.setUp()
        mockPixelBuffer = CapturedImageMock.frontDriversLicense.image.convertToBuffer()
    }

    override func setUp() {
        super.setUp()
        dataStore = .init()
        mockFlowController = .init()
        mockSheetController = .init(
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
        vc.didTapButton()
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
            isButtonDisabled: false
        )
    }

    func testTransitionFromScannedCardFront() {
        let vc = makeViewController(state: .scanned(.idCardFront, UIImage()))
        vc.didTapButton()
        verify(
            vc,
            expectedState: .interstitial(.idCardBack),
            isButtonDisabled: false,
            isScanning: false
        )
    }

    func testTransitionFromInterstitialCardBack() {
        let vc = makeViewController(state: .interstitial(.idCardBack))
        vc.didTapButton()
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
            isButtonDisabled: false
        )
    }

    func testTransitionFromScannedCardBack() {
        let vc = makeViewController(state: .scanned(.idCardBack, UIImage()))
        vc.didTapButton()
        wait(for: [mockFlowController.didTransitionToNextScreenExp], timeout: 1)
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
        vc.didTapButton()
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
            isButtonDisabled: false
        )
    }

    func testTransitionFromScannedPassport() {
        let vc = makeViewController(state: .scanned(.passport, UIImage()))
        vc.didTapButton()
        wait(for: [mockFlowController.didTransitionToNextScreenExp], timeout: 1)
    }

    func testSaveDataAndTransition() {
        // TODO: Test that image is uploaded
        // Blocked by https://github.com/stripe-ios/stripe-ios/pull/479

        let mockFrontImage = UIImage()
        let mockBackImage = UIImage()

        let vc = makeViewController(documentType: .drivingLicense)
        vc.frontDocument = mockFrontImage
        vc.backDocument = mockBackImage

        vc.saveDataAndTransition()
        XCTAssertEqual(dataStore.frontDocumentImage, .init(image: mockFrontImage, fileId: ""))
        XCTAssertEqual(dataStore.backDocumentImage, .init(image: mockBackImage, fileId: ""))
        XCTAssertTrue(mockSheetController.didSaveData)
        wait(for: [mockFlowController.didTransitionToNextScreenExp], timeout: 1)
    }
}

private extension DocumentCaptureViewControllerTest {
    func verify(
        _ vc: DocumentCaptureViewController,
        expectedState: DocumentCaptureViewController.State,
        isButtonDisabled: Bool,
        isScanning: Bool? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(vc.state, expectedState, "state", file: file, line: line)
        XCTAssertEqual(vc.isButtonDisabled, isButtonDisabled, "isButtonDisabled", file: file, line: line)
        if let isScanning = isScanning {
            XCTAssertEqual(mockDocumentScanner.isScanning, isScanning, "isScanning", file: file, line: line)
        }
    }

    func makeViewController(
        documentType: DocumentCaptureViewController.DocumentType
    ) -> DocumentCaptureViewController {
        return .init(
            sheetController: mockSheetController,
            cameraFeed: mockCameraFeed,
            documentType: documentType,
            documentScanner: mockDocumentScanner
        )
    }

    func makeViewController(
        state: DocumentCaptureViewController.State
    ) -> DocumentCaptureViewController {
        return .init(
            initialState: state,
            sheetController: mockSheetController,
            cameraFeed: mockCameraFeed,
            documentType: .idCard,
            documentScanner: mockDocumentScanner
        )
    }
}

extension DocumentCaptureViewController.State: Equatable {
    public static func == (lhs: DocumentCaptureViewController.State, rhs: DocumentCaptureViewController.State) -> Bool {
        switch (lhs, rhs) {
        case (.interstitial(let left), .interstitial(let right)),
             (.scanning(let left), .scanning(let right)),
             (.scanned(let left, _), .scanned(let right, _)):
            return left == right
        default:
            return false
        }
    }
}
