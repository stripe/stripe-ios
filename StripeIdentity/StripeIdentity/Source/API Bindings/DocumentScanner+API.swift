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
                / 1000
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
