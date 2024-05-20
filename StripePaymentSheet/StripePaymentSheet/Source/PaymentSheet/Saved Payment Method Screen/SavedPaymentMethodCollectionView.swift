//
//  SavedPaymentMethodCollectionView.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 9/3/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

// MARK: - Constants
/// Entire cell size
private let cellSize: CGSize = CGSize(width: 100, height: 88)
/// Size of the rounded rectangle that contains the PM logo
let roundedRectangleSize = CGSize(width: 100, height: 64)
private let paymentMethodLogoSize: CGSize = CGSize(width: 54, height: 40)

// MARK: - SavedPaymentMethodCollectionView
/// For internal SDK use only
@objc(STP_Internal_SavedPaymentMethodCollectionView)
class SavedPaymentMethodCollectionView: UICollectionView {
    init(appearance: PaymentSheet.Appearance) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.sectionInset = UIEdgeInsets(
            top: 0, left: PaymentSheetUI.defaultPadding, bottom: 0,
            right: PaymentSheetUI.defaultPadding)
        layout.itemSize = cellSize
        layout.minimumInteritemSpacing = 12
        super.init(frame: .zero, collectionViewLayout: layout)

        showsHorizontalScrollIndicator = false
        backgroundColor = appearance.colors.background

        register(
            PaymentOptionCell.self, forCellWithReuseIdentifier: PaymentOptionCell.reuseIdentifier)
    }

    var isRemovingPaymentMethods: Bool = false

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 100)
    }
}

// MARK: - Cells

protocol PaymentOptionCellDelegate: AnyObject {
    func paymentOptionCellDidSelectRemove(
        _ paymentOptionCell: SavedPaymentMethodCollectionView.PaymentOptionCell)
    func paymentOptionCellDidSelectEdit(
        _ paymentOptionCell: SavedPaymentMethodCollectionView.PaymentOptionCell)
}

extension SavedPaymentMethodCollectionView {

    /// A rounded, shadowed cell with an icon (e.g. Apple Pay, VISA, ➕) and some text at the bottom.
    /// Has a green outline when selected
    class PaymentOptionCell: UICollectionViewCell, EventHandler {
        static let reuseIdentifier = "PaymentOptionCell"

        lazy var label: UILabel = {
            let label = UILabel()
            label.font = appearance.scaledFont(for: appearance.font.base.medium, style: .footnote, maximumPointSize: 20)
            label.textColor = appearance.colors.text
            label.adjustsFontForContentSizeCategory = true
            return label
        }()
        let paymentMethodLogo: UIImageView = UIImageView()
        let plus: CircleIconView = CircleIconView(icon: .icon_plus,
                                                  fillColor: UIColor.dynamic(
            light: .systemGray5, dark: .tertiaryLabel))
        lazy var selectedIcon: CircleIconView = CircleIconView(icon: .icon_checkmark, fillColor: appearance.colors.primary)
        lazy var shadowRoundedRectangle: ShadowedRoundedRectangle = {
            return ShadowedRoundedRectangle(appearance: appearance)
        }()
        lazy var accessoryButton: CircularButton = {
            let button = CircularButton(style: .remove,
                                        dangerColor: appearance.colors.danger)
            button.backgroundColor = appearance.colors.danger
            button.isAccessibilityElement = true
            button.accessibilityLabel = String.Localized.remove
            button.accessibilityIdentifier = "Remove"
            return button
        }()

        fileprivate var viewModel: SavedPaymentOptionsViewController.Selection?

        var isRemovingPaymentMethods: Bool = false {
            didSet {
                update()
            }
        }

        weak var delegate: PaymentOptionCellDelegate?
        var appearance = PaymentSheet.Appearance.default {
            didSet {
                update()
                shadowRoundedRectangle.appearance = appearance
            }
        }

        var cbcEligible: Bool = false
        var allowsPaymentMethodRemoval: Bool = true

