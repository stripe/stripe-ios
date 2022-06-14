//
//  String+AutoComplete.swift
//  StripeiOS
//
//  Created by Nick Porter on 6/13/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

extension String {
    func highlightSearchString(highlightRanges: [NSValue], textStyle: UIFont.TextStyle, appearance: PaymentSheet.Appearance, isSubtitle: Bool) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: self)

        attributedString.addAttribute(
            NSAttributedString.Key.font,
            value: appearance.scaledFont(for: appearance.font.base.regular, style: textStyle, maximumPointSize: 25),
            range: (self as NSString).range(of: self))

        attributedString.addAttribute(
            NSAttributedString.Key.foregroundColor,
            value: isSubtitle ? appearance.colors.textSecondary : appearance.colors.text,
            range: (self as NSString).range(of: self))

        for highlightRange in highlightRanges {
            attributedString.addAttribute(
                NSAttributedString.Key.font,
                value: appearance.scaledFont(for: appearance.font.base.bold, style: textStyle, maximumPointSize: 25),
                range: highlightRange.rangeValue)
        }

        return attributedString
    }
}
