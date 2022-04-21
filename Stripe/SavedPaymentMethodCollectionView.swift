//
//  SavedPaymentMethodCollectionView.swift
//  Stripe
//
//  Created by Yuki Tokuhiro on 9/3/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

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
            light: CompatibleColor.systemGray5, dark: CompatibleColor.tertiaryLabel))
        lazy var selectedIcon: CircleIconView = CircleIconView(icon: .icon_checkmark, fillColor: appearance.colors.primary)
        lazy var shadowRoundedRectangle: ShadowedRoundedRectangle = {
            let shadowRoundedRectangle = ShadowedRoundedRectangle(appearance: appearance)
            shadowRoundedRectangle.layoutMargins = UIEdgeInsets(
                top: 15, left: 24, bottom: 15, right: 24)
            return shadowRoundedRectangle
        }()
        lazy var deleteButton: CircularButton = {
            let button = CircularButton(style: .remove,
                                        dangerColor: appearance.colors.danger)
            button.backgroundColor = appearance.colors.danger
            button.isAccessibilityElement = true
            button.accessibilityLabel = String.Localized.remove
            button.accessibilityIdentifier = "Remove"
            return button
        }()

        fileprivate var viewModel: SavedPaymentOptionsViewController.Selection? = nil

        var isRemovingPaymentMethods: Bool = false {
            didSet {
                update()
            }
        }

        weak var delegate: PaymentOptionCellDelegate? = nil
        var appearance = PaymentSheet.Appearance.default {
            didSet {
                update()
                shadowRoundedRectangle.appearance = appearance
            }
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
            accessibilityElements = [shadowRoundedRectangle, deleteButton]
            shadowRoundedRectangle.isAccessibilityElement = true

            paymentMethodLogo.contentMode = .scaleAspectFit
            deleteButton.addTarget(self, action: #selector(didSelectDelete), for: .touchUpInside)
            let views = [
                label, shadowRoundedRectangle, paymentMethodLogo, plus, selectedIcon, deleteButton,
            ]
            views.forEach {
                $0.translatesAutoresizingMaskIntoConstraints = false
                contentView.addSubview($0)
            }
            NSLayoutConstraint.activate([
                shadowRoundedRectangle.topAnchor.constraint(equalTo: contentView.topAnchor),
                shadowRoundedRectangle.leftAnchor.constraint(equalTo: contentView.leftAnchor),
                shadowRoundedRectangle.rightAnchor.constraint(equalTo: contentView.rightAnchor),
                shadowRoundedRectangle.widthAnchor.constraint(
                    equalToConstant: roundedRectangleSize.width),
                shadowRoundedRectangle.heightAnchor.constraint(
                    equalToConstant: roundedRectangleSize.height),

                label.topAnchor.constraint(
                    equalTo: shadowRoundedRectangle.bottomAnchor, constant: 4),
                label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
                label.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 2),
                label.rightAnchor.constraint(equalTo: contentView.rightAnchor),

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

                deleteButton.trailingAnchor.constraint(
                    equalTo: shadowRoundedRectangle.trailingAnchor, constant: 6),
                deleteButton.topAnchor.constraint(
                    equalTo: shadowRoundedRectangle.topAnchor, constant: -6),
            ])
        }

        override func layoutSubviews() {
            super.layoutSubviews()
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
            super.traitCollectionDidChange(previousTraitCollection)
            update()
        }

        override var isSelected: Bool {
            didSet {
                update()
            }
        }
        
        override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
            let translatedPoint = deleteButton.convert(point, from: self)
            
            // Ensures taps on the delete button are handled properly as it lives outside its cells' bounds
            if (deleteButton.bounds.contains(translatedPoint) && !deleteButton.isHidden) {
                return deleteButton.hitTest(translatedPoint, with: event)
            }
            
            return super.hitTest(point, with: event)
        }

        // MARK: - Internal Methods

        func setViewModel(_ viewModel: SavedPaymentOptionsViewController.Selection) {
            paymentMethodLogo.isHidden = false
            plus.isHidden = true
            shadowRoundedRectangle.isHidden = false
            self.viewModel = viewModel
            update()
        }

        func handleEvent(_ event: STPEvent) {
            UIView.animate(withDuration: PaymentSheetUI.defaultAnimationDuration) {
                switch event {
                case .shouldDisableUserInteraction:
                    self.label.alpha = 0.6
                case .shouldEnableUserInteraction:
                    self.label.alpha = 1
                }
            }
        }

        // MARK: - Private Methods
        @objc
        private func didSelectDelete() {
            delegate?.paymentOptionCellDidSelectRemove(self)
        }

        func attributedTextForLabel(paymentMethod: STPPaymentMethod) -> NSAttributedString? {
            if case .USBankAccount = paymentMethod.type,
                let iconImage = STPImageLibrary.bankIcon(for: nil)
                .compatible_withTintColor(STPTheme.defaultTheme.secondaryForegroundColor) {

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
                    shadowRoundedRectangle.accessibilityIdentifier = label.text
                    shadowRoundedRectangle.accessibilityLabel = paymentMethod.accessibilityLabel
                    paymentMethodLogo.image = paymentMethod.makeCarouselImage(for: self)
                case .applePay:
                    // TODO (cleanup) - get this from PaymentOptionDisplayData?
                    label.text = STPLocalizedString("Apple Pay", "Text for Apple Pay payment method")
                    shadowRoundedRectangle.accessibilityIdentifier = label.text
                    shadowRoundedRectangle.accessibilityLabel = label.text
                    paymentMethodLogo.image = PaymentOption.applePay.makeCarouselImage(for: self)
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
                label.textColor = appearance.colors.text
                paymentMethodLogo.alpha = 1
                plus.alpha = 1
                selectedIcon.isHidden = true
                layer.shadowOpacity = 0
                shadowRoundedRectangle.layer.cornerRadius = appearance.cornerRadius
                shadowRoundedRectangle.layer.borderWidth = appearance.borderWidth
                shadowRoundedRectangle.layer.borderColor = appearance.colors.componentBorder.cgColor
            }

            if isRemovingPaymentMethods {
                if case .saved = viewModel {
                    deleteButton.isHidden = false
                    deleteButton.backgroundColor = appearance.colors.danger
                    deleteButton.iconColor = appearance.colors.danger.contrastingColor
                    contentView.bringSubviewToFront(deleteButton)
                    applyDefaultStyle()
                } else {
                    deleteButton.isHidden = true

                    // apply disabled style
                    shadowRoundedRectangle.isEnabled = false
                    paymentMethodLogo.alpha = 0.6
                    plus.alpha = 0.6
                    label.textColor = appearance.colors.text.disabledColor
                    shadowRoundedRectangle.layer.borderWidth = appearance.borderWidth
                    shadowRoundedRectangle.layer.borderColor = appearance.colors.componentBorder.cgColor
                }

            } else if isSelected {
                deleteButton.isHidden = true
                shadowRoundedRectangle.isEnabled = true
                label.textColor = appearance.colors.text
                paymentMethodLogo.alpha = 1
                plus.alpha = 1
                selectedIcon.isHidden = false
                selectedIcon.backgroundColor = appearance.colors.primary

                // Draw a border with primary color
                shadowRoundedRectangle.layer.borderWidth = appearance.borderWidth * 2
                shadowRoundedRectangle.layer.borderColor = appearance.colors.primary.cgColor
                shadowRoundedRectangle.layer.cornerRadius = appearance.cornerRadius
            } else {
                deleteButton.isHidden = true
                shadowRoundedRectangle.isEnabled = true
                applyDefaultStyle()
            }
            deleteButton.isAccessibilityElement = !deleteButton.isHidden
            shadowRoundedRectangle.roundedRectangle.backgroundColor = appearance.colors.componentBackground
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

        required init(icon: Image, fillColor: UIColor) {
            imageView = UIImageView(image: icon.makeImage(template: true))
            super.init(frame: .zero)
            backgroundColor = fillColor

            // Set colors according to the icon
            switch icon {
            case .icon_plus:
                imageView.tintColor = CompatibleColor.secondaryLabel
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
