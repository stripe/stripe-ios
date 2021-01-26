//
//  SavedPaymentMethodCollectionView.swift
//  Stripe
//
//  Created by Yuki Tokuhiro on 9/3/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

// MARK: - Constants
/// Entire cell size
private let cellSize: CGSize = CGSize(width: 100, height: 88)
/// Size of the rounded rectangle that contains the PM logo
let roundedRectangleSize = CGSize(width: 100, height: 64)
private let paymentMethodLogoSize: CGSize = CGSize(width: 54, height: 40)
let shadowOpacity: Float = 0.2
let shadowRadius: CGFloat = 1.5

// MARK: - SavedPaymentMethodCollectionView
class SavedPaymentMethodCollectionView: UICollectionView {
    init() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.sectionInset = UIEdgeInsets(top: 0, left: PaymentSheetUI.defaultPadding, bottom: 0, right: PaymentSheetUI.defaultPadding)
        layout.itemSize = cellSize
        layout.minimumInteritemSpacing = 12
        super.init(frame: .zero, collectionViewLayout: layout)

        showsHorizontalScrollIndicator = false
        backgroundColor = CompatibleColor.systemBackground

        register(PaymentOptionCell.self, forCellWithReuseIdentifier: PaymentOptionCell.reuseIdentifier)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 100)
    }
}

// MARK: - Cells

extension SavedPaymentMethodCollectionView {

    /// A rounded, shadowed cell with an icon (e.g. Apple Pay, VISA, ➕) and some text at the bottom.
    /// Has a green outline when selected
    class PaymentOptionCell: UICollectionViewCell, EventHandler {
        static let reuseIdentifier = "PaymentOptionCell"

        lazy var label: UILabel = {
            let label = UILabel()
            label.font = UIFont.preferredFont(forTextStyle: .footnote, weight: .medium)
            label.textColor = CompatibleColor.label
            return label
        }()
        let paymentMethodLogo: UIImageView = UIImageView()
        let plus: CircleIconView = CircleIconView(icon: .plus)
        let selectedIcon: CircleIconView = CircleIconView(icon: .checkmark)
        lazy var shadowRoundedRectangle: ShadowedRoundedRectangle = {
            let shadowRoundedRectangle = ShadowedRoundedRectangle()
            shadowRoundedRectangle.layoutMargins = UIEdgeInsets(top: 15, left: 24, bottom: 15, right: 24)
            return shadowRoundedRectangle
        }()

        // MARK: - UICollectionViewCell

        override init(frame: CGRect) {
            super.init(frame: frame)

            layer.shadowColor = UIColor.black.cgColor
            layer.shadowOpacity = shadowOpacity
            layer.shadowRadius = shadowRadius
            layer.shadowOffset = CGSize(width: 0, height: 1)

            [paymentMethodLogo, plus, selectedIcon].forEach {
                shadowRoundedRectangle.addSubview($0)
                $0.translatesAutoresizingMaskIntoConstraints = false
            }

            isAccessibilityElement = true
            paymentMethodLogo.contentMode = .scaleAspectFit
            let views = [label, shadowRoundedRectangle, paymentMethodLogo, plus, selectedIcon]
            views.forEach {
                $0.translatesAutoresizingMaskIntoConstraints = false
                contentView.addSubview($0)
            }
            NSLayoutConstraint.activate([
                shadowRoundedRectangle.topAnchor.constraint(equalTo: contentView.topAnchor),
                shadowRoundedRectangle.leftAnchor.constraint(equalTo: contentView.leftAnchor),
                shadowRoundedRectangle.rightAnchor.constraint(equalTo: contentView.rightAnchor),
                shadowRoundedRectangle.widthAnchor.constraint(equalToConstant: roundedRectangleSize.width),
                shadowRoundedRectangle.heightAnchor.constraint(equalToConstant: roundedRectangleSize.height),

                label.topAnchor.constraint(equalTo: shadowRoundedRectangle.bottomAnchor, constant: 4),
                label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
                label.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 2),
                label.rightAnchor.constraint(equalTo: contentView.rightAnchor),

                paymentMethodLogo.centerXAnchor.constraint(equalTo: shadowRoundedRectangle.centerXAnchor),
                paymentMethodLogo.centerYAnchor.constraint(equalTo: shadowRoundedRectangle.centerYAnchor),
                paymentMethodLogo.widthAnchor.constraint(equalToConstant: paymentMethodLogoSize.width),
                paymentMethodLogo.heightAnchor.constraint(equalToConstant: paymentMethodLogoSize.height),

                plus.centerXAnchor.constraint(equalTo: shadowRoundedRectangle.centerXAnchor),
                plus.centerYAnchor.constraint(equalTo: shadowRoundedRectangle.centerYAnchor),
                plus.widthAnchor.constraint(equalToConstant: 32),
                plus.heightAnchor.constraint(equalToConstant: 32),

                selectedIcon.widthAnchor.constraint(equalToConstant: 26),
                selectedIcon.heightAnchor.constraint(equalToConstant: 26),
                selectedIcon.trailingAnchor.constraint(equalTo: shadowRoundedRectangle.trailingAnchor, constant: 6),
                selectedIcon.bottomAnchor.constraint(equalTo: shadowRoundedRectangle.bottomAnchor, constant: 6),
            ])
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            layer.shadowPath = CGPath(ellipseIn: selectedIcon.frame, transform: nil)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
            update()
        }

