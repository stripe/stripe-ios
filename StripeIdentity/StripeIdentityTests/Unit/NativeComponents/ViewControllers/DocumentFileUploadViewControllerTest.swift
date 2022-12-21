//
//  DocumentFileUploadViewControllerTest.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 1/18/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCameraCoreTestUtils
@_spi(STP) import StripeCore
import UIKit
import XCTest

@testable import StripeIdentity

final class DocumentFileUploadViewControllerTest: XCTestCase {

    var mockDocumentUploader: DocumentUploaderMock!
    var mockCameraPermissionsManager: MockCameraPermissionsManager!
    var mockAppSettingsHelper: MockAppSettingsHelper!
    var mockSheetController: VerificationSheetControllerMock!

    let mockImage = CapturedImageMock.frontDriversLicense.image
    let mockImageURL = CapturedImageMock.frontDriversLicense.url

    override func setUp() {
        super.setUp()

        mockDocumentUploader = .init()
        mockCameraPermissionsManager = .init()
        mockAppSettingsHelper = .init()
        mockAppSettingsHelper.canOpenAppSettings = true
        mockSheetController = .init()
    }

    func testDrivingLicenseFront() {
        let vc = makeViewController(documentType: .drivingLicense)
        // Allows front
        XCTAssertEqual(vc.viewModel.listViewModel?.items.count, 1)
        XCTAssertEqual(vc.viewModel.listViewModel?.items[0].text, "Front of driver's license")
    }

    func testDrivingLicenseBack() {
        // Mock front collected
        mockSheetController.collectedData.merge(
            VerificationPageDataUpdateMock.frontOnly.collectedData!
        )

        let vc = makeViewController(documentType: .drivingLicense)
        // Allows front and back
        XCTAssertEqual(vc.viewModel.listViewModel?.items.count, 2)
        XCTAssertEqual(vc.viewModel.listViewModel?.items[0].text, "Front of driver's license")
        XCTAssertEqual(vc.viewModel.listViewModel?.items[1].text, "Back of driver's license")

        // Verify button is only enabled after both front and back images are uploaded
        XCTAssertEqual(vc.buttonState, .disabled)
        mockDocumentUploader.backUploadStatus = .complete
        XCTAssertEqual(vc.buttonState, .disabled)
        mockDocumentUploader.frontUploadStatus = .complete
        XCTAssertEqual(vc.buttonState, .disabled)
    }

    func testIdCardFront() {
        let vc = makeViewController(documentType: .idCard)
        // Allows front
        XCTAssertEqual(vc.viewModel.listViewModel?.items.count, 1)
        XCTAssertEqual(vc.viewModel.listViewModel?.items[0].text, "Front of identity card")
    }

    func testIdCardBack() {
        // Mock front collected
        mockSheetController.collectedData.merge(
            VerificationPageDataUpdateMock.frontOnly.collectedData!
        )

        let vc = makeViewController(documentType: .idCard)
        // Allows front and back
        XCTAssertEqual(vc.viewModel.listViewModel?.items.count, 2)
        XCTAssertEqual(vc.viewModel.listViewModel?.items[0].text, "Front of identity card")
        XCTAssertEqual(vc.viewModel.listViewModel?.items[1].text, "Back of identity card")

        // Verify button is only enabled after both front and back images are uploaded
        XCTAssertEqual(vc.buttonState, .disabled)
        mockDocumentUploader.backUploadStatus = .complete
        XCTAssertEqual(vc.buttonState, .disabled)
        mockDocumentUploader.frontUploadStatus = .complete
        XCTAssertEqual(vc.buttonState, .disabled)
    }

    func testPassport() {
        let vc = makeViewController(documentType: .passport)
        // Allows only front upload
        XCTAssertEqual(vc.viewModel.listViewModel?.items[0].text, "Image of passport")

        // Verify button is enabled after front image is uploaded
        XCTAssertEqual(vc.buttonState, .disabled)
        mockDocumentUploader.frontUploadStatus = .complete
        XCTAssertEqual(vc.buttonState, .disabled)
    }

    func testAlertNoRequireLiveCapture() {
        let vc = makeViewController(documentType: .passport, requireLiveCapture: false)
        vc.didTapSelect(for: .front)
        guard let alert = vc.test_presentedViewController as? UIAlertController else {
            return XCTFail("Expected UIAlertController")
        }

        // NOTE: The photo option is not available on some simulators
        XCTAssert(Set(alert.actions.map { $0.title }).isSuperset(of: ["Photo Library", "Choose File", "Cancel"]))
    }

