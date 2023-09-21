//
//  STPCardBrand+PaymentSheet.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 9/21/23.
//

import Foundation
import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

extension STPCardBrand: Comparable {
    public static func < (lhs: StripePayments.STPCardBrand, rhs: StripePayments.STPCardBrand) -> Bool {
        return (STPCardBrandUtilities.stringFrom(lhs) ?? "") < (STPCardBrandUtilities.stringFrom(rhs) ?? "")
    }

    func brandIconAttributedString(theme: ElementsUITheme = .default) -> NSAttributedString {
        let brandImageAttachment = NSTextAttachment()
        brandImageAttachment.image = self == .unknown ? DynamicImageView.makeUnknownCardImageView(theme: theme).image : STPImageLibrary.cardBrandImage(for: self)

        return NSAttributedString(attachment: brandImageAttachment)
    }

    func cardBrandItem(theme: ElementsUITheme = .default) -> DropdownFieldElement.DropdownItem {
        let brandName = STPCardBrandUtilities.stringFrom(self) ?? ""

        let displayText = NSMutableAttributedString(attributedString: brandIconAttributedString(theme: theme))
        displayText.append(NSAttributedString(string: " " + brandName))

        return DropdownFieldElement.DropdownItem(
            pickerDisplayName: displayText,
            labelDisplayName: brandIconAttributedString(theme: theme),
            accessibilityValue: brandName,
            rawData: "\(self.rawValue)"
        )
    }
}