        /// Indicates whether the cell should be editable or just removable.
        /// If the card is a co-branded card and the merchant is eligible for card brand choice, then
        /// the cell should be editable. Otherwise, it should be just removable.
        var shouldAllowEditing: Bool {
            return (viewModel?.isCoBrandedCard ?? false) && cbcEligible
        }

        // MARK: - UICollectionViewCell

        override init(frame: CGRect) {
            super.init(frame: frame)

            [paymentMethodLogo, plus, selectedIcon].forEach {
                shadowRoundedRectangle.addSubview($0)
                $0.translatesAutoresizingMaskIntoConstraints = false
            }

            // Accessibility
            // Subviews of an accessibility element are ignored
            isAccessibilityElement = false
            // We choose the rectangle to represent the cell
            label.isAccessibilityElement = false
            accessibilityElements = [shadowRoundedRectangle, accessoryButton]
            shadowRoundedRectangle.isAccessibilityElement = true
            shadowRoundedRectangle.accessibilityTraits = [.button]

            paymentMethodLogo.contentMode = .scaleAspectFit
            accessoryButton.addTarget(self, action: #selector(didSelectAccessory), for: .touchUpInside)
            let views = [
                label, shadowRoundedRectangle, paymentMethodLogo, plus, selectedIcon, accessoryButton,
            ]
            views.forEach {
                $0.translatesAutoresizingMaskIntoConstraints = false
                contentView.addSubview($0)
            }
            NSLayoutConstraint.activate([
                shadowRoundedRectangle.topAnchor.constraint(equalTo: contentView.topAnchor),
                shadowRoundedRectangle.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                shadowRoundedRectangle.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                shadowRoundedRectangle.widthAnchor.constraint(
                    equalToConstant: roundedRectangleSize.width),
                shadowRoundedRectangle.heightAnchor.constraint(
                    equalToConstant: roundedRectangleSize.height),

                label.topAnchor.constraint(
                    equalTo: shadowRoundedRectangle.bottomAnchor, constant: 4),
                label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
                label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 2),
                label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

                paymentMethodLogo.centerXAnchor.constraint(
                    equalTo: shadowRoundedRectangle.centerXAnchor),
                paymentMethodLogo.centerYAnchor.constraint(
                    equalTo: shadowRoundedRectangle.centerYAnchor),
                paymentMethodLogo.widthAnchor.constraint(
                    equalToConstant: paymentMethodLogoSize.width),
                paymentMethodLogo.heightAnchor.constraint(
                    equalToConstant: paymentMethodLogoSize.height),

                plus.centerXAnchor.constraint(equalTo: shadowRoundedRectangle.centerXAnchor),
                plus.centerYAnchor.constraint(equalTo: shadowRoundedRectangle.centerYAnchor),
                plus.widthAnchor.constraint(equalToConstant: 32),
                plus.heightAnchor.constraint(equalToConstant: 32),

                selectedIcon.widthAnchor.constraint(equalToConstant: 26),
                selectedIcon.heightAnchor.constraint(equalToConstant: 26),
                selectedIcon.trailingAnchor.constraint(
                    equalTo: shadowRoundedRectangle.trailingAnchor, constant: 6),
                selectedIcon.bottomAnchor.constraint(
                    equalTo: shadowRoundedRectangle.bottomAnchor, constant: 6),

                accessoryButton.trailingAnchor.constraint(
                    equalTo: shadowRoundedRectangle.trailingAnchor, constant: 6),
                accessoryButton.topAnchor.constraint(
                    equalTo: shadowRoundedRectangle.topAnchor, constant: -6),
            ])
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        #if !canImport(CompositorServices)
        override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
            super.traitCollectionDidChange(previousTraitCollection)
            update()
        }
        #endif

        override var isSelected: Bool {
            didSet {
                update()
            }
        }

        override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
            let translatedPoint = accessoryButton.convert(point, from: self)

            // Ensures taps on the accessory button are handled properly as it lives outside its cells' bounds
            if accessoryButton.bounds.contains(translatedPoint) && !accessoryButton.isHidden {
                return accessoryButton.hitTest(translatedPoint, with: event)
            }

