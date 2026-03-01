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

    var selectorElement: SelectorElement?
    var dropdownElement: DropdownFieldElement?

    // Expose selected brand for external access
    var selectedBrand: STPCardBrand? {
        if enableCBCRedesign {
            return selectorElement?.selectedBrand
        } else {
            guard let dropdown = dropdownElement else { return nil }
            return STPCard.brand(from: dropdown.selectedItem.rawData)
        }
    }

    // Expose brand count for determining if selector should be shown
    var brandCount: Int {
        if enableCBCRedesign {
            return selectorElement?.cardBrands.count ?? 0
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
            self.selectorElement = SelectorElement(
                cardBrands: cardBrands,
                disallowedCardBrands: disallowedCardBrands,
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

    func update(cardBrands: Set<STPCardBrand>, disallowedCardBrands: Set<STPCardBrand> = []) {
        if enableCBCRedesign {
            selectorElement?.update(cardBrands: cardBrands, disallowedCardBrands: disallowedCardBrands)
        } else {
            let items = DropdownFieldElement.items(
                from: cardBrands,
                disallowedCardBrands: disallowedCardBrands,
                theme: dropdownElement?.theme ?? .default,
                includePlaceholder: includePlaceholder
            )
            dropdownElement?.update(items: items)
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

// MARK: - CardBrandChoiceViewDelegate

/// Delegate protocol for CardBrandChoiceView
private protocol CardBrandChoiceViewDelegate: AnyObject {
    func didTapBrand(_ brand: STPCardBrand?)
}

// MARK: - SelectorElement

/// Displays card brand icons in a horizontal row with tap-to-select behavior.
/// Selecting a brand shows a checkmark, tapping again deselects it (toggle).
final class SelectorElement: Element {
    weak var delegate: ElementDelegate?

    lazy var view: UIView = {
        return cbcView
    }()

    let collectsUserInput: Bool = true

    private let cbcView: CardBrandChoiceView
    private let theme: ElementsAppearance

    private(set) var selectedBrand: STPCardBrand?
    var cardBrands: Set<STPCardBrand>
    private var disallowedCardBrands: Set<STPCardBrand>

    init(cardBrands: Set<STPCardBrand> = [],
         disallowedCardBrands: Set<STPCardBrand> = [],
         theme: ElementsAppearance = .default) {
        self.cardBrands = cardBrands
        self.disallowedCardBrands = disallowedCardBrands
        self.theme = theme
        self.cbcView = CardBrandChoiceView(
            cardBrands: Array(cardBrands.sorted()),
            disallowedCardBrands: disallowedCardBrands,
            theme: theme
        )
        self.cbcView.delegate = self
    }

    func update(cardBrands: Set<STPCardBrand>, disallowedCardBrands: Set<STPCardBrand> = []) {
        self.cardBrands = cardBrands
        self.disallowedCardBrands = disallowedCardBrands

        // Clear selected brand if it's not in the new brands set
        if let selected = selectedBrand, !cardBrands.contains(selected) {
            selectedBrand = nil
        }

        // Don't make any selection changes if there aren't multiple brands to choose from
        guard cardBrands.count > 1 else {
            return
        }

        // Auto-select if there's only one allowed brand
        // Note: Don't call delegate?.didUpdate here - this method is called by the parent
        // as part of its update cycle. The parent will handle propagating changes.
        let allowedBrands = cardBrands.subtracting(disallowedCardBrands)
        if allowedBrands.count == 1, let onlyAllowedBrand = allowedBrands.first {
            if selectedBrand != onlyAllowedBrand {
                selectedBrand = onlyAllowedBrand
            }
        } else if allowedBrands.isEmpty && selectedBrand != nil {
            // If no brands are allowed, clear selection
            selectedBrand = nil
        }

        cbcView.update(
            cardBrands: Array(cardBrands.sorted()),
            disallowedCardBrands: disallowedCardBrands
        )

        // Update the view to reflect the current selection
        cbcView.setSelectedBrand(selectedBrand, animated: false)
    }

    func updateBrandSelection(_ brand: STPCardBrand?, animated: Bool = false) {
        // Toggle behavior: if already selected, deselect
        let newSelection: STPCardBrand? = (selectedBrand == brand) ? nil : brand
        selectedBrand = newSelection

        // Update the visual UI
        cbcView.setSelectedBrand(newSelection, animated: animated)

        delegate?.didUpdate(element: self)
    }
}

extension SelectorElement: CardBrandChoiceViewDelegate {
    func didTapBrand(_ brand: STPCardBrand?) {
        updateBrandSelection(brand)
    }
}
// MARK: - CardBrandChoiceView

/// The actual UIView that displays card brand icons with checkmarks (segmented control style)
private final class CardBrandChoiceView: UIView {
    weak var delegate: CardBrandChoiceViewDelegate?

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let theme: ElementsAppearance
    private var brandViews: [STPCardBrand: CardBrandItemView] = [:]
    private var selectedBrand: STPCardBrand?

    init(cardBrands: [STPCardBrand],
         disallowedCardBrands: Set<STPCardBrand>,
         theme: ElementsAppearance) {
        self.theme = theme
        super.init(frame: .zero)
        setupView()
        update(cardBrands: cardBrands, disallowedCardBrands: disallowedCardBrands)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        // Add segmented control styling
        layer.cornerRadius = theme.cornerRadius ?? 5
        layer.borderWidth = theme.borderWidth
        layer.borderColor = theme.colors.border.cgColor
        backgroundColor = theme.colors.componentBackground
        clipsToBounds = true // Clip child backgrounds to rounded corners

        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    func update(cardBrands: [STPCardBrand], disallowedCardBrands: Set<STPCardBrand>) {
        stackView.arrangedSubviews.forEach {
            $0.removeFromSuperview()
        }
        brandViews.removeAll()

        // Add views for each brand with separators
        let validBrands = cardBrands.filter { $0 != .unknown }
        for (index, brand) in validBrands.enumerated() {
            let isDisallowed = disallowedCardBrands.contains(brand)
            let itemView = CardBrandItemView(
                brand: brand,
                isDisallowed: isDisallowed,
                theme: theme
            )

            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(brandTapped(_:)))
            itemView.addGestureRecognizer(tapGesture)
            itemView.isUserInteractionEnabled = !isDisallowed

            stackView.addArrangedSubview(itemView)
            brandViews[brand] = itemView

            // Add separator between segments (except after the last one)
            if index < validBrands.count - 1 {
                let separator = UIView()
                separator.translatesAutoresizingMaskIntoConstraints = false
                separator.backgroundColor = theme.colors.divider
                stackView.addArrangedSubview(separator)
                NSLayoutConstraint.activate([
                    separator.widthAnchor.constraint(equalToConstant: 1),
                ])
            }
        }

        // Update intrinsic content size after adding/removing brands
        invalidateIntrinsicContentSize()
    }

    func setSelectedBrand(_ brand: STPCardBrand?, animated: Bool) {
        // Deselect previous
        if let previousBrand = selectedBrand,
           let previousView = brandViews[previousBrand] {
            previousView.updateSelectionState(false, animated: animated)
        }

        selectedBrand = brand

        // Select new brand
        if let brand = brand, let itemView = brandViews[brand] {
            itemView.updateSelectionState(true, animated: animated)
        }
    }

    @objc private func brandTapped(_ sender: UITapGestureRecognizer) {
        guard let itemView = sender.view as? CardBrandItemView else { return }
        // Notify SelectorElement to handle the selection
        delegate?.didTapBrand(itemView.brand)
    }
}

// MARK: - CardBrandItemView

/// A single tappable card brand icon with optional checkmark (segmented control style)
private final class CardBrandItemView: UIView {
    let brand: STPCardBrand
    private let isDisallowed: Bool
    private let theme: ElementsAppearance

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let checkmarkImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isHidden = true
        return imageView
    }()

    private let containerStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 4
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    init(brand: STPCardBrand, isDisallowed: Bool, theme: ElementsAppearance) {
        self.brand = brand
        self.isDisallowed = isDisallowed
        self.theme = theme
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        iconImageView.image = STPImageLibrary.cardBrandImage(for: brand)
        if isDisallowed {
            iconImageView.alpha = 0.4
        }

        checkmarkImageView.image = Image.embedded_check.makeImage(template: true)
        checkmarkImageView.tintColor = theme.colors.bodyText

        // Add checkmark on the left, then icon on the right
        containerStack.addArrangedSubview(checkmarkImageView)
        containerStack.addArrangedSubview(iconImageView)

        addSubview(containerStack)

        NSLayoutConstraint.activate([
            containerStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            containerStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            containerStack.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            containerStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),

            checkmarkImageView.widthAnchor.constraint(equalToConstant: 12),
            checkmarkImageView.heightAnchor.constraint(equalToConstant: 12),
        ])

        // Add accessibility
        isAccessibilityElement = true
        accessibilityLabel = STPCardBrandUtilities.stringFrom(brand)
        accessibilityTraits = .button
    }

    func updateSelectionState(_ selected: Bool, animated: Bool) {
        if selected {
            checkmarkImageView.isHidden = false
            checkmarkImageView.alpha = 0

            // Start background color animation
            UIView.animate(withDuration: 0.2) {
                self.backgroundColor = self.theme.colors.disabledBackground
            }

            accessibilityTraits.insert(.selected)
            if animated {
                UIView.animate(withDuration: 0.2) {
                    self.checkmarkImageView.alpha = 1.0
                }
            } else {
                checkmarkImageView.alpha = 1.0
            }
        } else {
            checkmarkImageView.isHidden = true
            UIView.animate(withDuration: 0.2) {
                self.backgroundColor = .clear
            }
            accessibilityTraits.remove(.selected)
        }
    }

}
