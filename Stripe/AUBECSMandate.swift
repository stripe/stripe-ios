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
@objc(STP_Internal_AUBECSMandate)
class AUBECSMandate: UIView {
    lazy var label: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = CompatibleColor.secondaryLabel
        label.numberOfLines = 0
        return label
    }()
    
    init() {
        super.init(frame: .zero)
        let localized = STPLocalizedString(
            "By providing your bank account details and confirming this payment, you agree to this Direct Debit Request and the Direct Debit Request service agreement, and authorise Stripe Payments Australia Pty Ltd ACN 160 180 343 Direct Debit User ID number 507156 (“Stripe”) to debit your account through the Bulk Electronic Clearing System (BECS) on behalf of Stripe Press (the \"Merchant\") for any amounts separately communicated to you by the Merchant. You certify that you are either an account holder or an authorised signatory on the account listed above.",
            "AU BECS mandate text"
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
