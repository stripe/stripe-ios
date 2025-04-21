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
private let cellSize: CGSize = CGSize(width: 106, height: 94)
private let cellSizeWithDefaultBadge: CGSize = CGSize(width: 106, height: 112)
/// Size of the rounded rectangle that contains the PM logo
let roundedRectangleSize = CGSize(width: 100, height: 64)
private let paymentMethodLogoSize: CGSize = CGSize(width: 54, height: 40)

// MARK: - SavedPaymentMethodCollectionView
/// For internal SDK use only
@objc(STP_Internal_SavedPaymentMethodCollectionView)
class SavedPaymentMethodCollectionView: UICollectionView {
    init(appearance: PaymentSheet.Appearance, needsVerticalPaddingForBadge: Bool = false) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.sectionInset = UIEdgeInsets(
            top: -6, left: PaymentSheetUI.defaultPadding, bottom: 0,
            right: PaymentSheetUI.defaultPadding)
        self.needsVerticalPaddingForBadge = needsVerticalPaddingForBadge
        layout.itemSize = cellSize
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 4
        super.init(frame: .zero, collectionViewLayout: layout)

        showsHorizontalScrollIndicator = false
        backgroundColor = appearance.colors.background

        register(
            PaymentOptionCell.self, forCellWithReuseIdentifier: PaymentOptionCell.reuseIdentifier)
    }

    var isRemovingPaymentMethods: Bool = false
    var needsVerticalPaddingForBadge: Bool

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        return needsVerticalPaddingForBadge && isRemovingPaymentMethods ? CGSize(width: UIView.noIntrinsicMetric, height: 118) : CGSize(width: UIView.noIntrinsicMetric, height: 100)
    }

    func updateLayout() {
        guard let layout = collectionViewLayout as? UICollectionViewFlowLayout else { return }
        let newCellSize = needsVerticalPaddingForBadge && isRemovingPaymentMethods ? cellSizeWithDefaultBadge : cellSize
        guard newCellSize != layout.itemSize else { return }
        layout.itemSize = newCellSize
        collectionViewLayout.invalidateLayout()
        invalidateIntrinsicContentSize()
    }
}

// MARK: - Cells

