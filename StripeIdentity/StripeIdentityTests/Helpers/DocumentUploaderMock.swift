//
//  DocumentUploaderMock.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 12/16/21.
//

import Foundation
import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeCameraCore
@testable import StripeIdentity
import XCTest

final class DocumentUploaderMock: DocumentUploaderProtocol {
    var delegate: DocumentUploaderDelegate?

    var frontUploadStatus: DocumentUploader.UploadStatus = .notStarted
    var backUploadStatus: DocumentUploader.UploadStatus = .notStarted

    var frontBackUploadFuture: Future<CombinedFileData> {
        return frontBackUploadPromise
    }

    let frontBackUploadPromise = Promise<CombinedFileData>()

    private(set) var uploadImagesExp = XCTestExpectation(description: "Document Images uploaded")
    private(set) var uploadedSide: DocumentSide?
    private(set) var uploadedDocumentScannerOutput: DocumentScannerOutput?
    private(set) var uploadMethod: StripeAPI.VerificationPageDataDocumentFileData.FileUploadMethod?
    private(set) var didReset = false

    func uploadImages(
        for side: DocumentSide,
        originalImage: CGImage,
        documentScannerOutput: DocumentScannerOutput?,
        exifMetadata: CameraExifMetadata?,
        method: StripeAPI.VerificationPageDataDocumentFileData.FileUploadMethod
    ) {
        uploadedSide = side
        uploadedDocumentScannerOutput = documentScannerOutput
        uploadMethod = method
        uploadImagesExp.fulfill()
    }

    func reset() {
        didReset = true
    }
}
