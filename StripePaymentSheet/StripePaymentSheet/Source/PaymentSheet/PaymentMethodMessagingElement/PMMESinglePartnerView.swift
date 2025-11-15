//
//  PMMESinglePartnerView.swift
//  StripePaymentSheet
//
//  Created by George Birch on 10/29/25.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

class PMMESinglePartnerView: UIView {

    private let logoSet: PaymentMethodMessagingElement.LogoSet
    private let promotion: String
    private let appearance: PaymentMethodMessagingElement.Appearance

    private let promotionLabel = UILabel()

    init(
        logoSet: PaymentMethodMessagingElement.LogoSet,
        promotion: String,
        appearance: PaymentMethodMessagingElement.Appearance
    ) {
        self.logoSet = logoSet
        self.promotion = promotion
        self.appearance = appearance
        super.init(frame: .zero)

        promotionLabel.attributedText = getPromotionAttributedString()
        promotionLabel.adjustsFontForContentSizeCategory = true
        promotionLabel.numberOfLines = 0
        addAndPinSubview(promotionLabel)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // user interface style may be different because of the new superview overriding it
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        promotionLabel.attributedText = getPromotionAttributedString()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
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
