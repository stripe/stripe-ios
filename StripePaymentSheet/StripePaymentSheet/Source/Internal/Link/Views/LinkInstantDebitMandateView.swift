//
//  LinkMandateView.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 2/17/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

protocol LinkMandateViewDelegate: AnyObject {
    /// Called when the user taps on a link.
    ///
    /// - Parameters:
    ///   - mandateView: The view that the user interacted with.
    ///   - url: URL of the link.
    func mandateView(_ mandateView: LinkMandateView, didTapOnLinkWithURL url: URL)
}

// TODO(ramont): extract common code with `LinkLegalTermsView`.

/// For internal SDK use only
@objc(STP_Internal_LinkMandateViewDelegate)
final class LinkMandateView: UIView {
    struct Constants {
        static let lineHeight: CGFloat = 1.5
    }

    private let links: [String: URL] = [
        "terms": URL(string: "https://link.com/terms/ach-authorization")!
    ]

    weak var delegate: LinkMandateViewDelegate?
    let intent: Intent

    private lazy var textView: UITextView = {
        let textView = UITextView()
        textView.attributedText = formattedLegalTextForBank()
        textView.delegate = self
        textView.applyStyle()
        return textView
    }()

    init(
        intent: Intent,
        delegate: LinkMandateViewDelegate? = nil
    ) {
        self.intent = intent
        super.init(frame: .zero)
        self.delegate = delegate
        addAndPinSubview(textView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(
        for type: ConsumerPaymentDetails.DetailsType,
        merchant: String
    ) {
        switch type {
        case .card:
            textView.attributedText = intent.isSettingUp ? formattedLegalTextForCard(with: merchant) : nil
        case .bankAccount:
            textView.attributedText = formattedLegalTextForBank()
        default:
            break
        }

        textView.applyStyle()
    }

    private func formattedLegalTextForBank() -> NSAttributedString {
        let string = String.Localized.bank_continue_mandate_text
        let formattedString = STPStringUtils.applyLinksToString(template: string, links: links)
        return formattedLegalText(formattedString)
    }

    private func formattedLegalTextForCard(with merchant: String) -> NSAttributedString {
        let string = String(format: .Localized.by_providing_your_card_information_text, merchant)
        let formattedString = NSMutableAttributedString(string: string)
        return formattedLegalText(formattedString)
    }

    private func formattedLegalText(_ formattedString: NSMutableAttributedString) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineSpacing = LinkUI.lineSpacing(
            fromRelativeHeight: Constants.lineHeight,
            textStyle: .caption
        )

        formattedString.addAttributes([.paragraphStyle: paragraphStyle], range: formattedString.extent)

        return formattedString
    }
}

extension LinkMandateView: UITextViewDelegate {

    #if !os(visionOS)
    func textView(
        _ textView: UITextView,
        shouldInteractWith URL: URL,
        in characterRange: NSRange,
        interaction: UITextItemInteraction
    ) -> Bool {
        if interaction == .invokeDefaultAction {
            delegate?.mandateView(self, didTapOnLinkWithURL: URL)
        }

        return false
    }
    #endif

}

private extension UITextView {

    func applyStyle() {
        isScrollEnabled = false
        isEditable = false
        backgroundColor = .clear
        textColor = .linkSecondaryText
        textAlignment = .center
        textContainerInset = .zero
        textContainer.lineFragmentPadding = 0
        clipsToBounds = false
        adjustsFontForContentSizeCategory = true
        linkTextAttributes = [
            .foregroundColor: UIColor.linkBrandDark
        ]
        font = LinkUI.font(forTextStyle: .caption)
    }
}
