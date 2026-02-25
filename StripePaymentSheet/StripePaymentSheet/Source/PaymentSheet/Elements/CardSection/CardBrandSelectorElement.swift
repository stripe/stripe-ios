//
//  CardBrandSelectorElement.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 2/24/26.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

/// An Element wrapper that provides inline tappable brand icons for card brand choice (CBC).
/// Can switch between the new inline selector and the old dropdown based on `enableCBCRedesign`.
final class CardBrandSelectorElement: Element {
    weak var delegate: ElementDelegate?

    var view: UIView {
        return enableCBCRedesign ? (selectorElement?.view ?? UIView()) : (dropdownElement?.view ?? UIView())
    }

    var collectsUserInput: Bool {
        return enableCBCRedesign ? (selectorElement?.collectsUserInput ?? false) : (dropdownElement?.collectsUserInput ?? false)
    }

    let enableCBCRedesign: Bool

    var selectorElement: SelectorElement?
    var dropdownElement: DropdownFieldElement?

    // Expose selected brand for external access
    var selectedBrand: STPCardBrand? {
        if enableCBCRedesign {
            return selectorElement?.selectedBrand
        } else {
            guard let dropdown = dropdownElement,
                  let rawValue = Int(dropdown.selectedItem.rawData) else {
                return nil
            }
            return STPCardBrand(rawValue: rawValue)
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
         didSelectBrand: ((STPCardBrand?) -> Void)? = nil) {
        self.enableCBCRedesign = enableCBCRedesign

        if enableCBCRedesign {
            self.selectorElement = SelectorElement(
                cardBrands: cardBrands,
                disallowedCardBrands: disallowedCardBrands,
                theme: theme,
                didSelectBrand: didSelectBrand
            )
            self.selectorElement?.delegate = self
        } else {
            self.dropdownElement = DropdownFieldElement.makeCardBrandDropdown(
                cardBrands: cardBrands,
                disallowedCardBrands: disallowedCardBrands,
                theme: theme,
                includePlaceholder: true,
                hasPadding: true
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
                includePlaceholder: true
            )
            dropdownElement?.update(items: items)
        }
    }
}

extension CardBrandSelectorElement: ElementDelegate {
    func didUpdate(element: Element) {
        delegate?.didUpdate(element: self)
    }

    func continueToNextField(element: Element) {
        delegate?.continueToNextField(element: self)
    }
}

// MARK: - SelectorElement

/// Displays card brand icons in a horizontal row with tap-to-select behavior.
/// Selecting a brand shows a checkmark, tapping again deselects it (toggle).
final class SelectorElement: Element {
    weak var delegate: ElementDelegate?

    lazy var view: UIView = {
        return selectorView
    }()

    let collectsUserInput: Bool = true

    private let selectorView: CardBrandSelectorView
    private let theme: ElementsAppearance
    private var didSelectBrand: ((STPCardBrand?) -> Void)?

    private(set) var selectedBrand: STPCardBrand?
    var cardBrands: Set<STPCardBrand>
    private var disallowedCardBrands: Set<STPCardBrand>

    init(cardBrands: Set<STPCardBrand> = [],
         disallowedCardBrands: Set<STPCardBrand> = [],
         theme: ElementsAppearance = .default,
         didSelectBrand: ((STPCardBrand?) -> Void)? = nil) {
        self.cardBrands = cardBrands
        self.disallowedCardBrands = disallowedCardBrands
        self.theme = theme
        self.didSelectBrand = didSelectBrand
        self.selectorView = CardBrandSelectorView(
            cardBrands: Array(cardBrands.sorted()),
            disallowedCardBrands: disallowedCardBrands,
            theme: theme
        )

        selectorView.onBrandSelected = { [weak self] brand in
            self?.handleBrandSelection(brand)
        }
    }

    func update(cardBrands: Set<STPCardBrand>, disallowedCardBrands: Set<STPCardBrand> = []) {
        self.cardBrands = cardBrands
        self.disallowedCardBrands = disallowedCardBrands

        // Clear selected brand if it's not in the new brands set
        if let selected = selectedBrand, !cardBrands.contains(selected) {
            selectedBrand = nil
        }

        // Clear selected brand if no brands are available
        if cardBrands.isEmpty {
            selectedBrand = nil
        }

        selectorView.update(
            cardBrands: Array(cardBrands.sorted()),
            disallowedCardBrands: disallowedCardBrands
        )
    }

