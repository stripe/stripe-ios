//
//  SegmentedSelectorElement.swift
//  StripeUICore
//
//  Created by Joyce Qin on 3/1/26.
//

import Foundation
import UIKit

// MARK: - SegmentedSelectorElement

/// Element that displays items in a horizontal row with tap-to-select behavior.
/// Selecting an item shows a checkmark, tapping again deselects it (toggle).
@_spi(STP) public final class SegmentedSelectorElement: Element {
    weak public var delegate: ElementDelegate?

    public var view: UIView {
        return selectorView
    }

    public let collectsUserInput: Bool = true

    private let selectorView: SegmentedSelectorView

    public private(set) var selectedItem: SegmentedSelectorItem?
    public private(set) var items: [SegmentedSelectorItem]
    private var disabledItems: Set<SegmentedSelectorItem>

    /// When false, the user cannot deselect the currently selected item.
    private var allowDeselection: Bool

    public init(items: [SegmentedSelectorItem] = [],
                disabledItems: Set<SegmentedSelectorItem> = [],
                allowDeselection: Bool = true,
                theme: ElementsAppearance = .default) {
        self.items = items
        self.disabledItems = disabledItems
        self.allowDeselection = allowDeselection
        self.selectorView = SegmentedSelectorView(
            items: items,
            disabledItems: disabledItems,
            theme: theme
        )
        self.selectorView.delegate = self
    }

    public func update(items: [SegmentedSelectorItem], disabledItems: Set<SegmentedSelectorItem> = []) {
        guard items != self.items || disabledItems != self.disabledItems else { return }
        self.items = items
        self.disabledItems = disabledItems

        // If the previously selected item is no longer present or enabled, deselect it
        if let selectedItem, !items.contains(selectedItem) || disabledItems.contains(selectedItem) {
            self.selectedItem = nil
            delegate?.didUpdate(element: self)
        }

        selectorView.update(
            items: items,
            disabledItems: disabledItems,
            selectedItem: selectedItem
        )
    }

    public func select(_ item: SegmentedSelectorItem?, animated: Bool = false) {
        // Validate that item exists in items array (if not nil)
        if let item = item, !items.contains(item) {
            return
        }

        guard selectedItem != item else { return }

        selectedItem = item

        // Update the visual UI
        selectorView.select(item, animated: animated)

        delegate?.didUpdate(element: self)
    }

    private func itemTapped(_ item: SegmentedSelectorItem) {
        // If deselection is not allowed, no-op when tapping on already selected item
        if selectedItem == item && !allowDeselection {
            return
        }
        // Toggle behavior: if already selected, deselect
        let newSelection: SegmentedSelectorItem? = (selectedItem == item) ? nil : item
        select(newSelection, animated: true)
    }
}

extension SegmentedSelectorElement: SegmentedSelectorViewDelegate {
    func didTap(_ item: SegmentedSelectorItem) {
        itemTapped(item)
    }
}

// MARK: - SegmentedSelectorView

/// UIView that displays selectable items with checkmarks (segmented control style)
final class SegmentedSelectorView: UIView {
    weak var delegate: SegmentedSelectorViewDelegate?

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let theme: ElementsAppearance
    private var itemViews: [SegmentedSelectorItem: SegmentedItemView] = [:]

