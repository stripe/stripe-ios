//
//  AffirmCopyLabel.swift
//  StripePaymentSheet
//
//  Created by Reshma Karthikeyan on 2/22/22.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

/// For internal SDK use only
@objc(STP_Internal_AffirmCopyLabel)
class AffirmCopyLabel: UIView {

    let logo = NSTextAttachment()

    convenience init(theme: ElementsAppearance = .default) {
        self.init(frame: .zero)
        let affirmLabel = UILabel()

        let message = NSMutableAttributedString(string: STPLocalizedString("Pay over time with %@", "Pay over time with Affirm copy"))
        logo.image = PaymentSheetImageLibrary.affirmLogo()
        message.replaceOccurrences(of: "%@", with: logo)
        affirmLabel.attributedText = message
        affirmLabel.font = theme.fonts.subheadline
        affirmLabel.textColor = theme.colors.bodyText
        affirmLabel.numberOfLines = 0
        affirmLabel.sizeToFit()
        addAndPinSubview(affirmLabel)
    }

#if !canImport(CompositorServices)
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        logo.image = PaymentSheetImageLibrary.affirmLogo()
    }
#endif

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