    private func handleBrandSelection(_ brand: STPCardBrand?) {
        // Toggle behavior: if already selected, deselect
        if selectedBrand == brand {
            selectedBrand = nil
        } else {
            selectedBrand = brand
        }

        didSelectBrand?(selectedBrand)
        delegate?.didUpdate(element: self)
    }
}

// MARK: - CardBrandSelectorView

/// The actual UIView that displays card brand icons with checkmarks (segmented control style)
private final class CardBrandSelectorView: UIView {
    var onBrandSelected: ((STPCardBrand?) -> Void)?

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 0
        stack.alignment = .fill
        stack.distribution = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let theme: ElementsAppearance
    private var brandViews: [STPCardBrand: CardBrandItemView] = [:]
    private var selectedBrand: STPCardBrand?
    private var separatorViews: [UIView] = []

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
            stackView.heightAnchor.constraint(equalToConstant: 32)
        ])

        // Set content hugging and compression resistance to keep it compact
        setContentHuggingPriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    func update(cardBrands: [STPCardBrand], disallowedCardBrands: Set<STPCardBrand>) {
        // Remove all existing views
        stackView.arrangedSubviews.forEach {
            $0.removeFromSuperview()
        }
        brandViews.removeAll()

        // Remove separator views
        separatorViews.forEach { $0.removeFromSuperview() }
        separatorViews.removeAll()

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
                addSubview(separator)
                separatorViews.append(separator)

                let constraints = [
                    separator.widthAnchor.constraint(equalToConstant: 1),
                    separator.topAnchor.constraint(equalTo: topAnchor),
                    separator.bottomAnchor.constraint(equalTo: bottomAnchor),
                    separator.leadingAnchor.constraint(equalTo: itemView.trailingAnchor)
                ]
                NSLayoutConstraint.activate(constraints)
            }
        }

        // Update intrinsic content size after adding/removing brands
        invalidateIntrinsicContentSize()
    }

    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)

        // Clean up separators when view is being removed
        if newSuperview == nil {
            separatorViews.forEach { $0.removeFromSuperview() }
            separatorViews.removeAll()
        }
    }

    @objc private func brandTapped(_ sender: UITapGestureRecognizer) {
        guard let itemView = sender.view as? CardBrandItemView else { return }

        let brand = itemView.brand

        // Toggle selection
        if selectedBrand == brand {
            selectedBrand = nil
            itemView.setSelected(false)
        } else {
            // Deselect previous
            if let previousBrand = selectedBrand,
               let previousView = brandViews[previousBrand] {
                previousView.setSelected(false)
            }

            selectedBrand = brand
            // Prepare checkmark for fade-in
            itemView.prepareCheckmarkForFadeIn()
        }

        // Animate the size change and fade in checkmark simultaneously
        UIView.animate(withDuration: 0.2) {
            if self.selectedBrand == brand {
                itemView.fadeInCheckmark()
            }
            self.superview?.layoutIfNeeded()
        }

        onBrandSelected?(selectedBrand)
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
        stack.distribution = .fill
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
        // Set up brand icon with fixed size
        iconImageView.image = STPImageLibrary.cardBrandImage(for: brand)
        iconImageView.contentMode = .scaleAspectFit
        if isDisallowed {
            iconImageView.alpha = 0.4
        }

        if #available(iOS 13.0, *) {
            checkmarkImageView.image = UIImage(systemName: "checkmark")
            checkmarkImageView.tintColor = theme.colors.bodyText
        }

        // Add checkmark on the left, then icon on the right
        containerStack.addArrangedSubview(checkmarkImageView)
        containerStack.addArrangedSubview(iconImageView)

        addSubview(containerStack)

        NSLayoutConstraint.activate([
            containerStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            containerStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            containerStack.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            containerStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),

            iconImageView.widthAnchor.constraint(equalToConstant: 30),
            iconImageView.heightAnchor.constraint(equalToConstant: 20),

            checkmarkImageView.widthAnchor.constraint(equalToConstant: 12),
            checkmarkImageView.heightAnchor.constraint(equalToConstant: 12)
        ])

        // Add accessibility
        isAccessibilityElement = true
        accessibilityLabel = STPCardBrandUtilities.stringFrom(brand)
        accessibilityTraits = .button
    }

    func setSelected(_ selected: Bool) {
        if !selected {
            // Deselecting: hide checkmark and clear background
            checkmarkImageView.isHidden = true
            checkmarkImageView.alpha = 0
            UIView.animate(withDuration: 0.2) {
                self.backgroundColor = .clear
            }
            accessibilityTraits.remove(.selected)
        }
    }

    func prepareCheckmarkForFadeIn() {
        // Make checkmark visible (for layout) but transparent
        checkmarkImageView.isHidden = false
        checkmarkImageView.alpha = 0

        // Start background color animation
        UIView.animate(withDuration: 0.2) {
            self.backgroundColor = self.theme.colors.disabledBackground
        }

        accessibilityTraits.insert(.selected)
    }

    func fadeInCheckmark() {
        // Animate alpha from 0 to 1 (called inside animation block)
        checkmarkImageView.alpha = 1.0
    }
}
