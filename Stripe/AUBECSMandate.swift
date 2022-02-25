//
//  SepaMandateView.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 6/15/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit
import SafariServices
@_spi(STP) import StripeUICore

/// For internal SDK use only
//@objc(STP_Internal_AUBECSMandate)
//class AUBECSMandate: UIView {
//
//    private let links: [String: URL] = [
//            "terms": URL(string: "https://stripe.com/au-becs-dd-service-agreement/legal")!
//        ]
//
//    lazy var label: UILabel = {
//        let label = UILabel()
//        label.font = .preferredFont(forTextStyle: .caption1)
//        label.textColor = CompatibleColor.secondaryLabel
//        label.numberOfLines = 0
//        return label
//    }()
//
//    init() {
//        super.init(frame: .zero)
//
//        let string = "By providing your bank account details and confirming this payment, you agree to this Direct Debit Request and the <terms>Direct Debit Request service agreement</terms>, and authorise Stripe Payments Australia Pty Ltd ACN 160 180 343 Direct Debit User ID number 507156 (“Stripe”) to debit your account through the Bulk Electronic Clearing System (BECS) on behalf of Stripe Press (the \"Merchant\") for any amounts separately communicated to you by the Merchant. You certify that you are either an account holder or an authorised signatory on the account listed above."
//
//        let formattedString = NSMutableAttributedString()
//
//        STPStringUtils.parseRanges(from: string, withTags: Set<String>(links.keys)) { string, matches in
//            formattedString.append(NSAttributedString(string: string))
//
//            for (tag, range) in matches {
//                guard range.rangeValue.location != NSNotFound else {
//                    assertionFailure("Tag '<\(tag)>' not found")
//                    continue
//                }
//
//                if let url = links[tag] {
//                    formattedString.addAttributes([.link: url], range: range.rangeValue)
//                }
//            }
//        }
//        label.attributedText = formattedString
//        installConstraints()
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    fileprivate func installConstraints() {
//        addAndPinSubview(label)
//    }
//}
protocol AUBECSLegalTermsViewDelegate: AnyObject {
    /// Called when the user taps on a legal link.
    ///
    /// Implementation must return `true` if the link was handled. Returning `false`results in the link
    /// to open in the default browser.
    ///
    /// - Parameters:
    ///   - legalTermsView: The view that the user interacted with.
    ///   - url: URL of the link.
    /// - Returns: `true` if the link was handled by the delegate.
    func legalTermsView(_ legalTermsView: AUBECSLegalTermsView, didTapOnLinkWithURL url: URL) -> Bool
}

/// For internal SDK use only
@objc(STP_Internal_AUBECSLegalTermsView)
final class AUBECSLegalTermsView: UIView {
    
    private let links: [String: URL] = [
    "terms": URL(string: "https://stripe.com/au-becs-dd-service-agreement/legal")!
]

    weak var delegate: AUBECSLegalTermsViewDelegate?


    private lazy var textView: UITextView = {
        let textView = UITextView()
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.font = .preferredFont(forTextStyle: .caption1)
        textView.backgroundColor = .clear
        textView.attributedText = formattedLegalText()
        textView.textColor = CompatibleColor.secondaryLabel
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.delegate = self
        textView.clipsToBounds = false
        return textView
    }()

    init(textAlignment: NSTextAlignment = .left, delegate: AUBECSLegalTermsViewDelegate? = nil) {
        super.init(frame: .zero)
        self.textView.textAlignment = textAlignment
        self.delegate = delegate
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
        let string = STPLocalizedString(
            "By providing your bank account details and confirming this payment, you agree to this Direct Debit Request and the <terms>Direct Debit Request service agreement</terms>, and authorise Stripe Payments Australia Pty Ltd ACN 160 180 343 Direct Debit User ID number 507156 (“Stripe”) to debit your account through the Bulk Electronic Clearing System (BECS) on behalf of Stripe Press (the \"Merchant\") for any amounts separately communicated to you by the Merchant. You certify that you are either an account holder or an authorised signatory on the account listed above.",
            "Legal text shown when using AUBECS."
        )

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

extension AUBECSLegalTermsView: UITextViewDelegate {

    func textView(
        _ textView: UITextView,
        shouldInteractWith URL: URL,
        in characterRange: NSRange,
        interaction: UITextItemInteraction
    ) -> Bool {
        guard interaction == .invokeDefaultAction else {
            // Disable preview and actions
            return false
        }

        let safariVC = SFSafariViewController(url: URL)
        safariVC.dismissButtonStyle = .close
        safariVC.modalPresentationStyle = .overFullScreen

        guard let topController = window?.findTopMostPresentedViewController() else {
            return false
        }

        topController.present(safariVC, animated: true)
        return true
    }

}
