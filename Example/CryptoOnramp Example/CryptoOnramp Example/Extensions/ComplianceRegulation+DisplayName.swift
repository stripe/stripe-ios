//
//  ComplianceRegulation+DisplayName.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 5/4/26.
//

@_spi(CryptoOnrampAlpha)
import StripeCryptoOnramp

extension ComplianceRegulation {

    /// A human-readable display name for known compliance regulations.
    var displayName: String {
        switch self {
        case .euCARF:
            return "CRS/CARF"
        case .euMiCA:
            return "MiCA"
        }
    }
}
