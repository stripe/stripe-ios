//
//  PMMESinglePartnerView.swift
//  StripePaymentSheet
//
//  Created by George Birch on 10/29/25.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

class PMMESinglePartnerView: PMMEUIView {

    private let logoSet: PaymentMethodMessagingElement.LogoSet
    private let promotion: String
    private let appearance: PaymentMethodMessagingElement.Appearance

    private var logoViews = [UIImageView]()
    private let promotionLabel = UILabel()

    init(
        logoSet: PaymentMethodMessagingElement.LogoSet,
        infoUrl: URL,
        promotion: String,
        appearance: PaymentMethodMessagingElement.Appearance,
        didUpdateHeight: ((CGFloat) -> Void)? = nil
    ) {
        self.logoSet = logoSet
        self.promotion = promotion
        self.appearance = appearance
        super.init(infoUrl: infoUrl, appearance: appearance, didUpdateHeight: didUpdateHeight)

        promotionLabel.attributedText = getPromotionAttributedString()
        promotionLabel.adjustsFontForContentSizeCategory = true
        promotionLabel.numberOfLines = 0
        addArrangedSubview(promotionLabel)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        promotionLabel.attributedText = getPromotionAttributedString()
    }

    func getPromotionAttributedString() -> NSMutableAttributedString {
        NSMutableAttributedString.bnplPromoString(
            font: appearance.scaledFont,
            textColor: appearance.textColor,
            infoIconColor: appearance.infoIconColor ?? appearance.textColor,
            template: promotion,
            substitution: ("{partner}", traitCollection.isDarkMode ? logoSet.dark : logoSet.light)
        )
    }
}
