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

    private enum Variant {
        case selector(SegmentedSelectorElement)
        case dropdown(DropdownFieldElement)
    }

    private let variant: Variant

    var view: UIView {
        switch variant {
        case .selector(let element):
            return element.view
        case .dropdown(let element):
            return element.view
        }
    }

    var collectsUserInput: Bool {
        switch variant {
        case .selector(let element):
            return element.collectsUserInput
        case .dropdown(let element):
            return element.collectsUserInput
        }
    }

    var enableCBCRedesign: Bool {
        switch variant {
        case .selector:
            return true
        case .dropdown:
            return false
        }
    }

    // Expose selected brand for external access
    var selectedBrand: STPCardBrand? {
        switch variant {
        case .selector(let element):
            guard let rawData = element.selectedItem?.rawData else { return nil }
            return STPCard.brand(from: rawData)
        case .dropdown(let element):
            guard !element.selectedItem.isPlaceholder else { return nil }
            return STPCard.brand(from: element.selectedItem.rawData)
        }
    }

    /// Latches true once the user taps the selector.
    private(set) var hasBeenInteractedWith = false

    // Expose brand count for determining if selector should be shown
    var brandCount: Int {
        switch variant {
        case .selector(let element):
            return element.items.count
        case .dropdown(let element):
            return element.nonPlacerholderItems.count
        }
    }

    init(enableCBCRedesign: Bool,
         cardBrands: Set<STPCardBrand> = [],
         disallowedCardBrands: Set<STPCardBrand> = [],
         theme: ElementsAppearance = .default,
         allowDeselection: Bool = true) {
        if enableCBCRedesign {
            let element = SegmentedSelectorElement(
                items: Self.makeItems(from: cardBrands),
                disabledItems: Set(Self.makeItems(from: disallowedCardBrands)),
                allowDeselection: allowDeselection,
                theme: theme
            )
            self.variant = .selector(element)
            element.delegate = self
        } else {
            let element = DropdownFieldElement.makeCardBrandDropdown(
                cardBrands: cardBrands,
                disallowedCardBrands: disallowedCardBrands,
                theme: theme,
                includePlaceholder: allowDeselection
            )
            self.variant = .dropdown(element)
            element.delegate = self
        }
    }

    func update(cardBrands: Set<STPCardBrand>, disallowedCardBrands: Set<STPCardBrand> = []) {
        let allowedBrands = cardBrands.subtracting(disallowedCardBrands)
        switch variant {
        case .selector(let element):
            element.update(
                items: Self.makeItems(from: cardBrands),
                disabledItems: Set(Self.makeItems(from: disallowedCardBrands))
            )
        case .dropdown(let element):
            let items = DropdownFieldElement.items(
                from: cardBrands,
                disallowedCardBrands: disallowedCardBrands,
                theme: element.theme,
                includePlaceholder: element.items.contains { $0.isPlaceholder }
            )
            element.update(items: items)
        }
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
        switch variant {
        case .selector(let element):
            element.select(brand.makeCardBrandItem())
        case .dropdown(let element):
            if let index = element.items.firstIndex(where: { $0.rawData == STPCardBrandUtilities.apiValue(from: brand) }) {
                element.select(index: index, shouldAutoAdvance: false)
            }
        }
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
        hasBeenInteractedWith = true
        delegate?.didUpdate(element: self)
    }

    func continueToNextField(element: Element) {
        delegate?.continueToNextField(element: self)
    }
}

private extension STPCardBrand {
    func makeCardBrandItem() -> SegmentedSelectorItem {
        return SegmentedSelectorItem(
            rawData: STPCardBrandUtilities.apiValue(from: self),
            image: STPImageLibrary.unpaddedCardBrandImage(for: self),
            accessibilityLabel: STPCardBrandUtilities.stringFrom(self) ?? ""
        )
    }
}
