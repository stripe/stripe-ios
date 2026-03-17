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
final class CardBrandChoiceElement: Element {
    weak var delegate: ElementDelegate?

    let element: SegmentedSelectorElement

    var view: UIView {
        return element.view
    }

    var collectsUserInput: Bool {
        return element.collectsUserInput
    }

    // Expose selected brand for external access
    var selectedBrand: STPCardBrand? {
        guard let rawData = element.selectedItem?.rawData else { return nil }
        return STPCard.brand(from: rawData)
    }

    // Expose whether the user has tapped the selector for determining if tooltip should be shown
    var hasBeenTapped: Bool {
        return element.hasBeenTapped
    }

    // Expose brand count for determining if selector should be shown
    var brandCount: Int {
        return element.items.count
    }

    // Expose allowed brand count for determining if selector should be shown
    var allowedBrandCount: Int {
        return element.enabledItems.count
    }

    init(cardBrands: Set<STPCardBrand> = [],
         disallowedCardBrands: Set<STPCardBrand> = [],
         theme: ElementsAppearance = .default,
         allowDeselection: Bool = true) {
        element = SegmentedSelectorElement(
            items: Self.makeItems(from: cardBrands),
            disabledItems: Set(Self.makeItems(from: disallowedCardBrands)),
            allowDeselection: allowDeselection,
            theme: theme
        )
        element.delegate = self
    }

    func update(cardBrands: Set<STPCardBrand>, disallowedCardBrands: Set<STPCardBrand> = []) {
        let allowedBrands = cardBrands.subtracting(disallowedCardBrands)
        element.update(
            items: Self.makeItems(from: cardBrands),
            disabledItems: Set(Self.makeItems(from: disallowedCardBrands))
        )
        // If we only fetched one card brand that is not disallowed, disable interaction and auto select it.
        // This case typically only occurs when card brand filtering is used with CBC and one of the fetched brands is filtered out.
        view.isUserInteractionEnabled = allowedBrands.count > 1
        if allowedBrands.count == 1,
           !disallowedCardBrands.isEmpty,
           let brand = allowedBrands.first {
            select(brand)
        }
    }

    func select(_ brand: STPCardBrand) {
        element.select(brand.makeCardBrandItem())
    }

    // MARK: - Helper Methods

    /// Converts a set of card brands to an ordered array of selector items.
    /// Sorts by brand's rawValue to ensure deterministic ordering.
    private static func makeItems(from brands: Set<STPCardBrand>) -> [SegmentedSelectorItem] {
        return brands
            .sorted { $0.rawValue < $1.rawValue }
            .map { brand in
                brand.makeCardBrandItem()
            }
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

extension STPCardBrand {
    func makeCardBrandItem() -> SegmentedSelectorItem {
        return SegmentedSelectorItem(
            rawData: STPCardBrandUtilities.apiValue(from: self),
            image: STPImageLibrary.unpaddedCardBrandImage(for: self),
            accessibilityLabel: STPCardBrandUtilities.stringFrom(self) ?? ""
        )
    }
}
