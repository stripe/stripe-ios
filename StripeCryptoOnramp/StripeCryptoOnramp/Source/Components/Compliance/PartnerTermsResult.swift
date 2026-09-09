//
//  PartnerTermsResult.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 9/1/26.
//

import Foundation

/// The result of checking for and presenting partner terms.
@_spi(CryptoOnrampAlpha)
public enum PartnerTermsResult: Equatable {

    /// The customer accepted the current partner terms.
    case accepted

    /// The customer had already accepted the current partner terms, or wasn't required to accept them, so no UI was presented.
    case notRequired

    /// The customer dismissed the partner terms without accepting.
    case canceled
}
