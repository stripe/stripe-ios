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

    @_spi(STP) public static func makeCardBrandDropdown(
        theme: ElementsUITheme
    ) -> DropdownFieldElement {
        return DropdownFieldElement(
            items: items(from: Set<STPCardBrand>()),
            defaultIndex: 0,
            label: nil,
            theme: theme
        )
    }

    @_spi(STP) public static func items(from cardBrands: Set<STPCardBrand>) -> [DropdownItem] {
        var dropDownItems: [DropdownFieldElement.DropdownItem] = [.init(pickerDisplayName: NSAttributedString(string: "Select card brand (optional)"),
                                                                        labelDisplayName: STPCardBrand.unknown.brandIconAttributedString,
                                                                        accessibilityValue: "Select card brand (optional)",
                                                                        rawData: "-1",
                                                                        isPlaceholder: true), ]
        dropDownItems += cardBrands.sorted().map {
            let brandName = STPCardBrandUtilities.stringFrom($0) ?? ""

            let displayText = NSMutableAttributedString(attributedString: ($0.brandIconAttributedString))
            displayText.append(NSAttributedString(string: " " + brandName))

            return .init(pickerDisplayName: displayText,
                         labelDisplayName: $0.brandIconAttributedString,
                         accessibilityValue: brandName,
                         rawData: "\($0.rawValue)")
        }

        return dropDownItems
    }
}

extension STPCardBrand: Comparable {
    public static func < (lhs: StripePayments.STPCardBrand, rhs: StripePayments.STPCardBrand) -> Bool {
        return (STPCardBrandUtilities.stringFrom(lhs) ?? "") >= (STPCardBrandUtilities.stringFrom(rhs) ?? "")
    }

    var brandIconAttributedString: NSAttributedString {
        let brandImageAttachment = NSTextAttachment()
        brandImageAttachment.image = STPImageLibrary.cardBrandImage(
            for: self
        )

        return NSAttributedString(attachment: brandImageAttachment)
    }
}
