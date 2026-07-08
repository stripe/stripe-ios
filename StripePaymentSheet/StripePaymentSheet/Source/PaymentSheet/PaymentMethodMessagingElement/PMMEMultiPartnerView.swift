//
//  PMMEMultiPartnerView.swift
//  StripePaymentSheet
//
//  Created by George Birch on 10/29/25.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
#if canImport(UIKit)
import UIKit
#else
import Foundation
#endif

class PMMEMultiPartnerView: UIView {

    private let logoSets: [PaymentMethodMessagingElement.LogoSet]
    private let promotion: String
    private let learnMoreText: String
    private let infoUrl: URL
    private let messagingAppearance: PaymentMethodMessagingElement.Appearance

    private var logoViews = [UIImageView]()
    private let logoStack = UIStackView()
    private let mainStack = UIStackView()

    private lazy var promotionTextView: PMMEPromotionTextView = {
        PMMEPromotionTextView(foregroundColor: messagingAppearance.linkTextColor)
    }()

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
        return xToFontHeightRatio * messagingAppearance.scaledFont.capHeight
    }

    var customAccessibilityLabel: String {
        logoSets.reduce("") { $0 + $1.altText + ", " } + promotion + " " + learnMoreText
    }

    init(
        logoSets: [PaymentMethodMessagingElement.LogoSet],
        promotion: String,
        learnMoreText: String,
        infoUrl: URL,
        appearance: PaymentMethodMessagingElement.Appearance,
        textViewDelegate: UITextViewDelegate
    ) {
        self.logoSets = logoSets
        self.promotion = promotion
        self.learnMoreText = learnMoreText
        self.infoUrl = infoUrl
        self.messagingAppearance = appearance
        super.init(frame: .zero)

        promotionTextView.delegate = textViewDelegate
        setupView()
    }

    private func setupView() {
        mainStack.axis = .vertical
        mainStack.spacing = verticalPadding

        logoStack.axis = .horizontal
        logoStack.spacing = logoHorizontalPadding
        for _ in logoSets {
            // Empty placeholder for initialization, we'll populate with the correct light/dark asset in didMoveToSuperView()
            let imageView = ScalingImageView(appearance: messagingAppearance)
            imageView.contentMode = .left
            imageView.contentMode = .scaleAspectFill
            logoStack.addArrangedSubview(imageView)
            logoViews.append(imageView)
        }
        logoStack.addArrangedSubview(UIView()) // spacer view to push icons to leading edge
        mainStack.addArrangedSubview(logoStack)

        promotionTextView.attributedText = getPromotionAttributedString()
        mainStack.addArrangedSubview(promotionTextView)

        addAndPinSubview(mainStack)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // user interface style may be different because of the new superview overriding it
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        updateLogoStyles()
        promotionTextView.attributedText = getPromotionAttributedString()
    }

    #if !os(visionOS)
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateLogoStyles()
        promotionTextView.attributedText = getPromotionAttributedString()
        // icon view scales may have changed
        logoViews.forEach { $0.invalidateIntrinsicContentSize() }

        // Adjust padding if content size changed
        logoStack.spacing = logoHorizontalPadding
        mainStack.spacing = verticalPadding
    }
    #endif

    private func updateLogoStyles() {
        for (logoSet, logoViews) in zip(logoSets, logoViews) {
            // If we are in alwaysLight, alwaysDark, or flat, dark and light will both be populated with the appropriate asset
            logoViews.image = traitCollection.isDarkMode ? logoSet.dark : logoSet.light
        }
    }

    private func getPromotionAttributedString() -> NSMutableAttributedString {
        .pmmePromoString(
            font: messagingAppearance.scaledFont,
            textColor: messagingAppearance.textColor,
            template: promotion,
            substitution: nil,
            learnMoreText: learnMoreText,
            learnMoreUrl: infoUrl
        )
    }
}

// UIImageView that scales according to the appearance's font size (including dynamic type)
class ScalingImageView: UIImageView {

    let messagingAppearance: PaymentMethodMessagingElement.Appearance

    init(appearance: PaymentMethodMessagingElement.Appearance) {
        self.messagingAppearance = appearance
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        guard let image else { return CGSize(width: -1, height: -1) }
        return image.sizeMatchingFont(messagingAppearance.scaledFont, additionalScale: 2.0)
    }
}
