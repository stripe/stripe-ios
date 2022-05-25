//
//  ConfirmButton+Link.swift
//  StripeiOS
//
//  Created by Ramon Torres on 1/12/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import UIKit

extension ConfirmButton {

    func applyLinkTheme(compact: Bool = false) {
        tintColor = .linkBrand
        font = LinkUI.font(forTextStyle: .bodyEmphasized)
        cornerRadius = LinkUI.cornerRadius
        directionalLayoutMargins = compact
            ? LinkUI.compactButtonMargins
            : LinkUI.buttonMargins

        update()
    }

}
