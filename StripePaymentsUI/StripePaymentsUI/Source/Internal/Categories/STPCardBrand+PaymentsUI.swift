//
//  STPCardBrand+PaymentSheet.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 9/21/23.
//

import Foundation
@_spi(STP) import StripeUICore
@_spi(STP) import StripeCore
import UIKit

extension STPCardBrand {
    func brandIconAttributedString(theme: ElementsAppearance = .default, maxWidth: CGFloat? = nil) -> NSAttributedString {
        let brandImageAttachment = NSTextAttachment()
        let image: UIImage = self == .unknown ? STPImageLibrary.cardBrandChoiceImage() : STPImageLibrary.cardBrandImage(for: self)
        brandImageAttachment.image = image
        // TODO: -3 is a hack for proper vertical alignment, investigate this
        let hackyVerticalInset: CGFloat = -3
        if let maxWidth = maxWidth {
            let widthRatio = maxWidth / image.size.width
            brandImageAttachment.bounds = .init(x: 0, y: hackyVerticalInset, width: maxWidth, height: image.size.height * widthRatio)
        } else {
            brandImageAttachment.bounds = .init(x: 0, y: hackyVerticalInset, width: image.size.width, height: image.size.height)
        }

        return NSAttributedString(attachment: brandImageAttachment)
    }

    func cardBrandItem(theme: ElementsAppearance = .default, isDisallowed: Bool, maxWidth: CGFloat? = nil) -> DropdownFieldElement.DropdownItem {
        let brandName = STPCardBrandUtilities.stringFrom(self) ?? ""

        let displayText = NSMutableAttributedString(attributedString: brandIconAttributedString(theme: theme))
        displayText.append(NSAttributedString(string: " " + brandName))
        if isDisallowed {
            displayText.append(NSAttributedString(string: " \(String.Localized.brand_not_accepted)"))
        }
        
        return DropdownFieldElement.DropdownItem(
            pickerDisplayName: displayText,
            labelDisplayName: brandIconAttributedString(theme: theme, maxWidth: maxWidth),
            accessibilityValue: brandName,
            rawData: STPCardBrandUtilities.apiValue(from: self),
            isDisabled: isDisallowed
        )
    }
}
