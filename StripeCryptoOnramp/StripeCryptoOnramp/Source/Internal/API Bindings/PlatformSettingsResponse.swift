//
//  PlatformSettingsResponse.swift
//  StripeCryptoOnramp
//
//  Created by Mat Schmid on 8/19/25.
//

import Foundation

struct PlatformSettingsResponse: Codable {

    /// The publishable key associated with the current platform.
    let publishableKey: String
}
