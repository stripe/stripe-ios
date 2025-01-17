//
//  LinkLegalTermsView.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 1/26/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore

import UIKit

protocol LinkLegalTermsViewDelegate: AnyObject {
    /// Called when the user taps on a legal link.
    ///
    /// Implementation must return `true` if the link was handled. Returning `false`results in the link
    /// to open in the default browser.
    ///
    /// - Parameters:
    ///   - legalTermsView: The view that the user interacted with.
    ///   - url: URL of the link.
    /// - Returns: `true` if the link was handled by the delegate.
    func legalTermsView(_ legalTermsView: LinkLegalTermsView, didTapOnLinkWithURL url: URL) -> Bool
}

/// For internal SDK use only
@objc(STP_Internal_LinkLegalTermsView)
final class LinkLegalTermsView: UIView {
    struct Constants {
        static let lineHeight: CGFloat = 1.0
    }

    private let links: [String: URL] = [
        "terms": URL(string: "https://link.co/terms")!,
        "privacy": URL(string: "https://link.co/privacy")!,
    ]

    weak var delegate: LinkLegalTermsViewDelegate?
    private let mode: LinkInlineSignupViewModel.Mode
    /// If true, we're in a separate Link VC (instead of the inline PS one)
    private let isStandalone: Bool
    private let emailWasPrefilled: Bool

    var textColor: UIColor? {
        get {
            return textView.textColor
        }
        set {
            textView.textColor = newValue
        }
    }

    var font: UIFont? {
        get {
            return textView.font
        }
        set {
            textView.font = newValue
        }
    }

    private lazy var textView: UITextView = {
        let textView = UITextView()
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.backgroundColor = .clear
        textView.attributedText = formattedLegalText()
        textView.textColor = .linkSecondaryText
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.delegate = self
        textView.clipsToBounds = false
        textView.adjustsFontForContentSizeCategory = true
        textView.font = LinkUI.font(forTextStyle: .caption)
        return textView
    }()

    init(textAlignment: NSTextAlignment = .left,
         mode: LinkInlineSignupViewModel.Mode = .checkbox,
         emailWasPrefilled: Bool = false,
         isStandalone: Bool = false,
         delegate: LinkLegalTermsViewDelegate? = nil) {
        self.mode = mode
        self.emailWasPrefilled = emailWasPrefilled
        self.isStandalone = isStandalone
        super.init(frame: .zero)
        self.textView.textAlignment = textAlignment
        self.delegate = delegate
        addAndPinSubview(textView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func formattedLegalText() -> NSAttributedString {
        let string: String = {
            if isStandalone {
                return STPLocalizedString(
                    "By continuing you agree to the <terms>Terms</terms> and <privacy>Privacy Policy</privacy>.",
                    "Legal text shown when creating a Link account."
                )
            }
            switch mode {
            case .checkbox:
                return STPLocalizedString(
                    "By joining Link, you agree to the <terms>Terms</terms> and <privacy>Privacy Policy</privacy>.",
                    "Legal text shown when creating a Link account."
                )
            case .textFieldsOnlyEmailFirst:
                return STPLocalizedString(
                    "By providing your email, you agree to create a Link account and save your payment info to Link, according to the Link <terms>Terms</terms> and <privacy>Privacy Policy</privacy>.",
                    "Legal text shown when creating a Link account."
                )
            case .textFieldsOnlyPhoneFirst:
                return STPLocalizedString(
                    "By providing your phone number, you agree to create a Link account and save your payment info to Link, according to the Link <terms>Terms</terms> and <privacy>Privacy Policy</privacy>.",
                    "Legal text shown when creating a Link account."
                )
            }
        }()
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

extension LinkLegalTermsView: UITextViewDelegate {
    enum Error: Swift.Error {
        case linkLegalTermsViewUITextViewDelegate
    }

#if !canImport(CompositorServices)
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

        let handled = delegate?.legalTermsView(self, didTapOnLinkWithURL: URL) ?? false

        if !handled {
            let errorAnalytic = ErrorAnalytic(event: .unexpectedPaymentSheetError,
                                              error: Error.linkLegalTermsViewUITextViewDelegate)
            STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic)
            stpAssertionFailure("Link not handled by delegate")
        }

        // If not handled by the delegate, let the system handle the link.
        return !handled
    }
#endif

}
