//
//  LinkMandateView.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 2/17/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

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
    weak var delegate: LinkMandateViewDelegate?
    private let linkTextColor: UIColor

    private lazy var textView: UITextView = {
        let textView = UITextView()
        textView.delegate = self
        textView.applyStyle(linkTextColor: linkTextColor)
        return textView
    }()

    init(delegate: LinkMandateViewDelegate? = nil, linkAppearance: LinkAppearance? = nil) {
        linkTextColor = linkAppearance?.colors?.primary ?? .linkTextBrand
        super.init(frame: .zero)
        self.delegate = delegate
        addAndPinSubview(textView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setText(_ text: NSAttributedString) {
        textView.attributedText = formattedLegalText(text)
        textView.applyStyle(linkTextColor: linkTextColor)
    }

    private func formattedLegalText(_ formattedString: NSAttributedString) -> NSAttributedString {
        let mutableString = NSMutableAttributedString(attributedString: formattedString)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineSpacing = LinkUI.mandateLineSpacing

        mutableString.addAttributes([.paragraphStyle: paragraphStyle], range: mutableString.extent)

        return mutableString
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

    func applyStyle(linkTextColor: UIColor) {
        isScrollEnabled = false
        isEditable = false
        backgroundColor = .clear
        textColor = .linkTextTertiary
        textAlignment = .center
        textContainerInset = .zero
        textContainer.lineFragmentPadding = 0
        clipsToBounds = false
        adjustsFontForContentSizeCategory = true
        linkTextAttributes = [
            .foregroundColor: linkTextColor
        ]
        font = LinkUI.font(forTextStyle: .caption)
    }
}
