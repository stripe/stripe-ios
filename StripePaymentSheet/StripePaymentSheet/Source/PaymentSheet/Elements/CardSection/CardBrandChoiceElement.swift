//
//  CardBrandChoiceElement.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 2/27/26.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

/// An Element wrapper that provides inline tappable brand icons for card brand choice (CBC).
/// Can switch between the new inline selector and the old dropdown based on `enableCBCRedesign`.
/// Will be collapsed when we ship and remove `enableCBCRedesign`, replacing the old dropdown
final class CardBrandChoiceElement: Element {
    weak var delegate: ElementDelegate?

    var view: UIView {
        return enableCBCRedesign ? (selectorElement?.view ?? UIView()) : (dropdownElement?.view ?? UIView())
    }

    var collectsUserInput: Bool {
        return enableCBCRedesign ? (selectorElement?.collectsUserInput ?? false) : (dropdownElement?.collectsUserInput ?? false)
    }

    let enableCBCRedesign: Bool
    let includePlaceholder: Bool

    var selectorElement: SegmentedSelectorElement?
    var dropdownElement: DropdownFieldElement?

    // Expose selected brand for external access
    var selectedBrand: STPCardBrand? {
        if enableCBCRedesign {
            guard let rawData = selectorElement?.selectedItem?.rawData else { return nil }
            return STPCard.brand(from: rawData)
        } else {
            guard let dropdown = dropdownElement else { return nil }
            return STPCard.brand(from: dropdown.selectedItem.rawData)
        }
    }

    // Expose brand count for determining if selector should be shown
    var brandCount: Int {
        if enableCBCRedesign {
            return selectorElement?.items.count ?? 0
        } else {
            return dropdownElement?.nonPlacerholderItems.count ?? 0
        }
    }

    init(enableCBCRedesign: Bool,
         cardBrands: Set<STPCardBrand> = [],
         disallowedCardBrands: Set<STPCardBrand> = [],
         theme: ElementsAppearance = .default,
         includePlaceholder: Bool = true) {
        self.enableCBCRedesign = enableCBCRedesign
        self.includePlaceholder = includePlaceholder

        if enableCBCRedesign {
            self.selectorElement = SegmentedSelectorElement(
                items: Self.makeItems(from: cardBrands),
                disabledItems: Self.makeItems(from: disallowedCardBrands),
                theme: theme
            )
            self.selectorElement?.delegate = self
        } else {
            self.dropdownElement = DropdownFieldElement.makeCardBrandDropdown(
                cardBrands: cardBrands,
                disallowedCardBrands: disallowedCardBrands,
                theme: theme,
                includePlaceholder: includePlaceholder
            )
            self.dropdownElement?.delegate = self
        }
    }

    func update(cardBrands: Set<STPCardBrand>, disallowedBrands: Set<STPCardBrand> = []) {
        if enableCBCRedesign {
            selectorElement?.update(
                items: Self.makeItems(from: cardBrands),
                disabledItems: Self.makeItems(from: disallowedBrands)
            )
        } else {
            let items = DropdownFieldElement.items(
                from: cardBrands,
                disallowedCardBrands: disallowedBrands,
                theme: dropdownElement?.theme ?? .default,
                includePlaceholder: includePlaceholder
            )
            dropdownElement?.update(items: items)
        }
    }

    // MARK: - Helper Methods

    /// Converts a set of card brands to selector items
    private static func makeItems(from brands: Set<STPCardBrand>) -> Set<SegmentedSelectorItem> {
        return Set(brands.map { brand in
            SegmentedSelectorItem(
                rawData: STPCardBrandUtilities.apiValue(from: brand),
                image: STPImageLibrary.cardBrandImage(for: brand),
                accessibilityLabel: STPCardBrandUtilities.stringFrom(brand) ?? ""
            )
        })
    }
}

extension CardBrandChoiceElement: ElementDelegate {
    func didUpdate(element: Element) {
        delegate?.didUpdate(element: self)
    }

    func continueToNextField(element: Element) {
        delegate?.continueToNextField(element: self)
    }
}