            return super.hitTest(point, with: event)
        }

        // MARK: - Internal Methods

        func setViewModel(_ viewModel: SavedPaymentOptionsViewController.Selection, cbcEligible: Bool, allowsPaymentMethodRemoval: Bool) {
            paymentMethodLogo.isHidden = false
            plus.isHidden = true
            shadowRoundedRectangle.isHidden = false
            self.viewModel = viewModel
            self.cbcEligible = cbcEligible
            self.allowsPaymentMethodRemoval = allowsPaymentMethodRemoval
            update()
        }

        func handleEvent(_ event: STPEvent) {
            UIView.animate(withDuration: PaymentSheetUI.defaultAnimationDuration) {
                switch event {
                case .shouldDisableUserInteraction:
                    self.label.alpha = 0.6
                case .shouldEnableUserInteraction:
                    self.label.alpha = 1
                default:
                    break
                }
            }
        }

        // MARK: - Private Methods
        @objc
        private func didSelectAccessory() {
            if shouldAllowEditing {
                delegate?.paymentOptionCellDidSelectEdit(self)
            } else if allowsPaymentMethodRemoval {
                delegate?.paymentOptionCellDidSelectRemove(self)
            }
        }

        func attributedTextForLabel(paymentMethod: STPPaymentMethod) -> NSAttributedString? {
            if case .USBankAccount = paymentMethod.type {
                let iconImage = PaymentSheetImageLibrary.bankIcon(for: nil).withTintColor(.secondaryLabel)
                let iconImageAttachment = NSTextAttachment()
                // Inspiration from:
                // https://stackoverflow.com/questions/26105803/center-nstextattachment-image-next-to-single-line-uilabel/45161058#45161058
                let ratio = 0.75
                let iconHeight = iconImage.size.height * ratio
                let iconWidth = iconImage.size.width * ratio

                iconImageAttachment.bounds = CGRect(x: 0,
                                                    y: (label.font.capHeight - iconHeight).rounded() / 2,
                                                    width: iconWidth,
                                                    height: iconHeight)
                iconImageAttachment.image = iconImage
                let result = NSMutableAttributedString(string: "")

                let padding = NSTextAttachment()
                padding.bounds = CGRect(x: 0, y: 0, width: 5, height: 0)

                result.append(NSAttributedString(attachment: iconImageAttachment))
                result.append(NSAttributedString(attachment: padding))
                result.append(NSAttributedString(string: paymentMethod.paymentSheetLabel))
                return result
            }
            return nil
        }

