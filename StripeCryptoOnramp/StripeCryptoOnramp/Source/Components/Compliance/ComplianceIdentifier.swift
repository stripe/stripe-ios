//
//  ComplianceIdentifier.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 5/4/26.
//

import Foundation

/// A compliance identifier collected for MiCA or CRS/CARF compliance.
@_spi(CryptoOnrampAlpha)
public struct ComplianceIdentifier: Codable, Equatable, Hashable {

    /// The type of identifier provided.
    public let type: ComplianceIdentifierType

    /// The identifier value.
    public let value: String

    /// Creates a `ComplianceIdentifier`.
    /// - Parameters:
    ///   - type: The type of identifier provided.
    ///   - value: The identifier value.
    public init(type: ComplianceIdentifierType, value: String) {
        self.type = type
        self.value = value
    }
}
