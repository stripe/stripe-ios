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
}
