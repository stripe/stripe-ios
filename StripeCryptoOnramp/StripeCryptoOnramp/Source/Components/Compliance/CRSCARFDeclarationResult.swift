//
//  CRSCARFDeclarationResult.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 4/22/26.
//

import Foundation

/// The result of presenting the CRS/CARF declaration.
@_spi(CryptoOnrampAlpha)
public enum CRSCARFDeclarationResult: Equatable {

    /// The customer accepted the declaration.
    case confirmed

    /// The customer dismissed the declaration without accepting.
    case canceled
}
