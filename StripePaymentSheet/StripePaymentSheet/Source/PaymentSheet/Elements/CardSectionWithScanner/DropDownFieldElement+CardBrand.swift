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

    enum Error: ElementValidationError {
        case failedToFetchBrands

        var localizedDescription: String {
            switch self {
            case .failedToFetchBrands:
                return .Localized.faild_to_fetch_card_brands
            }
        }
    }

    @_spi(STP) public static func makeCardBrandDropdown(cardBrands: Set<STPCardBrand> = Set<STPCardBrand>(), theme: ElementsUITheme = .default) -> DropdownFieldElement {
        return DropdownFieldElement(
            items: items(from: cardBrands, theme: theme),
            defaultIndex: 0,
            label: nil,
            theme: theme
        )
    }

    @_spi(STP) public static func items(from cardBrands: Set<STPCardBrand>, theme: ElementsUITheme) -> [DropdownItem] {
        let placeholderItem = DropdownItem(
            pickerDisplayName: NSAttributedString(string: .Localized.card_brand_dropdown_placeholder),
            labelDisplayName: STPCardBrand.unknown.brandIconAttributedString(theme: theme),
            accessibilityValue: .Localized.card_brand_dropdown_placeholder,
            rawData: "-1",
            isPlaceholder: true
        )

        let cardBrandItems = cardBrands.sorted().map { $0.cardBrandItem(theme: theme) }
        return [placeholderItem] + cardBrandItems
    }
}
