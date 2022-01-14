//
//  DocumentUploaderConfiguration+API.swift
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
            highResImageCompressionQuality: CGFloat(
                truncating: capturePageConfig.highResImageCompressionQuality as NSDecimalNumber
            ),
            highResImageCropPadding: CGFloat(
                truncating: capturePageConfig.highResImageCropPadding as NSDecimalNumber
            ),
            highResImageMaxDimension: capturePageConfig.highResImageMaxDimension,
            lowResImageCompressionQuality: CGFloat(
                truncating: capturePageConfig.lowResImageCompressionQuality as NSDecimalNumber
            ),
            lowResImageMaxDimension: capturePageConfig.lowResImageMaxDimension
        )
    }
}