        override var isSelected: Bool {
            didSet {
                update()
            }
        }

        // MARK: - Internal Methods

        func setViewModel(_ viewModel: SavedPaymentOptionsViewController.Selection) {
            paymentMethodLogo.isHidden = false
            plus.isHidden = true
            switch viewModel {
            case .saved(paymentMethod: _, label: let text, image: let image):
                label.text = text
                paymentMethodLogo.image = image
            case .applePay:
                // TODO (cleanup) - get this from PaymentOptionDisplayData?
                label.text = STPLocalizedString("Apple Pay", "Text for Apple Pay payment method")
                paymentMethodLogo.image = PaymentOption.applePay.makeImage()
            case .add:
                label.text = STPLocalizedString("+ Add card", "Text for a button that, when tapped, displays another screen where the customer can enter card details")
                paymentMethodLogo.isHidden = true
                plus.isHidden = false
                plus.setNeedsDisplay()
            }
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
        private func update() {
            if isSelected {
                selectedIcon.isHidden = false
                layer.shadowOpacity = shadowOpacity

                // Draw a green border
                shadowRoundedRectangle.layer.borderWidth = 2
                shadowRoundedRectangle.layer.borderColor = UIColor.systemGreen.cgColor
            } else {
                selectedIcon.isHidden = true
                layer.shadowOpacity = 0
                // Draw a outline in dark mode
                if #available(iOS 12.0, *) {
                    if traitCollection.userInterfaceStyle == .dark {
                        shadowRoundedRectangle.layer.borderWidth = 1
                        shadowRoundedRectangle.layer.borderColor = CompatibleColor.systemGray4.cgColor
                    } else {
                        shadowRoundedRectangle.layer.borderWidth = 0
                    }
                }
            }
            accessibilityLabel = label.text
            accessibilityTraits = isSelected ? [.selected] : []
        }

    }

    // A circle with an image in the middle
    class CircleIconView: UIView {
        let imageView: UIImageView

        required init(icon: Icon) {
            imageView = UIImageView(image: icon.makeImage())
            super.init(frame: .zero)

            // Set colors according to the icon
            switch icon {
            case .plus:
                imageView.tintColor = CompatibleColor.secondaryLabel
                backgroundColor = UIColor.dynamic(light: CompatibleColor.systemGray5, dark: CompatibleColor.tertiaryLabel)
            case .checkmark:
                imageView.tintColor = .white
                backgroundColor = .systemGreen
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

// The shadowed rounded rectangle that our cells use to display content
class ShadowedRoundedRectangle: UIView{
    let roundedRectangle: UIView
    let underShadowOpacity: Float = 0.5
    let underShadow: CALayer

    required init() {
        roundedRectangle = UIView()
        roundedRectangle.backgroundColor = UIColor.dynamic(light: CompatibleColor.systemBackground, dark: CompatibleColor.quaternarySystemFill)
        roundedRectangle.layer.cornerRadius = PaymentSheetUI.defaultButtonCornerRadius
        roundedRectangle.layer.masksToBounds = true

        underShadow = CALayer()
        super.init(frame: .zero)

        layer.cornerRadius = PaymentSheetUI.defaultButtonCornerRadius
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowRadius = shadowRadius
        layer.shadowColor = CompatibleColor.systemGray2.cgColor
        layer.shadowOpacity = shadowOpacity

        underShadow.shadowOffset = CGSize(width: 0, height: 1)
        underShadow.shadowRadius = 5
        underShadow.shadowOpacity = 0.5
        layer.addSublayer(underShadow)
        addSubview(roundedRectangle)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Update shadow paths based on current frame
        roundedRectangle.frame = bounds
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: 6).cgPath
        underShadow.shadowPath = UIBezierPath(roundedRect: roundedRectangle.bounds.inset(by: UIEdgeInsets(top: 5, left: 5, bottom: 0, right: 5)), cornerRadius: PaymentSheetUI.defaultButtonCornerRadius).cgPath

        // Turn off shadows in dark mode
        if #available(iOS 12.0, *) {
            if traitCollection.userInterfaceStyle == .dark {
                layer.shadowOpacity = 0
                underShadow.shadowOpacity = 0
            } else {
                layer.shadowOpacity = shadowOpacity
                underShadow.shadowOpacity = underShadowOpacity
            }
        }

        // Update shadow (cg)colors
        layer.shadowColor = CompatibleColor.systemGray2.cgColor
        underShadow.shadowColor = CompatibleColor.systemGray2.cgColor
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        setNeedsLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
