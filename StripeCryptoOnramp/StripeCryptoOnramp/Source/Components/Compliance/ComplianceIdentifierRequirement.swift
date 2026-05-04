//
//  ComplianceIdentifierRequirement.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 5/4/26.
//

import Foundation

/// A compliance identifier the customer still needs to provide.
@_spi(CryptoOnrampAlpha)
public struct ComplianceIdentifierRequirement: Decodable, Equatable, Hashable {

    /// The type of identifier required.
    public let type: ComplianceIdentifierType

    /// The regulation requiring this identifier.
    public let regulation: ComplianceRegulation

    /// Creates a `ComplianceIdentifierRequirement`.
    /// - Parameters:
    ///   - type: The type of identifier required.
    ///   - regulation: The regulation requiring this identifier.
    public init(type: ComplianceIdentifierType, regulation: ComplianceRegulation) {
        self.type = type
        self.regulation = regulation
    }
}
