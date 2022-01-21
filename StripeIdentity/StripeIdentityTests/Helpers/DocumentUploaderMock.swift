//
//  DocumentUploaderMock.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 12/16/21.
//

import Foundation
import UIKit
@_spi(STP) import StripeCore
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
    private(set) var uploadedSide: DocumentUploader.DocumentSide?
    private(set) var uploadedDocumentBounds: CGRect?
    private(set) var uploadMethod: VerificationPageDataDocumentFileData.FileUploadMethod?

    func uploadImages(
        for side: DocumentUploader.DocumentSide,
        originalImage: CIImage,
        documentBounds: CGRect?,
        method: VerificationPageDataDocumentFileData.FileUploadMethod
    ) {
        uploadedSide = side
        uploadedDocumentBounds = documentBounds
        uploadMethod = method
        uploadImagesExp.fulfill()
    }
}
