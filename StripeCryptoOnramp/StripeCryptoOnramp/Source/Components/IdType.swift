//
//  IdType.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 7/30/25.
//

import Foundation

/// Represents possible types of customer identification.
@_spi(CryptoOnrampSDKPreview)
public enum IdType: String, Codable, CaseIterable {
    case socialSecurityNumber = "social_security_number"
}
