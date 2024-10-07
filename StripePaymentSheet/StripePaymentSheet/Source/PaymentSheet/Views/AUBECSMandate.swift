//
//  AUBECSMandate.swift
//  StripePaymentSheet
//
//  Created by Reshma Karthikeyan on 2/25/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//
import Foundation
import SafariServices
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

@objc(STP_Internal_AUBECSLegalTermsView)
final class AUBECSLegalTermsView: UIView {

    private let links: [String: URL] = [
        "terms": URL(string: "https://stripe.com/au-becs-dd-service-agreement/legal")!
    ]
    private let configuration: PaymentSheetFormFactoryConfig

    private var theme: ElementsAppearance {
        return configuration.appearance.asElementsTheme
    }

    private lazy var textView: UITextView = {
        let textView = UITextView()
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.font = theme.fonts.caption
        textView.backgroundColor = .clear
        textView.attributedText = formattedLegalText()
        textView.textColor = theme.colors.secondaryText
        textView.linkTextAttributes = [.foregroundColor: theme.colors.primary]
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.clipsToBounds = false
        return textView
    }()

    init(configuration: PaymentSheetFormFactoryConfig, textAlignment: NSTextAlignment = .left) {
        self.configuration = configuration
        super.init(frame: .zero)
        self.textView.textAlignment = textAlignment
        addAndPinSubview(textView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

#if !canImport(CompositorServices)
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        textView.font = .preferredFont(forTextStyle: .caption1)
    }
#endif

    private func formattedLegalText() -> NSAttributedString {
        let template = STPLocalizedString(
            "By providing your bank account details and confirming this payment, you agree to this Direct Debit Request and the <terms>Direct Debit Request service agreement</terms>, and authorise Stripe Payments Australia Pty Ltd ACN 160 180 343 Direct Debit User ID number 507156 (“Stripe”) to debit your account through the Bulk Electronic Clearing System (BECS) on behalf of %@ (the \"Merchant\") for any amounts separately communicated to you by the Merchant. You certify that you are either an account holder or an authorised signatory on the account listed above.",
            "Legal text shown when using AUBECS."
        )
        let string = String(format: template, configuration.merchantDisplayName)
        return STPStringUtils.applyLinksToString(template: string, links: links)
    }

}

private extension UIResponder {
    var parentViewController: UIViewController? {
        return next as? UIViewController ?? next?.parentViewController
    }
}
