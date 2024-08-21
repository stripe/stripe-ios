//
//  Locale+extension.swift
//  StripeConnect
//
//  Created by Chris Mays on 8/22/24.
//

import Foundation
@_spi(STP) import StripeCore

extension Locale {
    /// iOS uses underscores for locale (`en_US`) but web uses hyphens (`en-US`)
    var webIdentifier: String {
        guard let region = stp_regionCode,
              let language = stp_languageCode else {
            return ""
        }
        return "\(language)-\(region)"
    }
}
