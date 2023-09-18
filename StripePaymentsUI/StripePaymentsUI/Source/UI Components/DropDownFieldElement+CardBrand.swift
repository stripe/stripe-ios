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

    @_spi(STP) public static func makeCardBrandDropdown(theme: ElementsUITheme) -> DropdownFieldElement {
        return DropdownFieldElement(
            items: items(from: Set<STPCardBrand>()),
            defaultIndex: 0,
            label: nil,
            theme: theme
        )
    }

    @_spi(STP) public static func items(from cardBrands: Set<STPCardBrand>) -> [DropdownItem] {
        let placeholderItem = DropdownItem(
            pickerDisplayName: NSAttributedString(string: Constants.selectCardBrandPlaceholder),
            labelDisplayName: STPCardBrand.unknown.brandIconAttributedString,
            accessibilityValue: Constants.selectCardBrandPlaceholder,
            rawData: Constants.unknownBrandPlaceholder,
            isPlaceholder: true
        )

        let cardBrandItems = cardBrands.sorted().map { $0.cardBrandItem }

        return [placeholderItem] + cardBrandItems
    }
}

extension STPCardBrand: Comparable {
    public static func < (lhs: StripePayments.STPCardBrand, rhs: StripePayments.STPCardBrand) -> Bool {
        return (STPCardBrandUtilities.stringFrom(lhs) ?? "") < (STPCardBrandUtilities.stringFrom(rhs) ?? "")
    }

    var brandIconAttributedString: NSAttributedString {
        let brandImageAttachment = NSTextAttachment()
        brandImageAttachment.image = STPImageLibrary.cardBrandImage(for: self)

        return NSAttributedString(attachment: brandImageAttachment)
    }

    var cardBrandItem: DropdownFieldElement.DropdownItem {
        let brandName = STPCardBrandUtilities.stringFrom(self) ?? ""

        let displayText = NSMutableAttributedString(attributedString: self.brandIconAttributedString)
        displayText.append(NSAttributedString(string: " " + brandName))

        return DropdownFieldElement.DropdownItem(
            pickerDisplayName: displayText,
            labelDisplayName: self.brandIconAttributedString,
            accessibilityValue: brandName,
            rawData: "\(self.rawValue)"
        )
    }
}