    init(items: [SegmentedSelectorItem],
         disabledItems: Set<SegmentedSelectorItem>,
         theme: ElementsAppearance) {
        self.theme = theme
        super.init(frame: .zero)
        setupView()
        update(items: items, disabledItems: disabledItems, selectedItem: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        // Add segmented control styling
        applyCornerRadius(appearance: theme)
        layer.borderWidth = theme.separatorWidth
        layer.borderColor = theme.colors.border.cgColor
        stackView.backgroundColor = theme.colors.componentBackground
        stackView.applyCornerRadius(appearance: theme)
        // Clip the stackView instead of self so child backgrounds are clipped to rounded corners without affecting the border rendering
        stackView.clipsToBounds = true

        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    func update(items: [SegmentedSelectorItem], disabledItems: Set<SegmentedSelectorItem>, selectedItem: SegmentedSelectorItem?) {
        // If we have the same items as before, just update the disabled state
        if Set(items) == Set(itemViews.keys) {
            items.forEach { item in
                let isDisabled = disabledItems.contains(item)
                itemViews[item]?.updateDisabledState(isDisabled)
            }
        } else { // Otherwise, rebuild the view with the new items
            stackView.arrangedSubviews.forEach {
                $0.removeFromSuperview()
            }
            itemViews.removeAll()

            // Add views for each item with separators
            for (index, item) in items.enumerated() {
                let isDisabled = disabledItems.contains(item)
                let position: SegmentedItemView.Position = {
                    if items.count == 1 { return .only }
                    if index == 0 { return .first }
                    if index == items.count - 1 { return .last }
                    return .middle
                }()
                let itemView = SegmentedItemView(
                    item: item,
                    isDisabled: isDisabled,
                    position: position,
                    theme: theme
                )

                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(itemTapped(_:)))
                itemView.addGestureRecognizer(tapGesture)
                itemView.isUserInteractionEnabled = !isDisabled

                stackView.addArrangedSubview(itemView)
                itemViews[item] = itemView

                // Add separator between segments (except after the last one)
                if index < items.count - 1 {
                    let separator = UIView()
                    separator.translatesAutoresizingMaskIntoConstraints = false
                    separator.backgroundColor = theme.colors.divider
                    stackView.addArrangedSubview(separator)
                    NSLayoutConstraint.activate([
                        separator.widthAnchor.constraint(equalToConstant: theme.separatorWidth),
                    ])
                }
            }
        }
        if let selectedItem, let itemView = itemViews[selectedItem] {
            itemView.select(true, animated: false)
        }
    }

    func select(_ item: SegmentedSelectorItem?, animated: Bool) {
        // Deselect all, then select the new item
        for (viewItem, itemView) in itemViews where viewItem != item {
            itemView.select(false, animated: animated)
        }
        if let item = item, let itemView = itemViews[item] {
            itemView.select(true, animated: animated)
        }
    }

    @objc private func itemTapped(_ sender: UITapGestureRecognizer) {
        guard let itemView = sender.view as? SegmentedItemView else { return }
        delegate?.didTap(itemView.item)
    }

#if !os(visionOS)
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        layer.borderColor = theme.colors.border.cgColor
    }
#endif

}

// MARK: - SegmentedItemView

/// A single tappable item icon with optional checkmark (segmented control style)
private final class SegmentedItemView: UIControl {
    let item: SegmentedSelectorItem
    private var isDisabled: Bool
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
        stack.spacing = 2
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    enum Position {
        case first, middle, last, only
    }

    private let position: Position
    private var leadingConstraint: NSLayoutConstraint?

    private static let padding: CGFloat = 6
    private static let liquidGlassOuterPadding: CGFloat = 10
    private static let liquidGlassSelectedLeadingPadding: CGFloat = 8

    init(item: SegmentedSelectorItem, isDisabled: Bool, position: Position, theme: ElementsAppearance) {
        self.item = item
        self.isDisabled = isDisabled
        self.position = position
        self.theme = theme
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        // Disable so touches pass through to this UIControl, preventing BottomSheetViewController's keyboard-dismiss gesture from firing.
        containerStack.isUserInteractionEnabled = false

        iconImageView.image = item.image

        let configuration = UIImage.SymbolConfiguration(weight: .medium)
        checkmarkImageView.image = UIImage(systemName: "checkmark", withConfiguration: configuration)
        checkmarkImageView.tintColor = theme.colors.bodyText

        // Add checkmark on the left, then icon on the right
        containerStack.addArrangedSubview(checkmarkImageView)
        containerStack.addArrangedSubview(iconImageView)

        addSubview(containerStack)

        // When Liquid Glass is enabled, the rounded style makes the outer segments feel crowded, so we add a little extra padding
        let isLiquidGlass = LiquidGlassDetector.isEnabledInMerchantApp && theme.cornerRadius == nil
        let outerPadding: CGFloat = isLiquidGlass ? Self.liquidGlassOuterPadding : Self.padding
        let leadingPadding: CGFloat = (position == .first || position == .only) ? outerPadding : Self.padding
        let trailingPadding: CGFloat = (position == .last || position == .only) ? outerPadding : Self.padding

        let leading = containerStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: leadingPadding)
        self.leadingConstraint = leading

