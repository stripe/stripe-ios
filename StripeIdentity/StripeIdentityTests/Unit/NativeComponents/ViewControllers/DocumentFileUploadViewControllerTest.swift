//
//  DocumentFileUploadViewControllerTest.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 1/18/22.
//

import Foundation
import XCTest
import UIKit
@testable import StripeIdentity
@_spi(STP) import StripeCameraCoreTestUtils
@_spi(STP) import StripeCore

final class DocumentFileUploadViewControllerTest: XCTestCase {

    var mockDocumentUploader: DocumentUploaderMock!
    var mockCameraPermissionsManager: MockCameraPermissionsManager!
    var mockAppSettingsHelper: MockAppSettingsHelper!
    var mockAPIClient: IdentityAPIClientTestMock!
    var mockFlowController: VerificationSheetFlowControllerMock!
    var mockSheetController: VerificationSheetControllerMock!

    let mockEAK = "EAK_123"
    let mockImage = CapturedImageMock.frontDriversLicense.image
    let mockImageURL = CapturedImageMock.frontDriversLicense.url

    override func setUp() {
        super.setUp()

        mockDocumentUploader = .init()
        mockCameraPermissionsManager = .init()
        mockAppSettingsHelper = .init()
        mockAppSettingsHelper.canOpenAppSettings = true
        mockAPIClient = .init()
        mockFlowController = .init()
        mockSheetController = .init(
            ephemeralKeySecret: mockEAK,
            apiClient: mockAPIClient,
            flowController: mockFlowController,
            dataStore: VerificationPageDataStore()
        )
    }

    func testDrivingLicense() {
        let vc = makeViewController(documentType: .drivingLicense)
        // Allows both front & back upload
        XCTAssertEqual(vc.listViewModel.items.map { $0.text }, ["Front of driver's license", "Back of driver's license"])

        // Verify button is only enabled after both front and back images are uploaded
        XCTAssertFalse(vc.isButtonEnabled)
        mockDocumentUploader.backUploadStatus = .complete
        XCTAssertFalse(vc.isButtonEnabled)
        mockDocumentUploader.frontUploadStatus = .complete
        XCTAssertTrue(vc.isButtonEnabled)
    }

    func testIdCard() {
        let vc = makeViewController(documentType: .idCard)
        // Allows both front & back upload
        XCTAssertEqual(vc.listViewModel.items.map { $0.text }, ["Front of identity card", "Back of identity card"])

        // Verify button is only enabled after both front and back images are uploaded
        XCTAssertFalse(vc.isButtonEnabled)
        mockDocumentUploader.frontUploadStatus = .complete
        XCTAssertFalse(vc.isButtonEnabled)
        mockDocumentUploader.backUploadStatus = .complete
        XCTAssertTrue(vc.isButtonEnabled)
    }

    func testPassport() {
        let vc = makeViewController(documentType: .passport)
        // Allows only front upload
        XCTAssertEqual(vc.listViewModel.items.map { $0.text }, ["Image of passport"])

        // Verify button is enabled after front image is uploaded
        XCTAssertFalse(vc.isButtonEnabled)
        mockDocumentUploader.frontUploadStatus = .complete
        XCTAssertTrue(vc.isButtonEnabled)
    }

    func testAlertNoRequireLiveCapture() {
        let vc = makeViewController(documentType: .passport, requireLiveCapture: false)
        vc.didTapSelect(for: .front)
        guard let alert = vc.test_presentedViewController as? UIAlertController else {
            return XCTFail("Expected UIAlertController")
        }

        // NOTE: The photo option is not available on the simulator
        XCTAssertEqual(alert.actions.map { $0.title }, ["Photo Library", "Choose File", "Cancel"])
    }

    func testSelectPhotoFromLibrary() {
        let vc = makeViewController(documentType: .drivingLicense)
        // Mock that user selected to upload front of document
        vc.didTapSelect(for: .front)
        // Mock that user chooses to Photo Library
        vc.selectPhotoFromLibrary()
        guard let pickerController = vc.test_presentedViewController as? UIImagePickerController else {
            return XCTFail("Expected UIImagePickerController")
        }
        // Mock that user selects a photo
        vc.imagePickerController(pickerController, didFinishPickingMediaWithInfo: [.originalImage: mockImage])
        // Verify front upload is triggered
        XCTAssertEqual(mockDocumentUploader.uploadedSide, .front)
        XCTAssertNil(mockDocumentUploader.uploadedDocumentBounds)
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
        guard let documentPicker = vc.test_presentedViewController as? UIDocumentPickerViewController else {
            return XCTFail("Expected UIDocumentPickerViewController")
        }
        vc.documentPicker(documentPicker, didPickDocumentsAt: [mockImageURL])
        // Verify front upload is triggered
        wait(for: [mockDocumentUploader.uploadImagesExp], timeout: 1)
        XCTAssertEqual(mockDocumentUploader.uploadedSide, .front)
        XCTAssertNil(mockDocumentUploader.uploadedDocumentBounds)
        XCTAssertEqual(mockDocumentUploader.uploadMethod, .fileUpload)
    }

    func testContinueButton() {
        let mockCombinedFileData = VerificationPageDataUpdateMock.default.collectedData.idDocument.map { (front: $0.front!, back: $0.back!) }!
        let vc = makeViewController(documentType: .drivingLicense)

        // Mock that files have been uploaded
        mockDocumentUploader.frontBackUploadPromise.resolve(with: mockCombinedFileData)

        vc.didTapContinueButton()
        // Verify data saved and transitioned to next screen
        wait(for: [mockSheetController.didFinishSaveDataExp, mockFlowController.didTransitionToNextScreenExp], timeout: 1)
    }
}

private extension DocumentFileUploadViewControllerTest {
    func makeViewController(
        documentType: DocumentFileUploadViewController.DocumentType,
        requireLiveCapture: Bool = false
    ) -> DocumentFileUploadViewController {
        return .init(
            documentType: documentType,
            requireLiveCapture: requireLiveCapture,
            documentUploader: mockDocumentUploader,
            cameraPermissionsManager: mockCameraPermissionsManager,
            appSettingsHelper: mockAppSettingsHelper,
            sheetController: mockSheetController
        )
    }
}
