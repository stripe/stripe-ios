//
//  DocumentUploader+API.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 1/6/22.
//

import Foundation
import UIKit
@_spi(STP) import StripeCameraCore

extension IdentityImageUploader.Configuration {
    init(from capturePageConfig: StripeAPI.VerificationPageStaticContentDocumentCapturePage) {
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

extension StripeAPI.VerificationPageDataDocumentFileData {
    init(
        documentScannerOutput: DocumentScannerOutput?,
        highResImage: String,
        lowResImage: String?,
        exifMetadata: CameraExifMetadata?,
        uploadMethod: FileUploadMethod
    ) {
        // TODO(mludowise|IDPROD-3269): Encode additional properties from scanner output
        let scores = documentScannerOutput?.idDetectorOutput.allClassificationScores
        self.init(
            backScore: scores?[.idCardBack].map { TwoDecimalFloat($0) },
            brightnessValue: exifMetadata?.brightnessValue.map { TwoDecimalFloat(double: $0) },
            cameraLensModel: exifMetadata?.lensModel,
            exposureDuration: documentScannerOutput?.cameraProperties.map {
                Int($0.exposureDuration.seconds * 1000)
            },
            exposureIso: documentScannerOutput?.cameraProperties.map {
                TwoDecimalFloat($0.exposureISO)
            },
            focalLength: exifMetadata?.focalLength.map { TwoDecimalFloat(double: $0) },
            frontCardScore: scores?[.idCardFront].map { TwoDecimalFloat($0) },
            highResImage: highResImage,
            invalidScore: scores?[.invalid].map { TwoDecimalFloat($0) },
            iosBarcodeDecoded: documentScannerOutput?.barcode?.hasBarcode,
            iosBarcodeSymbology: documentScannerOutput?.barcode?.symbology.stringValue,
            iosTimeToFindBarcode: documentScannerOutput?.barcode.map {
                Int($0.timeTryingToFindBarcode * 1000)
            },
            isVirtualCamera: documentScannerOutput?.cameraProperties?.isVirtualDevice,
            lowResImage: lowResImage,
            passportScore: scores?[.passport].map { TwoDecimalFloat($0) },
            uploadMethod: uploadMethod
        )
    }
}
