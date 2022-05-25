//
//  LinkInstantDebitMandateView.swift
//  StripeiOS
//
//  Created by Ramon Torres on 2/17/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import UIKit
@_spi(STP) import StripeUICore

protocol LinkInstantDebitMandateViewDelegate: AnyObject {
    /// Called when the user taps on a link.
    ///
    /// - Parameters:
    ///   - mandateView: The view that the user interacted with.
    ///   - url: URL of the link.
    func instantDebitMandateView(_ mandateView: LinkInstantDebitMandateView, didTapOnLinkWithURL url: URL)
}

// TODO(ramont): extract common code with `LinkLegalTermsView`.

/// For internal SDK use only
@objc(STP_Internal_LinkInstantDebitMandateViewDelegate)
final class LinkInstantDebitMandateView: UIView {
    struct Constants {
        static let lineHeight: CGFloat = 1.5
    }

    // TODO(ramont): Update with final URLs
    private let links: [String: URL] = [
        "terms": URL(string: "https://stripe.com/ach-payments/authorization")!
    ]

    weak var delegate: LinkInstantDebitMandateViewDelegate?

    var textColor: UIColor? {
        get {
            return textView.textColor
        }
        set {
            textView.textColor = newValue
        }
    }

    private lazy var textView: UITextView = {
        let textView = UITextView()
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.font = LinkUI.font(forTextStyle: .caption)
        textView.backgroundColor = .clear
        textView.attributedText = formattedLegalText()
        textView.textColor = CompatibleColor.secondaryLabel
        textView.textAlignment = .center
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.delegate = self
        textView.clipsToBounds = false
        textView.linkTextAttributes = [
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        return textView
    }()

    init(delegate: LinkInstantDebitMandateViewDelegate? = nil) {
        super.init(frame: .zero)
        self.delegate = delegate
        addAndPinSubview(textView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        textView.font = LinkUI.font(forTextStyle: .caption, compatibleWith: traitCollection)
    }

    private func formattedLegalText() -> NSAttributedString {
        let string = STPLocalizedString(
            "By continuing, you agree to authorize payments pursuant to these <terms>terms</terms>.",
            "Mandate text displayed when paying via Link instant debit."
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

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = LinkUI.lineSpacing(
            fromRelativeHeight: Constants.lineHeight,
            textStyle: .caption
        )

        formattedString.addAttributes([.paragraphStyle: paragraphStyle], range: formattedString.extent)

        return formattedString
    }

}

extension LinkInstantDebitMandateView: UITextViewDelegate {

    func textView(
        _ textView: UITextView,
        shouldInteractWith URL: URL,
        in characterRange: NSRange,
        interaction: UITextItemInteraction
    ) -> Bool {
        if interaction == .invokeDefaultAction {
            delegate?.instantDebitMandateView(self, didTapOnLinkWithURL: URL)
        }

        return false
    }

}
