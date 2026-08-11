//
//  DocumentScanner+API.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 4/14/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
import Vision

extension DocumentScanner.Configuration {
    // TODO: collect historical data and update the threshold from server.
    static let defaultBlurThreshold: Decimal = 0.0

    init(
        from capturePageConfig: StripeAPI.VerificationPageStaticContentDocumentCapturePage,
        for locale: Locale = .autoupdatingCurrent
    ) {
        self.init(
            idDetectorMinScore: capturePageConfig.models.idDetectorMinScore.floatValue,
            idDetectorMinIOU: capturePageConfig.models.idDetectorMinIou.floatValue,
            motionBlurMinIOU: capturePageConfig.motionBlurMinIou.floatValue,
            motionBlurMinDuration: TimeInterval(capturePageConfig.motionBlurMinDuration) / 1000,
            backIdCardBarcodeSymbology: capturePageConfig.symbology(for: locale),
            backIdCardBarcodeTimeout: TimeInterval(capturePageConfig.iosIdCardBackBarcodeTimeout)
                / 1000,
            blurThreshold: (capturePageConfig.blurThreshold ?? DocumentScanner.Configuration.defaultBlurThreshold).floatValue,
            highResImageCorpPadding: capturePageConfig.highResImageCropPadding
        )
    }
}

extension StripeAPI.VerificationPageStaticContentDocumentCapturePage {
    func symbology(for locale: Locale) -> VNBarcodeSymbology? {
        guard let regionCode = locale.regionCode,
            let symbologyString = iosIdCardBackCountryBarcodeSymbologies[regionCode]
        else {
            return nil
        }

        return VNBarcodeSymbology(fromStringValue: symbologyString)
    }
}
