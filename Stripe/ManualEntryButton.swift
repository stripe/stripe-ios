//
//  ManualEntryButton.swift
//  StripeiOS
//
//  Created by Nick Porter on 6/8/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit
@_spi(STP) import StripeCore

extension UIButton {
    
    static func makeManualEntryButton(appearance: PaymentSheet.Appearance) -> UIButton {
        let button = UIButton(type: .system)
        // TODO(porter) Style button background color for Appearance APIs and confirm other variables used
        button.backgroundColor = .manualEntryBackgroundColor
        button.titleLabel?.font = appearance.scaledFont(for: appearance.font.base.regular, style: .subheadline, maximumPointSize: 20)
        button.tintColor = appearance.colors.primary
        
        let underlineAttribute = [NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.union(.patternDot).rawValue,
                                  NSAttributedString.Key.underlineColor: appearance.colors.textSecondary] as [NSAttributedString.Key : Any]
        let underlineAttributedString = NSAttributedString(string: .Localized.enter_address_manually, attributes: underlineAttribute)
        button.setAttributedTitle(underlineAttributedString, for: .normal)
        button.titleLabel?.sizeToFit()
        
        if let titleLabelHeight = button.titleLabel?.frame.size.height {
            button.frame.size.height = titleLabelHeight * 2.5
        }
        
        return button
    }
}

private extension UIColor {
    static var manualEntryBackgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.00)
}
