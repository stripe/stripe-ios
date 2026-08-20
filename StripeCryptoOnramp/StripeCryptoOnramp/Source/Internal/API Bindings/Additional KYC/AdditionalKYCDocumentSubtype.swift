//
//  AdditionalKYCDocumentSubtype.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 8/20/26.
//

import Foundation

/// A document subtype that can satisfy an additional KYC document requirement.
struct AdditionalKYCDocumentSubtype: Codable, Equatable {

    /// The API identifier submitted for the document subtype.
    let id: String

    /// The localized name displayed for the document subtype.
    let label: String
}
