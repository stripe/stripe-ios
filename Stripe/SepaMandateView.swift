//
//  SepaMandateView.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 6/15/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit

class SepaMandateView: UIView {
    lazy var label: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = CompatibleColor.secondaryLabel
        label.numberOfLines = 0
        return label
    }()
    
    init(merchantDisplayName: String) {
        super.init(frame: .zero)
        let localized = STPLocalizedString(
            "By providing your payment information and confirming this payment, you authorise (A) %@ and Stripe, our payment service provider and/or PPRO, its local service provider, to send instructions to your bank to debit your account and (B) your bank to debit your account in accordance with those instructions. As part of your rights, you are entitled to a refund from your bank under the terms and conditions of your agreement with your bank. A refund must be claimed within 8 weeks starting from the date on which your account was debited. Your rights are explained in a statement that you can obtain from your bank. You agree to receive notifications for future debits up to 2 days before they occur.",
            "SEPA mandate text, as defined here: https://www.europeanpaymentscouncil.eu/other/core-sdd-mandate-translations"
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