    func testSelectPhotoFromLibrary() {
        let vc = makeViewController(documentType: .drivingLicense)
        // Mock that user selected to upload front of document
        vc.didTapSelect(for: .front)
        // Mock that user chooses to Photo Library
        vc.selectPhotoFromLibrary()
        guard let pickerController = vc.test_presentedViewController as? UIImagePickerController
        else {
            return XCTFail("Expected UIImagePickerController")
        }
        // Mock that user selects a photo
        vc.imagePickerController(
            pickerController,
            didFinishPickingMediaWithInfo: [.originalImage: mockImage]
        )
        // Verify front upload is triggered
        XCTAssertEqual(mockDocumentUploader.uploadedSide, .front)
        XCTAssertNil(mockDocumentUploader.uploadedDocumentScannerOutput)
        XCTAssertEqual(mockDocumentUploader.uploadMethod, .fileUpload)
    }

    func testTakePhotoCameraPermissions() {
        // NOTE: The `camera` source type is not available on the simulator
        // which means the UIImagePickerController cannot be instantiated
        // for camera use. So this will only test that camera access is
        // requested.

        let vc = makeViewController(documentType: .idCard)
        // Mock that user selected to upload front of document
        vc.didTapSelect(for: .back)
        // Mock that user chooses to Take Photo
        vc.takePhoto()
        XCTAssertTrue(mockCameraPermissionsManager.didRequestCameraAccess)

        // Mock that permission is denied
        mockCameraPermissionsManager.respondToRequest(granted: false)
        wait(for: [mockCameraPermissionsManager.didCompleteExpectation], timeout: 1)

        // Verify alert is displayed directing user to App Settings
        guard let alertController = vc.test_presentedViewController as? UIAlertController else {
            return XCTFail("Expected UIAlertController")
        }
        XCTAssertEqual(alertController.actions.map { $0.title }, ["App Settings", "OK"])
    }

    func testSelectFileFromSystem() {
        let vc = makeViewController(documentType: .passport)
        // Mock that user selected to upload front of document
        vc.didTapSelect(for: .front)
        // Mock that user chooses to Select File
        vc.selectFileFromSystem()
        guard
            let documentPicker = vc.test_presentedViewController as? UIDocumentPickerViewController
        else {
            return XCTFail("Expected UIDocumentPickerViewController")
        }
        vc.documentPicker(documentPicker, didPickDocumentsAt: [mockImageURL])
        // Verify front upload is triggered
        wait(for: [mockDocumentUploader.uploadImagesExp], timeout: 1)
        XCTAssertEqual(mockDocumentUploader.uploadedSide, .front)
        XCTAssertNil(mockDocumentUploader.uploadedDocumentScannerOutput)
        XCTAssertEqual(mockDocumentUploader.uploadMethod, .fileUpload)
    }

    func testContinueButton() {
        let vc = makeViewController(documentType: .drivingLicense)

        let frontFileData = (VerificationPageDataUpdateMock.default.collectedData?.idDocumentFront)!
        let backFileData = (VerificationPageDataUpdateMock.default.collectedData?.idDocumentBack)!

        // Mock that files have been uploaded
        mockDocumentUploader.frontUploadPromise.resolve(with: frontFileData)
        mockDocumentUploader.backUploadPromise.resolve(with: backFileData)

        // mock front upload delegate
        vc.documentUploaderDidUploadFront(mockDocumentUploader)
        // click continue button to upload back
        vc.didTapContinueButton()
        // Verify data saved and transitioned to next screen
        guard case .success(let front) = mockSheetController.frontUploadedDocumentsResult else {
            return XCTFail("Expected success result")
        }
        guard case .success(let back) = mockSheetController.backUploadedDocumentsResult else {
            return XCTFail("Expected success result")
        }
        XCTAssertEqual(front, frontFileData)
        XCTAssertEqual(back, backFileData)
    }
}

extension DocumentFileUploadViewControllerTest {
    fileprivate func makeViewController(
        documentType: DocumentType,
        requireLiveCapture: Bool = false
    ) -> DocumentFileUploadViewController {
        return .init(
            documentType: documentType,
            requireLiveCapture: requireLiveCapture,
            sheetController: mockSheetController,
            documentUploader: mockDocumentUploader,
            cameraPermissionsManager: mockCameraPermissionsManager,
            appSettingsHelper: mockAppSettingsHelper
        )
    }
}
