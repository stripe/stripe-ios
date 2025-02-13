//
//  LinkInstantDebitMandateView.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 2/17/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

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

    private let links: [String: URL] = [
        "terms": URL(string: "https://link.com/terms/ach-authorization")!
    ]

    weak var delegate: LinkInstantDebitMandateViewDelegate?

    private lazy var textView: UITextView = {
        let textView = UITextView()
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.backgroundColor = .clear
        textView.attributedText = formattedLegalText()
        textView.textColor = .linkSecondaryText
        textView.textAlignment = .center
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.delegate = self
        textView.clipsToBounds = false
        textView.adjustsFontForContentSizeCategory = true
        textView.linkTextAttributes = [
            .foregroundColor: UIColor.linkBrandDark
        ]
        textView.font = LinkUI.font(forTextStyle: .caption)
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

    private func formattedLegalText() -> NSAttributedString {
        let string = String.Localized.bank_continue_mandate_text

        let formattedString = STPStringUtils.applyLinksToString(template: string, links: links)

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

    #if !os(visionOS)
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
    #endif

}