        NSLayoutConstraint.activate([
            leading,
            containerStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -trailingPadding),
            containerStack.topAnchor.constraint(equalTo: topAnchor, constant: Self.padding),
            containerStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Self.padding),

            checkmarkImageView.widthAnchor.constraint(equalToConstant: 12),
            checkmarkImageView.heightAnchor.constraint(equalToConstant: 12),
        ])

        // Add accessibility
        isAccessibilityElement = true
        accessibilityLabel = item.accessibilityLabel
        accessibilityTraits = .button
        if isDisabled {
            iconImageView.alpha = 0.4
            accessibilityTraits.insert(.notEnabled)
        }
    }

    func select(_ selected: Bool, animated: Bool) {
        // When Liquid Glass is enabled, we inject some extra padding to the first item, but when it's selected, the checkmark adds some visual spacing, so we can decrease it a bit
        updateLiquidGlassLeadingPadding(isSelected: selected)

        if selected {
            let showSelection = {
                self.checkmarkImageView.isHidden = false
                self.checkmarkImageView.alpha = 1.0
                self.backgroundColor = self.theme.colors.border.withAlphaComponent(0.3)
            }
            if animated {
                UIView.animate(withDuration: 0.2) {
                    showSelection()
                }
            } else {
                showSelection()
            }
            self.accessibilityTraits.insert(.selected)
        } else { // instantly hide selection
            self.checkmarkImageView.isHidden = true
            self.backgroundColor = .clear
            self.accessibilityTraits.remove(.selected)
        }
    }

    private func updateLiquidGlassLeadingPadding(isSelected: Bool) {
        guard LiquidGlassDetector.isEnabledInMerchantApp,
              theme.cornerRadius == nil,
              position == .first || position == .only else {
            return
        }
        // When selected, the checkmark provides some visual spacing so decrease the amount of padding
        // When deselected, use the larger outer padding to avoid feeling cramped.
        let defaultPadding: CGFloat = (position == .first || position == .only) ? Self.liquidGlassOuterPadding : Self.padding
        leadingConstraint?.constant = isSelected ? Self.liquidGlassSelectedLeadingPadding : defaultPadding
    }

    func updateDisabledState(_ isDisabled: Bool) {
        guard isDisabled != self.isDisabled else { return }
        self.isDisabled = isDisabled
        // Update visual state
        isUserInteractionEnabled = !isDisabled
        iconImageView.alpha = isDisabled ? 0.4 : 1.0
        // If disabled, deselect it
        if isDisabled {
            select(false, animated: false)
            accessibilityTraits.insert(.notEnabled)
        } else {
            accessibilityTraits.remove(.notEnabled)
        }
    }
}

// MARK: - SegmentedSelectorItem

/// A struct that encapsulates the display information for a selectable item.
/// Uses type erasure with rawData to support any type.
@_spi(STP) public struct SegmentedSelectorItem: Hashable {
    public let rawData: String
    public let image: UIImage
    public let accessibilityLabel: String

    public init(rawData: String, image: UIImage, accessibilityLabel: String) {
        self.rawData = rawData
        self.image = image
        self.accessibilityLabel = accessibilityLabel
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.rawData == rhs.rawData
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawData)
    }
}

// MARK: - SegmentedSelectorViewDelegate

protocol SegmentedSelectorViewDelegate: AnyObject {
    func didTap(_ item: SegmentedSelectorItem)
}
