//
//  AUBECS.swift
//  StripeiOS
//
//  Created by Reshma Karthikeyan on 2/25/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//
import Foundation
import UIKit
import SafariServices
@_spi(STP) import StripeUICore

@objc(STP_Internal_AUBECSLegalTermsView)
final class AUBECSLegalTermsView: UIView {
    
    private let links: [String: URL] = [
        "terms": URL(string: "https://stripe.com/au-becs-dd-service-agreement/legal")!
    ]
    private let configuration: PaymentSheet.Configuration

    private lazy var textView: UITextView = {
        let textView = UITextView()
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.font = ElementsUITheme.current.fonts.caption
        textView.backgroundColor = .clear
        textView.attributedText = formattedLegalText()
        textView.textColor = ElementsUITheme.current.colors.secondaryText
        textView.linkTextAttributes = [.foregroundColor: ElementsUITheme.current.colors.primary]
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.clipsToBounds = false
        return textView
    }()

    init(configuration: PaymentSheet.Configuration, textAlignment: NSTextAlignment = .left) {
        self.configuration = configuration
        super.init(frame: .zero)
        self.textView.textAlignment = textAlignment
        addAndPinSubview(textView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        textView.font = .preferredFont(forTextStyle: .caption1)
    }

    private func formattedLegalText() -> NSAttributedString {
        let template = STPLocalizedString(
            "By providing your bank account details and confirming this payment, you agree to this Direct Debit Request and the <terms>Direct Debit Request service agreement</terms>, and authorise Stripe Payments Australia Pty Ltd ACN 160 180 343 Direct Debit User ID number 507156 (“Stripe”) to debit your account through the Bulk Electronic Clearing System (BECS) on behalf of %@ (the \"Merchant\") for any amounts separately communicated to you by the Merchant. You certify that you are either an account holder or an authorised signatory on the account listed above.",
            "Legal text shown when using AUBECS."
        )
        let string = String(format: template, configuration.merchantDisplayName)

        let formattedString = NSMutableAttributedString()

        STPStringUtils.parseRanges(from: string, withTags: Set<String>(links.keys)) { string, matches in
            formattedString.append(NSAttributedString(string: string))

            for (tag, range) in matches {
                guard range.rangeValue.location != NSNotFound else {
                    assertionFailure("Tag '<\(tag)>' not found")
                    continue
                }

                if let url = links[tag] {
                    formattedString.addAttributes([.link: url], range: range.rangeValue)
                }
            }
        }

        return formattedString
    }

}

private extension UIResponder {
    var parentViewController: UIViewController? {
        return next as? UIViewController ?? next?.parentViewController
    }
}
