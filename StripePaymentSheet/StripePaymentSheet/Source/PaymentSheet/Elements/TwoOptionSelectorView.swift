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
    private let buttonsStackView = UIStackView()
    private let captionLabel = UILabel()
    private var leftButton = UIButton(type: .system)
    private var rightButton = UIButton(type: .system)

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
        mainStackView.spacing = 8
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(mainStackView)

        buttonsStackView.axis = .horizontal
        buttonsStackView.spacing = 8
        buttonsStackView.distribution = .fillEqually
        mainStackView.addArrangedSubview(buttonsStackView)

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

        updateButtonStyles()
    }

    private func configureButton(_ button: UIButton, item: TwoOptionSelectorItem) {
        button.setTitle(item.displayText, for: .normal)
        button.titleLabel?.font = appearance.scaledFont(for: appearance.font.base.medium, style: .subheadline, maximumPointSize: 20)
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        button.applyCornerRadiusOrConfiguration(for: appearance, ios26DefaultCornerStyle: .capsule)
        button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        button.accessibilityIdentifier = item.accessibilityIdentifier
    }

    private func updateButtonStyles() {
        styleButton(leftButton, isSelected: leftItem.id == selectedItemId)
        styleButton(rightButton, isSelected: rightItem.id == selectedItemId)
    }

    private func styleButton(_ button: UIButton, isSelected: Bool) {
        button.backgroundColor = appearance.colors.componentBackground
        button.setTitleColor(appearance.colors.componentText, for: .normal)
        if isSelected {
            let selectedBorderWidth = appearance.selectedBorderWidth ?? appearance.borderWidth
            if selectedBorderWidth > 0 {
                button.layer.borderWidth = selectedBorderWidth * 1.5
            } else {
                button.layer.borderWidth = 1.5
            }
            button.layer.borderColor = appearance.colors.selectedComponentBorder?.cgColor ?? appearance.colors.primary.cgColor
        } else {
            button.layer.borderColor = appearance.colors.componentBorder.cgColor
            button.layer.borderWidth = appearance.borderWidth
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
        updateButtonStyles()
        if notifyDelegate {
            delegate?.twoOptionSelectorView(self, didSelectItemWithId: itemId)
        }
    }

#if !os(visionOS)
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateButtonStyles()
    }
#endif

    // MARK: - Enabled / Disabled

    func setEnabled(_ enabled: Bool) {
        leftButton.isEnabled = enabled
        rightButton.isEnabled = enabled
        alpha = enabled ? 1.0 : 0.6
    }
}
