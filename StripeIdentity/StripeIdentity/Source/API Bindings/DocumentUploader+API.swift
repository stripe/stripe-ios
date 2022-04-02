//
//  DocumentUploader+API.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 1/6/22.
//

import Foundation
import UIKit

extension DocumentUploader.Configuration {
    init(from capturePageConfig: VerificationPageStaticContentDocumentCapturePage) {
        self.init(
            filePurpose: capturePageConfig.filePurpose,
            highResImageCompressionQuality: capturePageConfig.highResImageCompressionQuality,
            highResImageCropPadding: capturePageConfig.highResImageCropPadding,
            highResImageMaxDimension: capturePageConfig.highResImageMaxDimension,
            lowResImageCompressionQuality: capturePageConfig.lowResImageCompressionQuality,
            lowResImageMaxDimension: capturePageConfig.lowResImageMaxDimension
        )
    }
}

extension VerificationPageDataDocumentFileData {
    init(
        documentScannerOutput: DocumentScannerOutput?,
        highResImage: String,
        lowResImage: String?,
        uploadMethod: FileUploadMethod
    ) {
        // TODO(mludowise|IDPROD-3269): Encode additional properties from scanner output
        let scores = documentScannerOutput?.idDetectorOutput.allClassificationScores
        self.init(
            backScore: scores?[.idCardBack].map { TwoDecimalFloat($0) },
            brightnessValue: nil,
            cameraLensModel: nil,
            exposureDuration: nil,
            exposureIso: nil,
            focalLength: nil,
            frontCardScore: scores?[.idCardFront].map { TwoDecimalFloat($0) },
            highResImage: highResImage,
            invalidScore: scores?[.invalid].map { TwoDecimalFloat($0) },
            iosBarcodeDecoded: nil,
            iosBarcodeSymbology: nil,
            iosTimeToFindBarcode: nil,
            isVirtualCamera: nil,
            lowResImage: lowResImage,
            passportScore: scores?[.passport].map { TwoDecimalFloat($0) },
            uploadMethod: uploadMethod,
            _additionalParametersStorage: nil
        )
    }
}
