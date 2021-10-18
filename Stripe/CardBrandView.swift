//
//  CardBrandView.swift
//  StripeiOS
//
//  Created by Ramon Torres on 8/31/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit
@_spi(STP) import StripeUICore

/// A view that displays a card brand icon/logo, or an icon to help the user locate the CVC
/// for a specific card brand.
final class CardBrandView: UIView {

    // TODO(ramont): unify icon sizes.

    /// The size of legacy icons.
    private static let legacyIconSize = CGSize(width: 29, height: 19)

    /// The target size of the rectangular part of the icon.
    private static let targetIconSize = CGSize(width: 24, height: 16)

    /// Icon padding.
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
    private static let iconPadding = UIEdgeInsets(top: 2, left: 0, bottom: 2, right: 3)

    /// Card brand to display.
    var cardBrand: STPCardBrand = .unknown {
        didSet {
            updateIcon()
        }
    }

    /// If `true`, the view will display the CVC hint icon instead of the card brand image.
    let showCVC: Bool

    override var intrinsicContentSize: CGSize {
        // Perform calculations in legacy icon space then convert to target scale
        let size = CGSize(
            width: Self.legacyIconSize.width + Self.iconPadding.left + Self.iconPadding.right,
            height: Self.legacyIconSize.height + Self.iconPadding.top + Self.iconPadding.bottom
        )

        let scaleX = Self.targetIconSize.width / Self.legacyIconSize.width
        let scaleY = Self.targetIconSize.height / Self.legacyIconSize.height

        return CGSize(
            width: round(size.width * scaleX),
            height: round(size.height * scaleY)
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
    init(showCVC: Bool = false) {
        self.showCVC = showCVC
        super.init(frame: .zero)

        self.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: self.topAnchor),
            imageView.bottomAnchor.constraint(
                equalTo: self.bottomAnchor,
                // Add bottom padding for vertical centering
                constant: -Self.iconPadding.bottom
            ),
            imageView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])

        updateIcon()
    }

    required init?(coder: NSCoder) {
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

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        updateIcon()
    }
}
