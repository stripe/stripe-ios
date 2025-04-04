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

protocol PaymentMethodTypeCollectionViewDelegate: AnyObject {
    func didUpdateSelection(_ paymentMethodTypeCollectionView: PaymentMethodTypeCollectionView)
}

/// A carousel of Payment Method types e.g. [Card, Alipay, SEPA Debit]
/// For internal SDK use only
@objc(STP_Internal_PaymentMethodTypeCollectionView)
class PaymentMethodTypeCollectionView: UICollectionView {
    enum Error: Swift.Error {
        case unableToDequeueReusableCell
    }

    // MARK: - Constants
    internal static let paymentMethodLogoSize: CGSize = CGSize(width: UIView.noIntrinsicMetric, height: 12)
    internal static let cellHeight: CGFloat = 52
    internal static let minInteritemSpacing: CGFloat = 12

    let reuseIdentifier: String = "PaymentMethodTypeCollectionView.PaymentTypeCell"
    private(set) var selected: PaymentSheet.PaymentMethodType {
        didSet(old) {
            if old != selected {
                _delegate?.didUpdateSelection(self)
            }
        }
    }
    let paymentMethodTypes: [PaymentSheet.PaymentMethodType]
    let appearance: PaymentSheet.Appearance
    let currency: String?
    weak var _delegate: PaymentMethodTypeCollectionViewDelegate?

    private var incentive: PaymentMethodIncentive?

    init(
        paymentMethodTypes: [PaymentSheet.PaymentMethodType],
        initialPaymentMethodType: PaymentSheet.PaymentMethodType? = nil,
        appearance: PaymentSheet.Appearance,
        currency: String? = nil,
        incentive: PaymentMethodIncentive?,
        delegate: PaymentMethodTypeCollectionViewDelegate
    ) {
        stpAssert(!paymentMethodTypes.isEmpty, "At least one payment method type must be provided.")

        self.paymentMethodTypes = paymentMethodTypes
        self.incentive = incentive
        self._delegate = delegate
        let selectedItemIndex: Int = {
            if let initialPaymentMethodType = initialPaymentMethodType {
                return paymentMethodTypes.firstIndex(of: initialPaymentMethodType) ?? 0
            } else {
                return 0
            }
        }()
        self.selected = paymentMethodTypes[selectedItemIndex]
        self.appearance = appearance
        self.currency = currency
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.sectionInset = UIEdgeInsets(
            top: 0, left: PaymentSheetUI.defaultPadding, bottom: 0,
            right: PaymentSheetUI.defaultPadding)
        layout.minimumInteritemSpacing = PaymentMethodTypeCollectionView.minInteritemSpacing
        super.init(frame: .zero, collectionViewLayout: layout)
        self.dataSource = self
        self.delegate = self
        selectItem(at: IndexPath(item: selectedItemIndex, section: 0), animated: false, scrollPosition: [])

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

    func setIncentive(_ incentive: PaymentMethodIncentive?) {
        guard self.incentive != incentive, let index = self.indexPathsForSelectedItems?.first else {
            return
        }

        self.incentive = incentive

        // Prevent the selected cell from being unselected following the reload
        reloadItems(at: [index])
        selectItem(at: index, animated: false, scrollPosition: [])
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout

extension PaymentMethodTypeCollectionView: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int)
        -> Int
    {
        return paymentMethodTypes.count
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
            let errorAnalytic = ErrorAnalytic(event: .unexpectedPaymentSheetError,
                                              error: Error.unableToDequeueReusableCell)
            STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic)
            stpAssertionFailure()
            return UICollectionViewCell()
        }
        let paymentMethodType = paymentMethodTypes[indexPath.item]
        cell.paymentMethodType = paymentMethodType
        cell.currency = currency
        cell.promoBadgeText = incentive?.takeIfAppliesTo(paymentMethodType)?.displayText
        cell.appearance = appearance
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        selected = paymentMethodTypes[indexPath.item]
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var useFixedSizeCells: Bool {
            #if canImport(CompositorServices)
            return true
            #else
            // Prefer fixed size cells for iPads and Mac.
            if #available(iOS 14.0, macCatalyst 14.0, *) {
                return UIDevice.current.userInterfaceIdiom == .pad || UIDevice.current.userInterfaceIdiom == .mac
            } else {
                return UIDevice.current.userInterfaceIdiom == .pad
            }
            #endif
        }

        if useFixedSizeCells {
            return CGSize(width: 100, height: PaymentMethodTypeCollectionView.cellHeight)
        } else {
            // When there are 2 PMs, make them span the width of the collection view
            // When there are not 2 PMs, show 3 full cells plus 30% of the next if present
            let numberOfCellsToShow = paymentMethodTypes.count == 2 ? CGFloat(2) : CGFloat(3.3)

            let cellWidth = (collectionView.frame.width - (PaymentSheetUI.defaultPadding + (PaymentMethodTypeCollectionView.minInteritemSpacing * 3.0))) / numberOfCellsToShow
            return CGSize(width: max(cellWidth, PaymentTypeCell.minWidth(for: paymentMethodTypes[indexPath.item], appearance: appearance)), height: PaymentMethodTypeCollectionView.cellHeight)
        }
    }
}

