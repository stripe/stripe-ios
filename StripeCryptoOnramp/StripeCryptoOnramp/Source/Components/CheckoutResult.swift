//
//  CheckoutResult.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 8/18/25.
//

import Foundation

@_spi(CryptoOnrampSDKPreview)
public enum CheckoutResult {

    /// The checkout was completed successfully.
    case completed

    /// The checkout failed with an error.
    case failed(Error)
}
