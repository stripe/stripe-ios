//
//  CardBrandSelectorElement.swift
//  StripePaymentSheet
//
//  Created by David Estes on 2/11/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

/// An Element wrapper around `CardBrandSelectorView` that provides inline tappable brand icons
/// for card brand choice (CBC). Replaces the old `DropdownFieldElement`-based card brand picker.
final class CardBrandSelectorElement: Element {
    weak var delegate: ElementDelegate?

    let collectsUserInput: Bool = true

    var validationState: ElementValidationState { .valid }

    /// Controls whether the "Choose a card brand" sub-label is shown.
    /// Should be set to `true` when the PAN field is being edited.
    var isPanFieldEditing: Bool = false {
        didSet {
            if oldValue != isPanFieldEditing {
                delegate?.didUpdate(element: self)
            }
        }
    }

    var subLabelText: String? {
        guard cardBrandSelectorView.brands.count > 1,
              cardBrandSelectorView.selectedBrand == nil,
              isPanFieldEditing else {
            return nil
        }
        return String.Localized.choose_a_card_brand
    }

    private(set) lazy var cardBrandSelectorView: CardBrandSelectorView = {
        let view = CardBrandSelectorView()
        view.delegate = self
        return view
    }()

    var view: UIView { cardBrandSelectorView }

    // MARK: - Public API

    var brands: [STPCardBrand] { cardBrandSelectorView.brands }

    var selectedBrand: STPCardBrand? { cardBrandSelectorView.selectedBrand }

    /// Updates the displayed brands and disallowed brands.
    func update(brands: [STPCardBrand], disallowedBrands: Set<STPCardBrand>) {
        cardBrandSelectorView.update(brands: brands, selectedBrand: cardBrandSelectorView.selectedBrand, disallowedBrands: disallowedBrands)
        delegate?.didUpdate(element: self)
    }

    /// Selects a specific brand (e.g. for preferred network auto-selection).
    func select(brand: STPCardBrand?) {
        cardBrandSelectorView.select(brand: brand)
        delegate?.didUpdate(element: self)
    }

    /// Clears the current selection and brand list.
    func reset() {
        cardBrandSelectorView.update(brands: [], selectedBrand: nil, disallowedBrands: [])
        delegate?.didUpdate(element: self)
    }
}

// MARK: - CardBrandSelectorViewDelegate

extension CardBrandSelectorElement: CardBrandSelectorViewDelegate {
    func cardBrandSelectorView(_ view: CardBrandSelectorView, didChangeSelection brand: STPCardBrand?) {
        delegate?.didUpdate(element: self)
    }
}
