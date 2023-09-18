//
//  DropDownFieldElement+CardBrand.swift
//  StripeUICore
//
//  Created by Nick Porter on 8/31/23.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore
import UIKit

extension DropdownFieldElement {

    struct Constants {
        static let selectCardBrandPlaceholder = "Select card brand (optional)"
        static let unknownBrandPlaceholder = "-1"
    }

    @_spi(STP) public static func makeCardBrandDropdown(theme: ElementsUITheme = .default) -> DropdownFieldElement {
        return DropdownFieldElement(
            items: items(from: Set<STPCardBrand>(), theme: theme),
            defaultIndex: 0,
            label: nil,
            theme: theme
        )
    }

    @_spi(STP) public static func items(from cardBrands: Set<STPCardBrand>, theme: ElementsUITheme) -> [DropdownItem] {
        let placeholderItem = DropdownItem(
            pickerDisplayName: NSAttributedString(string: Constants.selectCardBrandPlaceholder),
            labelDisplayName: STPCardBrand.unknown.brandIconAttributedString(theme: theme),
            accessibilityValue: Constants.selectCardBrandPlaceholder,
            rawData: Constants.unknownBrandPlaceholder,
            isPlaceholder: true
        )

        let cardBrandItems = cardBrands.sorted().map { $0.cardBrandItem(theme: theme) }

        return [placeholderItem] + cardBrandItems
    }
}

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

@_spi(STP) public extension DynamicImageView {
    static func makeUnknownCardImageView(theme: ElementsUITheme) -> DynamicImageView {
        return DynamicImageView(
            lightImage: STPImageLibrary.safeImageNamed(
                "card_unknown_updated_icon",
                darkMode: true
            ),
            darkImage: STPImageLibrary.safeImageNamed(
                "card_unknown_updated_icon",
                darkMode: false
            ),
            pairedColor: theme.colors.textFieldText
        )
    }
}

