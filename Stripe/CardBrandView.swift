//
//  CardBrandView.swift
//  StripeiOS
//
//  Created by Ramon Torres on 8/31/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit

/// A view that displays a card brand icon/logo, or an icon to help the user locate the CVC
/// for a specific card brand.
final class CardBrandView: UIView {

    /// Card brand to display.
    var cardBrand: STPCardBrand = .unknown {
        didSet {
            updateIcon()
        }
    }

    /// If `true`, the view will display the CVC hint icon instead of the card brand image.
    let showCVC: Bool

    private let imageView: UIImageView = {
        let imageView = UIImageView()
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
            imageView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
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
        invalidateIntrinsicContentSize()
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
