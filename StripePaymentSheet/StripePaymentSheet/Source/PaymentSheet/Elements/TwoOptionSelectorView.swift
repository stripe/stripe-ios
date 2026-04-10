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
    let displayText: String
    let accessibilityIdentifier: String
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

    private let appearance: PaymentSheet.Appearance

    private var leftItem: TwoOptionSelectorItem
    private var rightItem: TwoOptionSelectorItem
    private(set) var selectedItemId: String

    private let mainStackView = UIStackView()
    private let trackView = UIView()
    private let buttonsStackView = UIStackView()
    private let selectionIndicatorView = UIView()
    private(set) var captionLabel = UILabel()
    private var leftButton = UIButton(type: .system)
    private var rightButton = UIButton(type: .system)

    private let trackPadding: CGFloat = 3

    private var indicatorLeadingConstraint: NSLayoutConstraint?
    private var indicatorTrailingConstraint: NSLayoutConstraint?

    // MARK: - Init

    init(
        leftItem: TwoOptionSelectorItem,
        rightItem: TwoOptionSelectorItem,
        selectedItemId: String,
        caption: String? = nil,
        appearance: PaymentSheet.Appearance
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

    private func setupViews() {
        mainStackView.axis = .vertical
        mainStackView.spacing = 6
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(mainStackView)

        // Track background
        trackView.backgroundColor = appearance.colors.background
        trackView.layer.borderWidth = 0.5
        trackView.applyCornerRadiusOrConfiguration(for: appearance, ios26DefaultCornerStyle: .uniform)
        trackView.clipsToBounds = false

        // Selection indicator pill
        selectionIndicatorView.backgroundColor = appearance.colors.componentBackground
        selectionIndicatorView.applyCornerRadiusOrConfiguration(for: appearance, ios26DefaultCornerStyle: .uniform)

        selectionIndicatorView.layer.applyShadow(shadow: appearance.shadow.asElementThemeShadow)
        selectionIndicatorView.layer.borderWidth = 0.5
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

        captionLabel.font = appearance.scaledFont(for: appearance.font.base.regular, style: .caption1, maximumPointSize: 20)
        captionLabel.textColor = appearance.colors.textSecondary
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
        let borderColor = appearance.colors.componentBorder.withAlphaComponent(0.5).cgColor
        trackView.layer.borderColor = borderColor
        selectionIndicatorView.layer.borderColor = borderColor
    }

    private func configureButton(_ button: UIButton, item: TwoOptionSelectorItem) {
        button.setTitle(item.displayText, for: .normal)
        button.titleLabel?.font = appearance.scaledFont(for: appearance.font.base.medium, style: .footnote, maximumPointSize: 20)
        button.contentEdgeInsets = UIEdgeInsets(top: 7, left: 16, bottom: 7, right: 16)
        button.backgroundColor = .clear
        button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        button.accessibilityIdentifier = item.accessibilityIdentifier
    }

    private func updateButtonStyles(animated: Bool) {
        let isLeftSelected = leftItem.id == selectedItemId

        leftButton.setTitleColor(isLeftSelected ? appearance.colors.componentText : appearance.colors.textSecondary, for: .normal)
        rightButton.setTitleColor(!isLeftSelected ? appearance.colors.componentText : appearance.colors.textSecondary, for: .normal)

        leftButton.titleLabel?.font = appearance.scaledFont(for: appearance.font.base.medium, style: .footnote, maximumPointSize: 20)
        rightButton.titleLabel?.font = appearance.scaledFont(for: appearance.font.base.medium, style: .footnote, maximumPointSize: 20)
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
