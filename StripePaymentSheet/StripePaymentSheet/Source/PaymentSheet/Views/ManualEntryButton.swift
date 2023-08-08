//
//  ManualEntryButton.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 6/8/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

extension UIButton {

    static func makeManualEntryButton(appearance: PaymentSheet.Appearance) -> UIButton {
        let button = UIButton(type: .system)
        button.titleLabel?.font = appearance.scaledFont(for: appearance.font.base.regular, style: .subheadline, maximumPointSize: 20)
        button.tintColor = appearance.colors.primary

        button.setTitle(.Localized.enter_address_manually, for: .normal)
        button.titleLabel?.sizeToFit()

        if let titleLabelHeight = button.titleLabel?.frame.size.height {
            button.frame.size.height = titleLabelHeight * 2.25
        }

        button.backgroundColor = UIColor(dynamicProvider: { traitCollection in
            if traitCollection.isDarkMode {
                return appearance.colors.componentBackground
            }

            return appearance.colors.background.darken(by: 0.07)
        })

        return button
    }
}
