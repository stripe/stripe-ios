//
//  TermsAndConditionsResult.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 8/27/26.
//

import Foundation

/// The result of checking for and presenting terms and conditions.
@_spi(CryptoOnrampAlpha)
public enum TermsAndConditionsResult: Equatable {

    /// The customer accepted the current terms and conditions.
    case accepted

    /// The customer had already accepted the current terms and conditions, or wasn't required to accept them, so no UI was presented.
    case notRequired

    /// The customer dismissed the terms and conditions without accepting.
    case canceled
}
