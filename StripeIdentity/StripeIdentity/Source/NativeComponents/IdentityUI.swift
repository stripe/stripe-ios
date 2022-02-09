//
//  IdentityUI.swift
//  StripeIdentity
//
//  Created by Jaime Park on 1/26/22.
//

import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

/// Stores common UI values used throughout Identity
struct IdentityUI {
    static var titleFont: UIFont {
        UIFont.preferredFont(forTextStyle: .title1, weight: .medium)
    }

    static var instructionsFont: UIFont {
        UIFont.preferredFont(forTextStyle: .subheadline)
    }

    static var containerColor = UIColor.dynamic(
        light: UIColor(red: 0.969, green: 0.98, blue: 0.988, alpha: 1),
        dark: UIColor(red: 0.11, green: 0.11, blue: 0.118, alpha: 1)
    )
}
