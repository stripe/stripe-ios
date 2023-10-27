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

    @_spi(STP) public static func makeCardBrandDropdown(cardBrands: Set<STPCardBrand> = Set<STPCardBrand>(), theme: ElementsUITheme = .default, maxWidth: CGFloat? = nil, hasPadding: Bool = true) -> DropdownFieldElement {
        return DropdownFieldElement(
            items: items(from: cardBrands, theme: theme, maxWidth: maxWidth),
            defaultIndex: 0,
            label: nil,
            theme: theme,
            hasPadding: hasPadding,
            isOptional: true
        )
    }

    @_spi(STP) public static func items(from cardBrands: Set<STPCardBrand>, theme: ElementsUITheme, maxWidth: CGFloat? = nil) -> [DropdownItem] {
        let placeholderItem = DropdownItem(
            pickerDisplayName: NSAttributedString(string: .Localized.card_brand_dropdown_placeholder),
            labelDisplayName: STPCardBrand.unknown.brandIconAttributedString(theme: theme, maxWidth: maxWidth),
            accessibilityValue: .Localized.card_brand_dropdown_placeholder,
            rawData: "-1",
            isPlaceholder: true
        )

        let cardBrandItems = cardBrands.sorted().map { $0.cardBrandItem(theme: theme, maxWidth: maxWidth) }
        return [placeholderItem] + cardBrandItems
    }
}