        private func update() {
            if let viewModel = viewModel {
                switch viewModel {
                case .saved(let paymentMethod):
                    if let attributedText = attributedTextForLabel(paymentMethod: paymentMethod) {
                        label.attributedText = attributedText
                    } else {
                        label.text = paymentMethod.paymentSheetLabel
                    }
                    accessibilityIdentifier = label.text
                    shadowRoundedRectangle.accessibilityIdentifier = label.text
                    shadowRoundedRectangle.accessibilityLabel = paymentMethod.paymentSheetAccessibilityLabel
                    paymentMethodLogo.image = paymentMethod.makeSavedPaymentMethodCellImage()
                case .applePay:
                    // TODO (cleanup) - get this from PaymentOptionDisplayData?
                    label.text = String.Localized.apple_pay
                    accessibilityIdentifier = label.text
                    shadowRoundedRectangle.accessibilityIdentifier = label.text
                    shadowRoundedRectangle.accessibilityLabel = label.text
                    paymentMethodLogo.image = PaymentOption.applePay.makeSavedPaymentMethodCellImage()
                case .link:
                    label.text = STPPaymentMethodType.link.displayName
                    accessibilityIdentifier = label.text
                    shadowRoundedRectangle.accessibilityIdentifier = label.text
                    shadowRoundedRectangle.accessibilityLabel = label.text
                    paymentMethodLogo.image = PaymentOption.link(option: .wallet).makeSavedPaymentMethodCellImage()
                    paymentMethodLogo.tintColor = UIColor.linkNavLogo.resolvedContrastingColor(
                        forBackgroundColor: appearance.colors.componentBackground
                    )
                case .add:
                    label.text = STPLocalizedString(
                        "+ Add",
                        "Text for a button that, when tapped, displays another screen where the customer can add payment method details"
                    )
                    shadowRoundedRectangle.accessibilityLabel = String.Localized.add_new_payment_method
                    shadowRoundedRectangle.accessibilityIdentifier = "+ Add"
                    paymentMethodLogo.isHidden = true
                    plus.isHidden = false
                    plus.setNeedsDisplay()
                }
            }
            let applyDefaultStyle: () -> Void = { [self] in
                shadowRoundedRectangle.isEnabled = true
                shadowRoundedRectangle.isSelected = false
                label.textColor = appearance.colors.text
                paymentMethodLogo.alpha = 1
                plus.alpha = 1
                selectedIcon.isHidden = true
                layer.shadowOpacity = 0
            }

            if isRemovingPaymentMethods {
                if case .saved = viewModel {
                    if shouldAllowEditing {
                        accessoryButton.isHidden = false
                        accessoryButton.set(style: .edit, with: appearance.colors.danger)
                        accessoryButton.backgroundColor = UIColor.dynamic(
                            light: .systemGray5, dark: appearance.colors.componentBackground.lighten(by: 0.075))
                        accessoryButton.iconColor = appearance.colors.icon
                    } else if allowsPaymentMethodRemoval {
                        accessoryButton.isHidden = false
                        accessoryButton.set(style: .remove, with: appearance.colors.danger)
                        accessoryButton.backgroundColor = appearance.colors.danger
                        accessoryButton.iconColor = appearance.colors.danger.contrastingColor
                    }
                    contentView.bringSubviewToFront(accessoryButton)
                    applyDefaultStyle()

                } else {
                    accessoryButton.isHidden = true

                    // apply disabled style
                    shadowRoundedRectangle.isEnabled = false
                    paymentMethodLogo.alpha = 0.6
                    plus.alpha = 0.6
                    label.textColor = appearance.colors.text.disabledColor
                }

            } else if isSelected {
                accessoryButton.isHidden = true
                shadowRoundedRectangle.isEnabled = true
                label.textColor = appearance.colors.text
                paymentMethodLogo.alpha = 1
                plus.alpha = 1
                selectedIcon.isHidden = false
                selectedIcon.backgroundColor = appearance.colors.primary

                // Draw a border with primary color
                shadowRoundedRectangle.isSelected = true
            } else {
                accessoryButton.isHidden = true
                applyDefaultStyle()
            }
            accessoryButton.isAccessibilityElement = !accessoryButton.isHidden
            label.font = appearance.scaledFont(for: appearance.font.base.medium, style: .footnote, maximumPointSize: 20)

            shadowRoundedRectangle.accessibilityTraits = {
                if isRemovingPaymentMethods {
                    return [.notEnabled]
                } else {
                    if isSelected {
                        return [.button, .selected]
                    } else {
                        return [.button]
                    }
                }
            }()
        }

    }

    // A circle with an image in the middle
    class CircleIconView: UIView {
        let imageView: UIImageView

        override var backgroundColor: UIColor? {
            didSet {
                imageView.tintColor = backgroundColor?.contrastingColor
            }
        }

        override var intrinsicContentSize: CGSize {
            return CGSize(width: 20, height: 20)
        }

        required init(icon: Image, fillColor: UIColor) {
            imageView = UIImageView(image: icon.makeImage(template: true))
            super.init(frame: .zero)
            backgroundColor = fillColor

            // Set colors according to the icon
            switch icon {
            case .icon_plus:
                imageView.tintColor = .secondaryLabel
            case .icon_checkmark:
                imageView.tintColor = .white
            default:
                break
            }

            addSubview(imageView)
            imageView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
                imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            ])
            layer.masksToBounds = true
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            layer.cornerRadius = frame.width / 2
        }
    }
}