// MARK: - Cells

extension PaymentMethodTypeCollectionView {
    class PaymentTypeCell: UICollectionViewCell, EventHandler {
        static let reuseIdentifier = "PaymentTypeCell"
        var currency: String?
        var paymentMethodType: PaymentSheet.PaymentMethodType = .stripe(.card) {
            didSet {
                update()
            }
        }

        var promoBadgeText: String? {
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
        private lazy var promoBadge: PromoBadgeView = {
            PromoBadgeView(appearance: appearance, tinyMode: true)
        }()
        private lazy var shadowRoundedRectangle: ShadowedRoundedRectangle = {
            return ShadowedRoundedRectangle(appearance: appearance)
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
            if let (cachedAppearance, cachedWidth) = widthCache[paymentMethodType.identifier],
               cachedAppearance == appearance {
                return cachedWidth
            }
            sizingInstance.paymentMethodType = paymentMethodType
            sizingInstance.appearance = appearance
            let size = sizingInstance.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
            widthCache[paymentMethodType.identifier] = (appearance, size.width)
            return size.width
        }

        override init(frame: CGRect) {
            super.init(frame: frame)

            [paymentMethodLogo, label, promoBadge].forEach {
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

                promoBadge.centerYAnchor.constraint(equalTo: paymentMethodLogo.centerYAnchor),
                promoBadge.trailingAnchor.constraint(equalTo: shadowRoundedRectangle.trailingAnchor, constant: -12),
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

        // MARK: - Internal Methods

        func handleEvent(_ event: STPEvent) {
            UIView.animate(withDuration: PaymentSheetUI.defaultAnimationDuration) {
                let views = [self.label, self.paymentMethodLogo, self.promoBadge].compactMap { $0 }
                switch event {
                case .shouldDisableUserInteraction:
                    views.forEach { $0.alpha = 0.6 }
                case .shouldEnableUserInteraction:
                    views.forEach { $0.alpha = 1 }
                default:
                    break
                }
            }
        }

        // MARK: - Private Methods
        var paymentMethodTypeOfCurrentImage: PaymentSheet.PaymentMethodType = .stripe(.unknown)
        private func update() {
            contentView.layer.cornerRadius = appearance.cornerRadius
            shadowRoundedRectangle.appearance = appearance
            label.text = paymentMethodType.displayName

            label.font = appearance.scaledFont(for: appearance.font.base.medium, style: .footnote, maximumPointSize: 20)
            let currPaymentMethodType = self.paymentMethodType
            let image = paymentMethodType.makeImage(forDarkBackground: appearance.colors.componentBackground.contrastingColor == .white, currency: currency) { [weak self] image in
                DispatchQueue.main.async {
                    guard let self, currPaymentMethodType == self.paymentMethodType else {
                        return
                    }
                    // Keep track of the PM type of the image
                    self.paymentMethodTypeOfCurrentImage = currPaymentMethodType
                    self.updateImage(image)
                }
            }
            // Hacky workaround: If we update unconditionally, we'll overwrite the current PM's valid image with a 1x1 placeholder here
            // until it gets overwritten again when the image download completion block runs.
            // Ideally, the DownloadManager API is refactored to not return a placeholder or an image; then we can set the image to a placeholder only when the payment method type of this cell changes.
            if paymentMethodTypeOfCurrentImage != self.paymentMethodType || image.size != CGSize(width: 1, height: 1) {
                updateImage(image)
            }

            promoBadge.isHidden = promoBadgeText == nil
            if let promoBadgeText {
                promoBadge.setAppearance(appearance)
                promoBadge.setText(promoBadgeText)
            }

            shadowRoundedRectangle.isSelected = isSelected
            // Set text color
            label.textColor = appearance.colors.componentText
            accessibilityLabel = label.text
            accessibilityTraits = isSelected ? [.selected] : []
            accessibilityIdentifier = paymentMethodType.identifier
        }
        private func updateImage(_ imageParam: UIImage) {
            var image = imageParam
            // tint icon for a few PMs to be a contrasting color to the component background
            if paymentMethodType.iconRequiresTinting  {
                image = image.withRenderingMode(.alwaysTemplate)
                paymentMethodLogo.tintColor = appearance.colors.componentBackground.contrastingColor
            }

            paymentMethodLogo.image = image
            paymentMethodLogoWidthConstraint.constant = paymentMethodLogoSize.height / image.size.height * image.size.width
            setNeedsLayout()
        }
    }
}
