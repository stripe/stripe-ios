//
//  TwoOptionSelectorView.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 3/20/26.

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

/// A single item in a `TwoOptionSelectorView`.
struct TwoOptionSelectorItem: Equatable {
    let id: String
    let displayText: NSAttributedString
    let accessibilityLabel: String
    let accessibilityIdentifier: String
}

// MARK: - TwoOptionSelectorViewAppearance

/// The visual properties that `TwoOptionSelectorView` reads from its appearance.
protocol TwoOptionSelectorViewAppearance {
    var trackBackground: UIColor { get }
    var pillBackground: UIColor { get }
    var selectedTextColor: UIColor { get }
    var unselectedTextColor: UIColor { get }
    var borderColor: UIColor { get }
    var borderWidth: CGFloat { get }
    var cornerRadius: CGFloat { get }
    var contentVerticalPadding: CGFloat { get }
    var font: UIFont { get }
    var sizeScaleFactor: CGFloat { get }
    var captionColor: UIColor { get }
}

extension TwoOptionSelectorViewAppearance {
    func scaledFont(for font: UIFont, style: UIFont.TextStyle) -> UIFont {
        let defaultTraitCollection = UITraitCollection(preferredContentSizeCategory: .large)
        let fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style, compatibleWith: defaultTraitCollection)
        let customFont = font.withSize(fontDescriptor.pointSize * sizeScaleFactor)
        return UIFontMetrics.default.scaledFont(for: customFont, maximumPointSize: 20)
    }
}

// MARK: - TwoOptionSelectorViewDelegate

@MainActor
protocol TwoOptionSelectorViewDelegate: AnyObject {
    func twoOptionSelectorView(_ view: TwoOptionSelectorView, didSelectItemWithId id: String)
}

// MARK: - TwoOptionSelectorView

/// A two-option selector with an optional caption label below.
final class TwoOptionSelectorView: UIView {

    // MARK: - Properties

    weak var delegate: TwoOptionSelectorViewDelegate?

    private let appearance: TwoOptionSelectorViewAppearance

    private(set) var leftItem: TwoOptionSelectorItem
    private(set) var rightItem: TwoOptionSelectorItem
    private(set) var selectedItemId: String

    private let mainStackView = UIStackView()
    private let trackView = UIView()
    private let buttonsStackView = UIStackView()
    private let selectionIndicatorView = UIView()
    private(set) lazy var expandableDetailView = ExpandableDetailView(appearance: appearance)
    private var leftButton = UIButton(type: .custom)
    private var rightButton = UIButton(type: .custom)

    private static let trackPadding: CGFloat = 3
    private static let defaultContentHeight: CGFloat = 26

    private var indicatorLeadingConstraint: NSLayoutConstraint?
    private var indicatorTrailingConstraint: NSLayoutConstraint?

    // MARK: - Init

