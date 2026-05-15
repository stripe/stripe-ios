//
//  TwoOptionSelectorView.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 3/20/26.

@_spi(STP) import StripeUICore
import UIKit

/// A single item in a `TwoOptionSelectorView`.
struct TwoOptionSelectorItem: Equatable {
    let id: String
    let displayText: NSAttributedString
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
    var height: CGFloat { get }
    var font: UIFont { get }
    var sizeScaleFactor: CGFloat { get }
    var captionColor: UIColor { get }
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

    private let leftItem: TwoOptionSelectorItem
    private let rightItem: TwoOptionSelectorItem
    private(set) var selectedItemId: String

    private let mainStackView = UIStackView()
    private let trackView = UIView()
    private let buttonsStackView = UIStackView()
    private let selectionIndicatorView = UIView()
    private(set) var captionLabel = UILabel()
    private var leftButton = UIButton(type: .custom)
    private var rightButton = UIButton(type: .custom)

    private let trackPadding: CGFloat = 3

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

    private func trackAndPillCornerRadii() -> (track: CGFloat, pill: CGFloat) {
        let h = appearance.height
        let bw = appearance.borderWidth
        let maxTrack = max((h - bw) / 2, 0)
        let track = min(appearance.cornerRadius, maxTrack)
        let innerH = h - 2 * trackPadding
        let maxPill = innerH / 2
        let pill = max(0, min(track - trackPadding, maxPill))
        return (track, pill)
    }

    private func setupViews() {
        mainStackView.axis = .vertical
        mainStackView.spacing = 6
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(mainStackView)

        let (trackCornerRadius, pillCornerRadius) = trackAndPillCornerRadii()

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
        let leading = buttonsStackView.leadingAnchor.constraint(equalTo: trackView.leadingAnchor, constant: trackPadding)
        leading.priority = UILayoutPriority(999)
        let trailing = buttonsStackView.trailingAnchor.constraint(equalTo: trackView.trailingAnchor, constant: -trackPadding)
        trailing.priority = UILayoutPriority(999)

        NSLayoutConstraint.activate([
            buttonsStackView.topAnchor.constraint(equalTo: trackView.topAnchor, constant: trackPadding),
            leading,
            trailing,
            buttonsStackView.bottomAnchor.constraint(equalTo: trackView.bottomAnchor, constant: -trackPadding),
        ])

        let heightConstraint = trackView.heightAnchor.constraint(equalToConstant: appearance.height)
        heightConstraint.priority = UILayoutPriority(999)
        heightConstraint.isActive = true

        captionLabel.font = scaledFont(for: appearance.font, style: .caption1)
        captionLabel.textColor = appearance.captionColor
        captionLabel.numberOfLines = 0
        captionLabel.isHidden = true
        mainStackView.addArrangedSubview(captionLabel)

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
        button.setAttributedTitle(item.displayText, for: .normal)
        button.titleLabel?.font = scaledFont(for: appearance.font.medium, style: .footnote)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        button.backgroundColor = .clear
        button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        button.accessibilityIdentifier = item.accessibilityIdentifier
    }

    private func updateButtonStyles(animated: Bool) {
        let isLeftSelected = leftItem.id == selectedItemId
        let font = scaledFont(for: appearance.font.medium, style: .footnote)

        applyTitleColor(to: leftButton, item: leftItem, color: isLeftSelected ? appearance.selectedTextColor : appearance.unselectedTextColor, font: font)
        applyTitleColor(to: rightButton, item: rightItem, color: !isLeftSelected ? appearance.selectedTextColor : appearance.unselectedTextColor, font: font)
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

    // MARK: - Font Scaling

    private func scaledFont(for font: UIFont, style: UIFont.TextStyle) -> UIFont {
        let defaultTraitCollection = UITraitCollection(preferredContentSizeCategory: .large)
        let fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style, compatibleWith: defaultTraitCollection)
        let customFont = font.withSize(fontDescriptor.pointSize * appearance.sizeScaleFactor)
        return UIFontMetrics.default.scaledFont(for: customFont, maximumPointSize: 20)
    }

    // MARK: - Caption

    func updateCaption(_ caption: String?) {
        if let caption, !caption.isEmpty {
            captionLabel.text = caption
            captionLabel.isHidden = false
        } else {
            captionLabel.text = nil
            captionLabel.isHidden = true
        }
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
