//
//  Image.swift
//  StripeCryptoOnramp
//
//  Created by Mat Schmid on 8/25/25.
//

import Foundation
@_spi(STP) import StripeUICore

/// The canonical set of all image files in the `StripeCryptoOnramp` module.
@_spi(STP) public enum Image: String, CaseIterable, ImageMaker {
    @_spi(STP) public typealias BundleLocator = StripeCryptoOnrampBundleLocator

    case wallet = "wallet"
}
