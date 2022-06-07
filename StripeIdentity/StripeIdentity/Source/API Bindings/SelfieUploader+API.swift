//
//  SelfieUploader+API.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 6/2/22.
//

import Foundation
import UIKit
@_spi(STP) import StripeCameraCore

extension IdentityImageUploader.Configuration {
    init(from selfiePageConfig: StripeAPI.VerificationPageStaticContentSelfiePage) {
        self.init(
            filePurpose: selfiePageConfig.filePurpose,
            highResImageCompressionQuality: selfiePageConfig.highResImageCompressionQuality,
            highResImageCropPadding: selfiePageConfig.highResImageCropPadding,
            highResImageMaxDimension: selfiePageConfig.highResImageMaxDimension,
            lowResImageCompressionQuality: selfiePageConfig.lowResImageCompressionQuality,
            lowResImageMaxDimension: selfiePageConfig.lowResImageMaxDimension
        )
    }
}
