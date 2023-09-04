//
//  PaymentMethodTypeCollectionView.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 12/4/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

/// A carousel of Payment Method types e.g. [Card, Alipay, SEPA Debit]
/// For internal SDK use only
@objc(STP_Internal_PaymentMethodTypeCollectionView)
class PaymentMethodTypeCollectionView: UICollectionView {
    // MARK: - Constants
    internal static let paymentMethodLogoSize: CGSize = CGSize(width: UIView.noIntrinsicMetric, height: 12)
    internal static let cellHeight: CGFloat = 52
    internal static let minInteritemSpacing: CGFloat = 12

    let reuseIdentifier: String = "PaymentMethodTypeCollectionView.PaymentTypeCell"

    let viewModel: PaymentMethodTypeSelectorViewModel
    let appearance: PaymentSheet.Appearance

    init(
        viewModel: PaymentMethodTypeSelectorViewModel,
        appearance: PaymentSheet.Appearance
    ) {
        assert(!viewModel.paymentMethodTypes.isEmpty, "At least one payment method type must be provided.")

        self.viewModel = viewModel
        self.appearance = appearance
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.sectionInset = UIEdgeInsets(
            top: 0, left: PaymentSheetUI.defaultPadding, bottom: 0,
            right: PaymentSheetUI.defaultPadding)
        layout.minimumInteritemSpacing = PaymentMethodTypeCollectionView.minInteritemSpacing
        super.init(frame: .zero, collectionViewLayout: layout)
        self.dataSource = self
        self.delegate = self
        selectItem(at: IndexPath(item: viewModel.selectedItemIndex, section: 0), animated: false, scrollPosition: [])

        showsHorizontalScrollIndicator = false
        backgroundColor = appearance.colors.background

        register(PaymentTypeCell.self, forCellWithReuseIdentifier: PaymentTypeCell.reuseIdentifier)
        clipsToBounds = false
        layer.masksToBounds = false
        accessibilityIdentifier = "PaymentMethodTypeCollectionView"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: PaymentMethodTypeCollectionView.cellHeight)
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout

extension PaymentMethodTypeCollectionView: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int)
        -> Int
    {
        return viewModel.paymentMethodTypes.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath)
        -> UICollectionViewCell
    {
        guard
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: PaymentMethodTypeCollectionView.PaymentTypeCell
                    .reuseIdentifier, for: indexPath)
                as? PaymentMethodTypeCollectionView.PaymentTypeCell,
            let appearance = (collectionView as? PaymentMethodTypeCollectionView)?.appearance
        else {
            assertionFailure()
            return UICollectionViewCell()
        }
        cell.paymentMethodType = viewModel.paymentMethodTypes[indexPath.item]
        cell.appearance = appearance
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        viewModel.selectItem(at: indexPath.item)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var useFixedSizeCells: Bool {
            // Prefer fixed size cells for iPads and Mac.
            if #available(iOS 14.0, macCatalyst 14.0, *) {
                return UIDevice.current.userInterfaceIdiom == .pad || UIDevice.current.userInterfaceIdiom == .mac
            } else {
                return UIDevice.current.userInterfaceIdiom == .pad
            }
        }

        if useFixedSizeCells {
            return CGSize(width: 100, height: PaymentMethodTypeCollectionView.cellHeight)
        } else {
            // When there are 2 PMs, make them span the width of the collection view
            // When there are not 2 PMs, show 3 full cells plus 30% of the next if present
            let numberOfCellsToShow = viewModel.paymentMethodTypes.count == 2 ? CGFloat(2) : CGFloat(3.3)

            let cellWidth = (collectionView.frame.width - (PaymentSheetUI.defaultPadding + (PaymentMethodTypeCollectionView.minInteritemSpacing * 3.0))) / numberOfCellsToShow
            let paymentMethodType = viewModel.paymentMethodTypes[indexPath.item]
            return CGSize(
                width: max(cellWidth, PaymentTypeCell.minWidth(for: paymentMethodType, appearance: appearance)),
                height: PaymentMethodTypeCollectionView.cellHeight
            )
        }
    }
}

// MARK: - Cells

extension PaymentMethodTypeCollectionView {
    class PaymentTypeCell: UICollectionViewCell, EventHandler {
        static let reuseIdentifier = "PaymentTypeCell"
        var paymentMethodType: PaymentSheet.PaymentMethodType = .card {
            didSet {
                update()
            }
        }

        var appearance: PaymentSheet.Appearance = PaymentSheet.Appearance.default {
            didSet {
                update()
            }
        }

        private lazy var label: UILabel = {
            let label = UILabel()
            label.numberOfLines = 1
            label.font = appearance.scaledFont(for: appearance.font.base.medium, style: .footnote, maximumPointSize: 20)
            label.adjustsFontSizeToFitWidth = true
            label.minimumScaleFactor = 0.75
            label.textColor = .label
            label.adjustsFontForContentSizeCategory = true
            return label
        }()
        private lazy var paymentMethodLogo: UIImageView = {
            let paymentMethodLogo = UIImageView()
            paymentMethodLogo.contentMode = .scaleAspectFit
            return paymentMethodLogo
        }()
        private lazy var shadowRoundedRectangle: ShadowedRoundedRectangle = {
            let shadowRoundedRectangle = ShadowedRoundedRectangle(appearance: appearance)
            shadowRoundedRectangle.layer.borderWidth = 1
            shadowRoundedRectangle.layoutMargins = UIEdgeInsets(
                top: 15, left: 24, bottom: 15, right: 24)
            return shadowRoundedRectangle
        }()
        lazy var paymentMethodLogoWidthConstraint: NSLayoutConstraint = {
            paymentMethodLogo.widthAnchor.constraint(equalToConstant: 0)
        }()

