//
//  Locale+extension.swift
//  StripeConnect
//
//  Created by Chris Mays on 8/22/24.
//

import Foundation
@_spi(STP) import StripeCore

extension Locale {
    /// Transforms the locale into a web locale
    var webIdentifier: String? {
        guard let languageCode else { return nil }

        return [languageCode, adjustedScriptCode, languageRegionCode]
            .compactMap { $0 }
            .joined(separator: "-")
    }

    private var languageRegionCode: String? {
        // On iOS 16+, the language can have a different region from the device
        if #available(iOS 16, *),
           let languageRegion = language.region {
            // Use language region
            return languageRegion.identifier
        }

        // Fallback to device region
        return regionCode
    }

    private var adjustedScriptCode: String? {
        // Use the system script if there is one
        if let scriptCode { return scriptCode }

        /*
         iOS drops the language script when using:
         - language=zh-Hans and region=CN
         - language=zh-Hant and region=TW or HK

         If the Chinese language script is not specified to web, it will default
         to using zh-Hans, so we need to explicitly specify one for these cases.
         */
        switch (languageCode, languageRegionCode) {
        case ("zh", "CN"):
            return "Hans"
        case ("zh", "TW"),
             ("zh", "HK"):
            return "Hant"
        default:
            return nil
        }
    }
}
