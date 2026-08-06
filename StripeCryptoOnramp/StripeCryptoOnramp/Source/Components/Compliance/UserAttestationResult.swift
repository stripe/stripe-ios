//
//  UserAttestationResult.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 4/22/26.
//

import Foundation

/// The result of presenting the user attestation.
@_spi(CryptoOnrampAlpha)
public enum UserAttestationResult: Equatable {

    /// The customer accepted the attestation.
    case confirmed

    /// The customer dismissed the attestation without accepting.
    case canceled
}
