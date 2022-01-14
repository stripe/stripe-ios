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

final class DocumentUploaderMock: DocumentUploaderProtocol {
    var frontBackUploadFuture: Future<CombinedFileData> {
        return frontBackUploadPromise
    }

    let frontBackUploadPromise = Promise<CombinedFileData>()

    private(set) var didUploadImages = false

    func uploadImages(
        for side: DocumentUploader.DocumentSide,
        originalImage: CIImage,
        documentBounds: CGRect?,
        method: VerificationPageDataDocumentFileData.FileUploadMethod
    ) {
        didUploadImages = true
    }
}
