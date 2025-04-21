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

    @_spi(STP) public static func makeCardBrandDropdown(cardBrands: Set<STPCardBrand> = Set<STPCardBrand>(),
                                                        disallowedCardBrands: Set<STPCardBrand> = Set<STPCardBrand>(),
                                                        theme: ElementsAppearance = .default,
                                                        includePlaceholder: Bool = true,
                                                        maxWidth: CGFloat? = nil,
                                                        hasPadding: Bool = true) -> DropdownFieldElement {
        let dropDown = DropdownFieldElement(
            items: items(from: cardBrands, disallowedCardBrands: disallowedCardBrands, theme: theme, includePlaceholder: includePlaceholder, maxWidth: maxWidth),
            defaultIndex: 0,
            label: nil,
            theme: theme,
            hasPadding: hasPadding,
            isOptional: true
        )
        dropDown.view.accessibilityIdentifier = "Card Brand Dropdown"
        return dropDown
    }

    @_spi(STP) public static func items(from cardBrands: Set<STPCardBrand>, disallowedCardBrands: Set<STPCardBrand>, theme: ElementsAppearance, includePlaceholder: Bool = true, maxWidth: CGFloat? = nil) -> [DropdownItem] {
        let placeholderItem = DropdownItem(
            pickerDisplayName: NSAttributedString(string: .Localized.card_brand_dropdown_placeholder),
            labelDisplayName: STPCardBrand.unknown.brandIconAttributedString(theme: theme, maxWidth: maxWidth),
            accessibilityValue: .Localized.card_brand_dropdown_placeholder,
            rawData: STPCardBrandUtilities.apiValue(from: .unknown),
            isPlaceholder: true
        )

        let cardBrandItems = cardBrands.sorted().map { $0.cardBrandItem(theme: theme, isDisallowed: disallowedCardBrands.contains($0), maxWidth: maxWidth) }

        return includePlaceholder ? [placeholderItem] + cardBrandItems : cardBrandItems
    }
}
