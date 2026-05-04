//
//  ComplianceRegulation.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 5/4/26.
//

import Foundation

/// The regulation requiring a compliance identifier.
@_spi(CryptoOnrampAlpha)
public enum ComplianceRegulation: String, Codable, Equatable, Hashable {

    /// Common Reporting Standard (CRS) and Crypto-Asset Reporting Framework (CARF).
    case euCARF = "eu_carf"

    /// Markets in Crypto-Assets Regulation (MICA).
    case euMICA = "eu_mica"
}
