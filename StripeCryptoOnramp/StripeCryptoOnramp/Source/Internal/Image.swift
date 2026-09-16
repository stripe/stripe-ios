//
//  Image.swift
//  StripeCryptoOnramp
//
//  Created by Mat Schmid on 8/25/25.
//

import Foundation
@_spi(STP) import StripeUICore

/// The canonical set of all image files in the `StripeCryptoOnramp` module.
enum Image: String, CaseIterable, ImageMaker {
    typealias BundleLocator = StripeCryptoOnrampBundleLocator

    case linkIconSquare = "link_icon_square"
    case iconLocationPin = "icon_location_pin"
    case iconWallet = "icon_wallet"
    case iconClock = "icon_clock"
    case iconExclamationCircle = "icon_exclamation_circle"
    case iconClose = "icon_close"
}
