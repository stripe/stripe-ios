//
//  CardBrandSelectorView.swift
//  StripePaymentSheet
//
//  Created by David Estes on 2/11/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

protocol CardBrandSelectorViewDelegate: AnyObject {
    func cardBrandSelectorView(_ view: CardBrandSelectorView, didChangeSelection brand: STPCardBrand?)
}

/// A view that displays card brand icons side-by-side with tap-to-select behavior.
/// Selecting a brand shows a checkmark between the icons. Tapping again deselects (toggle).
class CardBrandSelectorView: UIView {
    weak var delegate: CardBrandSelectorViewDelegate?

    private(set) var brands: [STPCardBrand] = []
    private(set) var selectedBrand: STPCardBrand?
    private(set) var disallowedBrands: Set<STPCardBrand> = []

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 4
        return stack
    }()

    private static let brandIconSize = CGSize(width: 28, height: 18)
    private static let checkmarkSize: CGFloat = 12

    override init(frame: CGRect) {
        super.init(frame: frame)
        addAndPinSubview(stackView)
        isAccessibilityElement = true
        accessibilityTraits = .adjustable
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(brands: [STPCardBrand], selectedBrand: STPCardBrand?, disallowedBrands: Set<STPCardBrand>) {
        self.brands = brands
        self.selectedBrand = selectedBrand
        self.disallowedBrands = disallowedBrands
        rebuildStackView()
        updateAccessibility()
    }

    func select(brand: STPCardBrand?) {
        selectedBrand = brand
        rebuildStackView()
        updateAccessibility()
    }

    // MARK: - Private

    private func rebuildStackView() {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for (index, brand) in brands.enumerated() {
            let isDisallowed = disallowedBrands.contains(brand)
            let isSelected = selectedBrand == brand

            let button = makeBrandButton(brand: brand, tag: index, isDisallowed: isDisallowed)

            // Insert checkmark before this brand if the previous brand was selected
            if index > 0 && brands[index - 1] == selectedBrand {
                stackView.addArrangedSubview(makeCheckmarkView())
            }

            stackView.addArrangedSubview(button)

            // Insert checkmark after this brand if this is the last brand and it's selected
            if isSelected && index == brands.count - 1 {
                stackView.addArrangedSubview(makeCheckmarkView())
            }
        }
    }

    private func makeBrandButton(brand: STPCardBrand, tag: Int, isDisallowed: Bool) -> UIButton {
        let button = UIButton(type: .custom)
        button.tag = tag
        let image = STPImageLibrary.cardBrandImage(for: brand)
        button.setImage(image, for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.addTarget(self, action: #selector(brandTapped(_:)), for: .touchUpInside)

        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: Self.brandIconSize.width),
            button.heightAnchor.constraint(equalToConstant: Self.brandIconSize.height),
        ])

        if isDisallowed {
            button.alpha = 0.3
            button.isUserInteractionEnabled = false
        }

        return button
    }

    private func makeCheckmarkView() -> UIView {
        let image = Image.icon_checkmark.makeImage(template: true)
        let imageView = UIImageView(image: image)
        imageView.tintColor = .systemGreen
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: Self.checkmarkSize),
            imageView.heightAnchor.constraint(equalToConstant: Self.checkmarkSize),
        ])
        return imageView
    }

    @objc private func brandTapped(_ sender: UIButton) {
        let index = sender.tag
        guard index < brands.count else { return }
        let brand = brands[index]

        guard !disallowedBrands.contains(brand) else { return }

        // Toggle semantics
        if selectedBrand == brand {
            selectedBrand = nil
        } else {
            selectedBrand = brand
        }

        rebuildStackView()
        updateAccessibility()
        delegate?.cardBrandSelectorView(self, didChangeSelection: selectedBrand)
    }

    // MARK: - Accessibility

    private func updateAccessibility() {
        let brandNames = brands.map { STPCardBrandUtilities.stringFrom($0) ?? "Unknown" }
        if let selectedBrand = selectedBrand,
           let name = STPCardBrandUtilities.stringFrom(selectedBrand) {
            accessibilityValue = name
            accessibilityLabel = String(
                format: String.Localized.card_brand_selector_accessibility_label,
                brandNames.joined(separator: ", ")
            )
        } else {
            accessibilityValue = nil
            accessibilityLabel = String(
                format: String.Localized.card_brand_selector_accessibility_label,
                brandNames.joined(separator: ", ")
            )
        }
    }

    // MARK: - UIAccessibility (adjustable)

    override func accessibilityIncrement() {
        guard !brands.isEmpty else { return }
        let currentIndex = brands.firstIndex(where: { $0 == selectedBrand }) ?? -1
        let nextIndex = currentIndex + 1
        if nextIndex < brands.count && !disallowedBrands.contains(brands[nextIndex]) {
            selectedBrand = brands[nextIndex]
            rebuildStackView()
            updateAccessibility()
            delegate?.cardBrandSelectorView(self, didChangeSelection: selectedBrand)
        }
    }

    override func accessibilityDecrement() {
        guard !brands.isEmpty else { return }
        if let currentIndex = brands.firstIndex(where: { $0 == selectedBrand }), currentIndex > 0 {
            let prevIndex = currentIndex - 1
            if !disallowedBrands.contains(brands[prevIndex]) {
                selectedBrand = brands[prevIndex]
                rebuildStackView()
                updateAccessibility()
                delegate?.cardBrandSelectorView(self, didChangeSelection: selectedBrand)
            }
        } else {
            selectedBrand = nil
            rebuildStackView()
            updateAccessibility()
            delegate?.cardBrandSelectorView(self, didChangeSelection: selectedBrand)
        }
    }
}
