//
//  DocumentUploaderMock.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 12/16/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCameraCore
@_spi(STP) import StripeCore
import UIKit
import XCTest

@testable import StripeIdentity

final class DocumentUploaderMock: DocumentUploaderProtocol {
    var delegate: DocumentUploaderDelegate?

    var frontUploadStatus: DocumentUploader.UploadStatus = .notStarted
    var backUploadStatus: DocumentUploader.UploadStatus = .notStarted

    var frontUploadFuture: Future<StripeAPI.VerificationPageDataDocumentFileData>? {
        return frontUploadPromise
    }

    var backUploadFuture: Future<StripeAPI.VerificationPageDataDocumentFileData>? {
        return backUploadPromise
    }

    let frontUploadPromise = Promise<StripeAPI.VerificationPageDataDocumentFileData>()

    let backUploadPromise = Promise<StripeAPI.VerificationPageDataDocumentFileData>()

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