protocol PaymentOptionCellDelegate: AnyObject {
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
            let button = CircularButton(style: .edit)
            button.backgroundColor = appearance.colors.primary
            button.iconColor = appearance.colors.primary.contrastingColor
            button.isAccessibilityElement = true
            button.accessibilityLabel = String.Localized.edit
            return button
        }()
        lazy var defaultBadge: UILabel = {
            let label = UILabel()
            label.font = appearance.scaledFont(for: appearance.font.base.medium, style: .caption1, maximumPointSize: 20)
            label.textColor = appearance.colors.textSecondary
            label.adjustsFontForContentSizeCategory = true
            label.text = String.Localized.default_text
            label.isHidden = true
            return label
        }()

        fileprivate var viewModel: SavedPaymentOptionsViewController.Selection?

        var isRemovingPaymentMethods: Bool = false {
            didSet {
                updateVerticalConstraintsIfNeeded()
                update()
            }
        }

        func updateVerticalConstraintsIfNeeded() {
            if needsVerticalPaddingForBadge, isRemovingPaymentMethods {
                activateDefaultBadgeConstraints()
                defaultBadge.setHiddenIfNecessary(!showDefaultPMBadge)
            } else {
                deactivateDefaultBadgeConstraints()
                defaultBadge.setHiddenIfNecessary(true)
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
        var allowsPaymentMethodUpdate: Bool = false
        var allowsSetAsDefaultPM: Bool = false
        var needsVerticalPaddingForBadge: Bool = false
        var showDefaultPMBadge: Bool = false

        /// Indicates whether the cell for a saved payment method should display the edit icon.
        /// True if payment methods can be removed or edited
        var isEditable: Bool {
            guard PaymentSheet.supportedSavedPaymentMethods.contains(where: { viewModel?.savedPaymentMethod?.type == $0 }) else {
                return false
            }
            return allowsSetAsDefaultPM || allowsPaymentMethodRemoval || allowsPaymentMethodUpdate || (viewModel?.savedPaymentMethod?.isCoBrandedCard ?? false && cbcEligible)
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
                label, shadowRoundedRectangle, paymentMethodLogo, plus, selectedIcon, accessoryButton, defaultBadge
            ]
            views.forEach {
                $0.translatesAutoresizingMaskIntoConstraints = false
                contentView.addSubview($0)
            }
            NSLayoutConstraint.activate([
                shadowRoundedRectangle.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
                shadowRoundedRectangle.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                shadowRoundedRectangle.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -6),
                shadowRoundedRectangle.widthAnchor.constraint(
                    equalToConstant: roundedRectangleSize.width),
                shadowRoundedRectangle.heightAnchor.constraint(
                    equalToConstant: roundedRectangleSize.height),

                label.topAnchor.constraint(
                    equalTo: shadowRoundedRectangle.bottomAnchor, constant: 4),
                labelBottomConstraint,
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
                    equalTo: contentView.trailingAnchor, constant: 0),
                accessoryButton.topAnchor.constraint(
                    equalTo: contentView.topAnchor, constant: 0),

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

        private lazy var labelBottomConstraint: NSLayoutConstraint = {
            return label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        }()
        private lazy var labelHeightConstraint: NSLayoutConstraint = {
            return label.heightAnchor.constraint(equalToConstant: 20)
        }()
        private lazy var defaultBadgeConstraints: [NSLayoutConstraint] = {
            return [
                defaultBadge.topAnchor.constraint(
                    equalTo: label.bottomAnchor, constant: 2),
                defaultBadge.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
                defaultBadge.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 2),
                defaultBadge.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            ]
        }()

        // MARK: - Internal Methods
        func setViewModel(_ viewModel: SavedPaymentOptionsViewController.Selection, cbcEligible: Bool, allowsPaymentMethodRemoval: Bool, allowsPaymentMethodUpdate: Bool, allowsSetAsDefaultPM: Bool = false, needsVerticalPaddingForBadge: Bool = false, showDefaultPMBadge: Bool = false) {
            paymentMethodLogo.isHidden = false
            plus.isHidden = true
            shadowRoundedRectangle.isHidden = false
            self.viewModel = viewModel
            self.cbcEligible = cbcEligible
            self.allowsPaymentMethodRemoval = allowsPaymentMethodRemoval
            self.allowsPaymentMethodUpdate = allowsPaymentMethodUpdate
            self.allowsSetAsDefaultPM = allowsSetAsDefaultPM
            self.needsVerticalPaddingForBadge = needsVerticalPaddingForBadge
            self.showDefaultPMBadge = showDefaultPMBadge
            update()
        }

        func handleEvent(_ event: STPEvent) {
            UIView.animate(withDuration: PaymentSheetUI.defaultAnimationDuration) {
                switch event {
                case .shouldDisableUserInteraction:
                    self.label.alpha = 0.6
                    self.paymentMethodLogo.alpha = 0.6
                case .shouldEnableUserInteraction:
                    self.label.alpha = 1
                    self.paymentMethodLogo.alpha = 1
                default:
                    break
                }
            }
        }

        // MARK: - Private Methods
        @objc
        private func didSelectAccessory() {
            if isEditable {
                delegate?.paymentOptionCellDidSelectEdit(self)
            }
        }

        func attributedTextForLabel(paymentMethod: STPPaymentMethod) -> NSAttributedString? {
            if case .USBankAccount = paymentMethod.type {
                let iconImage = PaymentSheetImageLibrary.bankIcon(for: nil).withTintColor(appearance.colors.text)
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
            // Setting the image ends up implicitly using UITraitCollection.current, which is undefined in this context, so wrap this in `traitCollection.performAsCurrent` to ensure it uses this view's trait collection
            traitCollection.performAsCurrent {
                let overrideUserInterfaceStyle: UIUserInterfaceStyle = appearance.colors.componentBackground.isDark ? .dark : .light
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
                        paymentMethodLogo.image = paymentMethod.makeSavedPaymentMethodCellImage(overrideUserInterfaceStyle: overrideUserInterfaceStyle)
                    case .applePay:
                        // TODO (cleanup) - get this from PaymentOptionDisplayData?
                        label.text = String.Localized.apple_pay
                        accessibilityIdentifier = label.text
                        shadowRoundedRectangle.accessibilityIdentifier = label.text
                        shadowRoundedRectangle.accessibilityLabel = label.text
                        paymentMethodLogo.image = PaymentOption.applePay.makeSavedPaymentMethodCellImage(overrideUserInterfaceStyle: overrideUserInterfaceStyle)
                    case .link:
                        label.text = STPPaymentMethodType.link.displayName
                        accessibilityIdentifier = label.text
                        shadowRoundedRectangle.accessibilityIdentifier = label.text
                        shadowRoundedRectangle.accessibilityLabel = label.text
                        paymentMethodLogo.image = PaymentOption.link(option: .wallet).makeSavedPaymentMethodCellImage(overrideUserInterfaceStyle: overrideUserInterfaceStyle)
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
                    if case .saved = viewModel, isEditable {
                        accessoryButton.isHidden = false
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

        private func activateDefaultBadgeConstraints() {
            NSLayoutConstraint.deactivate([labelBottomConstraint])
            NSLayoutConstraint.activate([labelHeightConstraint] + defaultBadgeConstraints)
        }

        private func deactivateDefaultBadgeConstraints() {
            NSLayoutConstraint.deactivate(defaultBadgeConstraints + [labelHeightConstraint])
            NSLayoutConstraint.activate([labelBottomConstraint])
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
