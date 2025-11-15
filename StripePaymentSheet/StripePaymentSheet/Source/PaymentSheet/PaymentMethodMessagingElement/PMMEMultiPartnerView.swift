//
//  PMMEMultiPartnerView.swift
//  StripePaymentSheet
//
//  Created by George Birch on 10/29/25.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

class PMMEMultiPartnerView: UIView {

    private let logoSets: [PaymentMethodMessagingElement.LogoSet]
    private let promotion: String
    private let appearance: PaymentMethodMessagingElement.Appearance

    private var logoViews = [UIImageView]()
    private let promotionLabel = UILabel()
    private let logoStack = UIStackView()
    private let mainStack = UIStackView()

    // With the default font, padding between logos is 8
    private var logoHorizontalPadding: CGFloat {
        fontScaled(8)
    }
    // With the default font, padding between logos and text is 4
    private var verticalPadding: CGFloat {
        fontScaled(4)
    }

    private func fontScaled(_ x: CGFloat) -> CGFloat {
        let defaultFontCapheight = PaymentMethodMessagingElement.Appearance().font.capHeight
        let xToFontHeightRatio = x / defaultFontCapheight
        return xToFontHeightRatio * appearance.scaledFont.capHeight
    }

    init(
        logoSets: [PaymentMethodMessagingElement.LogoSet],
        promotion: String,
        appearance: PaymentMethodMessagingElement.Appearance
    ) {
        self.logoSets = logoSets
        self.promotion = promotion
        self.appearance = appearance
        super.init(frame: .zero)

        setupView()
    }

    private func setupView() {
        mainStack.axis = .vertical
        mainStack.spacing = verticalPadding

        logoStack.axis = .horizontal
        logoStack.spacing = logoHorizontalPadding
        for logoSet in logoSets {
            // Empty placeholder for initialization, we'll populate with the correct light/dark asset in willMove()
            let imageView = ScalingImageView(appearance: appearance)
            imageView.contentMode = .left
            imageView.contentMode = .scaleAspectFill
            imageView.accessibilityLabel = logoSet.altText
            imageView.isAccessibilityElement = true
            logoStack.addArrangedSubview(imageView)
            logoViews.append(imageView)
        }
        logoStack.addArrangedSubview(UIView()) // spacer view to push icons to leading edge
        mainStack.addArrangedSubview(logoStack)

        promotionLabel.attributedText = getPromotionAttributedString()
        promotionLabel.adjustsFontForContentSizeCategory = true
        promotionLabel.numberOfLines = 0
        mainStack.addArrangedSubview(promotionLabel)

        addAndPinSubview(mainStack)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // user interface style may be different because of the new superview overriding it
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        updateLogoStyles()
        promotionLabel.attributedText = getPromotionAttributedString()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateLogoStyles()
        promotionLabel.attributedText = getPromotionAttributedString()
        // icon view scales may have changed
        logoViews.forEach { $0.invalidateIntrinsicContentSize() }

        // Adjust padding if content size changed
        logoStack.spacing = logoHorizontalPadding
        mainStack.spacing = verticalPadding
    }

    private func updateLogoStyles() {
        for (logoSet, logoViews) in zip(logoSets, logoViews) {
            // If we are in alwaysLight, alwaysDark, or flat, dark and light will both be populated with the appropriate asset
            logoViews.image = traitCollection.isDarkMode ? logoSet.dark : logoSet.light
        }
    }

    private func getPromotionAttributedString() -> NSMutableAttributedString? {
        return NSMutableAttributedString.bnplPromoString(
            font: appearance.scaledFont,
            textColor: appearance.textColor,
            infoIconColor: appearance.infoIconColor ?? appearance.textColor,
            template: promotion,
            substitution: nil
        )
    }
}

// UIImageView that scales according to the appearance's font size (including dynamic type)
class ScalingImageView: UIImageView {

    let appearance: PaymentMethodMessagingElement.Appearance

    init(appearance: PaymentMethodMessagingElement.Appearance) {
        self.appearance = appearance
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        guard let image else { return CGSize(width: -1, height: -1) }
        return image.sizeMatchingFont(appearance.scaledFont, additionalScale: 2.0)
    }
}
