//
//  CardBrandView.swift
//  StripePaymentsUI
//
//  Created by Ramon Torres on 8/31/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore
import UIKit

/// A view that displays a card brand icon/logo, or an icon to help the user locate the CVC
/// for a specific card brand.
/// For internal SDK use only
@objc(STP_Internal_CardBrandView)
@_spi(STP) public final class CardBrandView: UIView {

    // TODO(ramont): unify icon sizes.

    /// The size of legacy icons.
    private static let legacyIconSize = CGSize(width: 29, height: 19)

    /// The target size of the rectangular part of the icon.
    /// internal so we can reuse size with other icon views (see LinkPaymentMethodPicker-CellContentView)
    @_spi(STP) public static let targetIconSize = CGSize(width: 24, height: 16)

    /// Padding built in to the icon.
    ///
    /// Card brand icons have baked-in top and right padding, so they align perfectly with the CVC icons. Bottom padding
    /// is then added for vertically centering the icon; thus it must match the top padding.
    ///
    ///  ```
    ///  +----------------+
    ///  |  PADDING       |
    ///  +------------+   |
    ///  |            |   |
    ///  |    LOGO    |   |
    ///  |            |   |
    ///  +------------+---+
    ///  |  B. PADDING    |
    ///  +----------------+
    ///  ```
    ///
    /// TODO(ramont): remove baked-in padding and perform alignment in code.
    private static let iconPadding = UIEdgeInsets(top: 2, left: 0, bottom: 0, right: 3)
    private var centeringPadding: UIEdgeInsets {
        return UIEdgeInsets(
            top: 0,
            left: centerHorizontally ? Self.iconPadding.right : 0,
            bottom: Self.iconPadding.top,
            right: 0
        )
    }

    /// Card brand to display.
    @_spi(STP) public var cardBrand: STPCardBrand = .unknown {
        didSet {
            updateIcon()
        }
    }

    /// If `true`, the view will display the CVC hint icon instead of the card brand image.
    let showCVC: Bool

    /// If `true`, will center the card brand icon horizontally in the containing view
    let centerHorizontally: Bool

    @_spi(STP) public override var intrinsicContentSize: CGSize {
        return size(for: Self.targetIconSize)
    }

    @_spi(STP) public func size(for targetSize: CGSize) -> CGSize {
        let padding = centeringPadding

        // The way this scaling works isn't perfect since the returned size has to map to a valid point value
        // (see rounding) which can change the effects of scaleX/scaleY. In practice this is only 1 pixel off so
        // acceptable for now.
        let scaleX =
            targetSize.width
            / (Self.legacyIconSize.width - Self.iconPadding.left - Self.iconPadding.right)
        let scaleY =
            targetSize.height
            / (Self.legacyIconSize.height - Self.iconPadding.top - Self.iconPadding.bottom)
        // We could adapt this for multiple screens, but probably not worth it (better solution is to remove padding from images)
        let screenScale = UIScreen.main.scale
        return CGSize(
            width: (round(Self.legacyIconSize.width * scaleX * screenScale) / screenScale)
                + padding.right + padding.left,
            height: (round(Self.legacyIconSize.height * scaleY * screenScale) / screenScale)
                + padding.top + padding.bottom
        )
    }

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    /// Creates and returns an initialized card brand view.
    /// - Parameter showCVC: Whether or not to show the CVC hint icon instead of the card brand image.
    /// - Parameter centerHorizontally: Whether or not the card icon should be centered horizontally
    @_spi(STP) public init(
        showCVC: Bool = false,
        centerHorizontally: Bool = false
    ) {
        self.showCVC = showCVC
        self.centerHorizontally = centerHorizontally
        super.init(frame: .zero)

        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: self.topAnchor, constant: centeringPadding.top),
            self.bottomAnchor.constraint(
                equalTo: imageView.bottomAnchor,
                constant: centeringPadding.bottom
            ),
            imageView.leftAnchor.constraint(
                equalTo: self.leftAnchor,
                constant: centeringPadding.left
            ),
            imageView.rightAnchor.constraint(
                equalTo: self.rightAnchor,
                constant: centeringPadding.right
            ),
        ])

        updateIcon()
    }

    required init?(
        coder: NSCoder
    ) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Updates the card brand, optionally animating the transition.
    /// - Parameters:
    ///   - newBrand: New card brand.
    ///   - animated: Whether or not to animate the transition.
    func setCardBrand(_ newBrand: STPCardBrand, animated: Bool) {
        let canAnimateTransition = imageView.image != self.image(for: newBrand)

        self.cardBrand = newBrand

        if animated && canAnimateTransition {
            performTransitionAnimation()
        }
    }

    // MARK: - Private Methods

    private func updateIcon() {
        imageView.image = image(for: cardBrand)
    }

    private func performTransitionAnimation() {
        // values match Elements animation
        let timingFunction = CAMediaTimingFunction(controlPoints: 0.075, 0.82, 0.165, 1)

        let scaleAnimation = CABasicAnimation(keyPath: "transform")
        scaleAnimation.duration = 0.4
        scaleAnimation.timingFunction = timingFunction
        scaleAnimation.fromValue = CATransform3DScale(CATransform3DIdentity, 0.7, 0.7, 1)
        scaleAnimation.toValue = CATransform3DIdentity

        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.duration = 0.7
        opacityAnimation.timingFunction = timingFunction
        opacityAnimation.fromValue = 0.0
        opacityAnimation.toValue = 1.0

        let animationGroup = CAAnimationGroup()
        animationGroup.animations = [scaleAnimation, opacityAnimation]

        self.layer.add(animationGroup, forKey: "transition")
    }

    /// Returns the most appropriate icon/image for the given card brand.
    /// - Parameter cardBrand: Card brand
    /// - Returns: Image.
    private func image(for cardBrand: STPCardBrand) -> UIImage {
        if showCVC {
            return cardBrand == .amex
                ? STPImageLibrary.safeImageNamed("card_cvc_amex_icon")
                : STPImageLibrary.safeImageNamed("card_cvc_icon")
        } else {
            return cardBrand == .unknown
                ? STPImageLibrary.safeImageNamed("card_unknown_icon")
                : STPImageLibrary.cardBrandImage(for: cardBrand)
        }
    }

    // MARK: - Callbacks

    @_spi(STP) public override func traitCollectionDidChange(
        _ previousTraitCollection: UITraitCollection?
    ) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateIcon()
    }
}
