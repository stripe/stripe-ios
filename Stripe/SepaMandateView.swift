//
//  SepaMandateView.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 6/15/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit
@_spi(STP) import StripeUICore

/// For internal SDK use only
@objc(STP_Internal_SepaMandateView)
class SepaMandateView: UIView {
    private let theme: ElementsUITheme
    lazy var label: UILabel = {
        let label = UILabel()
        label.font = theme.fonts.caption
        label.textColor = theme.colors.secondaryText
        label.numberOfLines = 0
        return label
    }()
    
    init(merchantDisplayName: String, theme: ElementsUITheme = .default) {
        self.theme = theme
        super.init(frame: .zero)
        let localized = STPLocalizedString(
            "By providing your payment information and confirming this payment, you authorise (A) %@ and Stripe, our payment service provider, to send instructions to your bank to debit your account and (B) your bank to debit your account in accordance with those instructions. As part of your rights, you are entitled to a refund from your bank under the terms and conditions of your agreement with your bank. A refund must be claimed within 8 weeks starting from the date on which your account was debited. Your rights are explained in a statement that you can obtain from your bank. You agree to receive notifications for future debits up to 2 days before they occur.",
            "SEPA mandate text"
        )
        label.text = String(format: localized, merchantDisplayName)
        installConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func installConstraints() {
        addAndPinSubview(label)
    }
}
