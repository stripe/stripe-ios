//
//  ElementsUITheme+Link.swift
//  StripeiOS Tests
//
//  Created by Ramon Torres on 3/31/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import UIKit
@_spi(STP) import StripeUICore

extension ElementsUITheme {

    static func linkTheme() -> ElementsUITheme {
        var theme = ElementsUITheme.default
        theme.cornerRadius = LinkUI.mediumCornerRadius
        return theme
    }

}
