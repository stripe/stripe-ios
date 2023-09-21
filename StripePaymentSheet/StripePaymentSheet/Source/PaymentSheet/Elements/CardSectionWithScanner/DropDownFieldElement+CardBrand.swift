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

    enum CardBrandDropDownError: ElementValidationError {
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

    @_spi(STP) public func fetchAndUpdateCardBrands(for number: String) {
        // Only fetch card brands if we have at least 8 digits in the pan
        guard number.count >= 8 else {
            return
        }

        STPCardValidator.possibleBrands(forNumber: number) { [weak self] result in
            switch result {
            case .success(let brands):
                DispatchQueue.main.async {
                    self?.validationState = .valid
                    self?.update(items: DropdownFieldElement.items(from: brands, theme: self?.theme ?? .default))
                    // If there is only one option select it
                    if brands.count == 1 {
                        // Using 1 index as first index is a placeholder item
                        self?.selectedIndex = 1
                    }
                }
            case .failure:
                self?.validationState = .invalid(error: CardBrandDropDownError.failedToFetchBrands, shouldDisplay: true)
            }
        }
    }
}
