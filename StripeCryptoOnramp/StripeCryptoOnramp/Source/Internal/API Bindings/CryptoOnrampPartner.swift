//
//  CryptoOnrampPartner.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 9/1/26.
//

import Foundation

/// A partner whose declarations can be presented by the CryptoOnramp SDK.
enum CryptoOnrampPartner: String, Encodable {

    /// The Swapped liquidity provider.
    case swapped
}