        // MARK: - UICollectionViewCell
        // static instance to calculate min width
        private static let sizingInstance = PaymentTypeCell(frame: .zero)
        // maps payment method type to (appearnceInstance, width) to avoid recalculation
        private static var widthCache = [String: (PaymentSheet.Appearance, CGFloat)]()

        class func minWidth(for paymentMethodType: PaymentSheet.PaymentMethodType, appearance: PaymentSheet.Appearance) -> CGFloat {
            let paymentMethodTypeString = PaymentSheet.PaymentMethodType.string(from: paymentMethodType) ?? "unknown"
            if let (cachedAppearance, cachedWidth) = widthCache[paymentMethodTypeString],
               cachedAppearance == appearance {
                return cachedWidth
            }
            sizingInstance.paymentMethodType = paymentMethodType
            sizingInstance.appearance = appearance
            let size = sizingInstance.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
            widthCache[paymentMethodTypeString] = (appearance, size.width)
            return size.width
        }

        override init(frame: CGRect) {
            super.init(frame: frame)

            [paymentMethodLogo, label].forEach {
                shadowRoundedRectangle.addSubview($0)
                $0.translatesAutoresizingMaskIntoConstraints = false
            }

            isAccessibilityElement = true
            contentView.addAndPinSubview(shadowRoundedRectangle)
            shadowRoundedRectangle.frame = bounds

            NSLayoutConstraint.activate([
                paymentMethodLogo.topAnchor.constraint(
                    equalTo: shadowRoundedRectangle.topAnchor, constant: 12),
                paymentMethodLogo.leadingAnchor.constraint(
                    equalTo: shadowRoundedRectangle.leadingAnchor, constant: 12),
                paymentMethodLogo.heightAnchor.constraint(
                    equalToConstant: PaymentMethodTypeCollectionView.paymentMethodLogoSize.height),
                paymentMethodLogoWidthConstraint,

                label.topAnchor.constraint(equalTo: paymentMethodLogo.bottomAnchor, constant: 4),
                label.bottomAnchor.constraint(
                    equalTo: shadowRoundedRectangle.bottomAnchor, constant: -8),
                label.leadingAnchor.constraint(equalTo: paymentMethodLogo.leadingAnchor),
                label.trailingAnchor.constraint(equalTo: shadowRoundedRectangle.trailingAnchor, constant: -12), // should be -const of paymentMethodLogo leftAnchor
            ])

            contentView.layer.cornerRadius = appearance.cornerRadius
            clipsToBounds = false
            layer.masksToBounds = false

            update()
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            contentView.layer.shadowPath =
                UIBezierPath(roundedRect: bounds, cornerRadius: contentView.layer.cornerRadius)
                .cgPath
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

        // MARK: - Internal Methods

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
            contentView.layer.cornerRadius = appearance.cornerRadius
            shadowRoundedRectangle.appearance = appearance
            label.text = paymentMethodType.displayName

            label.font = appearance.scaledFont(for: appearance.font.base.medium, style: .footnote, maximumPointSize: 20)
            let currPaymentMethodType = self.paymentMethodType
            let image = paymentMethodType.makeImage(forDarkBackground: appearance.colors.componentBackground.contrastingColor == .white) { [weak self] image in
                guard let strongSelf = self,
                      currPaymentMethodType == strongSelf.paymentMethodType else {
                    return
                }
                DispatchQueue.main.async {
                    strongSelf.updateImage(image)
                }
            }
            updateImage(image)

            if isSelected {
                // Set text color
                label.textColor = appearance.colors.primary

                // Set border
                shadowRoundedRectangle.layer.borderWidth = appearance.borderWidth * 2
                shadowRoundedRectangle.layer.borderColor = appearance.colors.primary.cgColor
            } else {
                // Set text color
                label.textColor = appearance.colors.componentText

                // Set border
                shadowRoundedRectangle.layer.borderWidth = appearance.borderWidth
                shadowRoundedRectangle.layer.borderColor = appearance.colors.componentBorder.cgColor
            }
            accessibilityLabel = label.text
            accessibilityTraits = isSelected ? [.selected] : []
            accessibilityIdentifier = PaymentSheet.PaymentMethodType.string(from: paymentMethodType)
        }
        private func updateImage(_ imageParam: UIImage) {
            var image = imageParam
            // tint icon primary color for a few PMs should be tinted the appearance primary color when selected
            if paymentMethodType.iconRequiresTinting  {
                image = image.withRenderingMode(.alwaysTemplate)
                paymentMethodLogo.tintColor = isSelected ? appearance.colors.primary : appearance.colors.componentBackground.contrastingColor
            }

            paymentMethodLogo.image = image
            paymentMethodLogoWidthConstraint.constant = paymentMethodLogoSize.height / image.size.height * image.size.width
            setNeedsLayout()
        }
    }
}