    init(
        leftItem: TwoOptionSelectorItem,
        rightItem: TwoOptionSelectorItem,
        selectedItemId: String,
        caption: String? = nil,
        appearance: TwoOptionSelectorViewAppearance
    ) {
        self.appearance = appearance
        self.leftItem = leftItem
        self.rightItem = rightItem
        self.selectedItemId = selectedItemId

        super.init(frame: .zero)
        setupViews()
        updateCaption(caption)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func trackAndPillCornerRadii(for height: CGFloat) -> (track: CGFloat, pill: CGFloat) {
        let bw = appearance.borderWidth
        let maxTrack = max((height - bw) / 2, 0)
        let track = min(appearance.cornerRadius, maxTrack)
        let pillHeight = height - 2 * Self.trackPadding
        let maxPill = pillHeight / 2
        let pill = min(max(track - Self.trackPadding, 0), maxPill)
        return (track, pill)
    }

    private func setupViews() {
        mainStackView.axis = .vertical
        mainStackView.spacing = 6
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(mainStackView)

        let trackHeight = Self.defaultContentHeight + 2 * appearance.contentVerticalPadding
        let (trackCornerRadius, pillCornerRadius) = trackAndPillCornerRadii(for: trackHeight)

        // Track background
        trackView.backgroundColor = appearance.trackBackground
        trackView.layer.borderWidth = appearance.borderWidth
        trackView.layer.cornerRadius = trackCornerRadius
        trackView.layer.cornerCurve = .circular
        trackView.clipsToBounds = false

        // Selection indicator pill
        selectionIndicatorView.backgroundColor = appearance.pillBackground
        selectionIndicatorView.layer.cornerRadius = pillCornerRadius
        selectionIndicatorView.layer.cornerCurve = .circular

        buttonsStackView.axis = .horizontal
        buttonsStackView.spacing = 0
        buttonsStackView.distribution = .fillEqually
        buttonsStackView.translatesAutoresizingMaskIntoConstraints = false

        trackView.addSubview(selectionIndicatorView)
        trackView.addSubview(buttonsStackView)
        mainStackView.addArrangedSubview(trackView)

        // Priority 999 on horizontal constraints so they break gracefully during
        // zero-width sizing passes (e.g. SwiftUI's fixedSize measuring).
        let leading = buttonsStackView.leadingAnchor.constraint(equalTo: trackView.leadingAnchor, constant: Self.trackPadding)
        leading.priority = UILayoutPriority(999)
        let trailing = buttonsStackView.trailingAnchor.constraint(equalTo: trackView.trailingAnchor, constant: -Self.trackPadding)
        trailing.priority = UILayoutPriority(999)

        NSLayoutConstraint.activate([
            buttonsStackView.topAnchor.constraint(equalTo: trackView.topAnchor, constant: Self.trackPadding),
            leading,
            trailing,
            buttonsStackView.bottomAnchor.constraint(equalTo: trackView.bottomAnchor, constant: -Self.trackPadding),
        ])

        let heightConstraint = trackView.heightAnchor.constraint(equalToConstant: Self.defaultContentHeight + 2 * appearance.contentVerticalPadding)
        heightConstraint.priority = UILayoutPriority(999)
        heightConstraint.isActive = true

        mainStackView.addArrangedSubview(expandableDetailView)

        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: topAnchor),
            mainStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            mainStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        configureButton(leftButton, item: leftItem)
        configureButton(rightButton, item: rightItem)
        buttonsStackView.addArrangedSubview(leftButton)
        buttonsStackView.addArrangedSubview(rightButton)

        // Indicator constraints
        selectionIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            selectionIndicatorView.topAnchor.constraint(equalTo: buttonsStackView.topAnchor),
            selectionIndicatorView.bottomAnchor.constraint(equalTo: buttonsStackView.bottomAnchor),
        ])

        indicatorLeadingConstraint = selectionIndicatorView.leadingAnchor.constraint(equalTo: leftButton.leadingAnchor)
        indicatorTrailingConstraint = selectionIndicatorView.trailingAnchor.constraint(equalTo: leftButton.trailingAnchor)
        indicatorLeadingConstraint?.isActive = true
        indicatorTrailingConstraint?.isActive = true

        updateBorderColors()
        updateButtonStyles(animated: false)
    }

    private func updateBorderColors() {
        trackView.layer.borderColor = appearance.borderColor.cgColor
    }

    private func configureButton(_ button: UIButton, item: TwoOptionSelectorItem) {
        var config = UIButton.Configuration.plain()
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
        config.attributedTitle = AttributedString(item.displayText)
        config.background.backgroundColor = .clear
        button.configuration = config
        button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        button.accessibilityLabel = item.accessibilityLabel
        button.accessibilityIdentifier = item.accessibilityIdentifier
    }

    private func updateButtonStyles(animated: Bool) {
        let isLeftSelected = leftItem.id == selectedItemId
        let font = appearance.scaledFont(for: appearance.font.medium, style: .footnote)

        applyTitleColor(to: leftButton, item: leftItem, color: isLeftSelected ? appearance.selectedTextColor : appearance.unselectedTextColor, font: font)
        applyTitleColor(to: rightButton, item: rightItem, color: !isLeftSelected ? appearance.selectedTextColor : appearance.unselectedTextColor, font: font)

        leftButton.accessibilityTraits = isLeftSelected ? [.button, .selected] : .button
        rightButton.accessibilityTraits = !isLeftSelected ? [.button, .selected] : .button

        indicatorLeadingConstraint?.isActive = false
        indicatorTrailingConstraint?.isActive = false

        if isLeftSelected {
            indicatorLeadingConstraint = selectionIndicatorView.leadingAnchor.constraint(equalTo: leftButton.leadingAnchor)
            indicatorTrailingConstraint = selectionIndicatorView.trailingAnchor.constraint(equalTo: leftButton.trailingAnchor)
        } else {
            indicatorLeadingConstraint = selectionIndicatorView.leadingAnchor.constraint(equalTo: rightButton.leadingAnchor)
            indicatorTrailingConstraint = selectionIndicatorView.trailingAnchor.constraint(equalTo: rightButton.trailingAnchor)
        }

        indicatorLeadingConstraint?.isActive = true
        indicatorTrailingConstraint?.isActive = true

        if animated {
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut) {
                self.layoutIfNeeded()
            }
        }
    }

    private func applyTitleColor(to button: UIButton, item: TwoOptionSelectorItem, color: UIColor, font: UIFont) {
        let styled = NSMutableAttributedString(attributedString: item.displayText)
        styled.addAttributes(
            [.foregroundColor: color, .font: font],
            range: NSRange(location: 0, length: styled.length)
        )
        button.setAttributedTitle(styled, for: .normal)
    }

    // MARK: - Update Items

    func updateItems(left: TwoOptionSelectorItem, right: TwoOptionSelectorItem) {
        leftItem = left
        rightItem = right
        updateButton(leftButton, item: leftItem)
        updateButton(rightButton, item: rightItem)
        updateButtonStyles(animated: false)
    }

    private func updateButton(_ button: UIButton, item: TwoOptionSelectorItem) {
        button.setAttributedTitle(item.displayText, for: .normal)
        button.accessibilityLabel = item.accessibilityLabel
        button.accessibilityIdentifier = item.accessibilityIdentifier
    }

    // MARK: - Caption

    func updateCaption(_ caption: String?, detailText: String? = nil) {
        expandableDetailView.update(caption: caption, detail: detailText)
    }

    // MARK: - Selection

    @objc private func buttonTapped(_ sender: UIButton) {
        let tappedId = sender === leftButton ? leftItem.id : rightItem.id
        select(tappedId, notifyDelegate: true)
    }

    func select(_ itemId: String, notifyDelegate: Bool = false) {
        guard itemId == leftItem.id || itemId == rightItem.id else { return }
        guard itemId != selectedItemId else { return }
        selectedItemId = itemId
        updateButtonStyles(animated: true)
        if notifyDelegate {
            delegate?.twoOptionSelectorView(self, didSelectItemWithId: itemId)
        }
        UIAccessibility.post(notification: .layoutChanged, argument: itemId == leftItem.id ? leftButton : rightButton)
    }

#if !os(visionOS)
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateBorderColors()
        updateButtonStyles(animated: false)
    }
#endif

    // MARK: - Enabled / Disabled

    func setEnabled(_ enabled: Bool) {
        leftButton.isEnabled = enabled
        rightButton.isEnabled = enabled
        alpha = enabled ? 1.0 : 0.6
    }
}
