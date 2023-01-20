//
//  ClickableLabel.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 6/16/22.
//

import Foundation
import SafariServices
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

final class ClickableLabel: HitTestView {

    struct Link {
        let range: NSRange
        let urlString: String
        let action: (URL) -> Void
    }

    private let font: UIFont
    private let boldFont: UIFont
    private let linkFont: UIFont
    private let textColor: UIColor
    private let alignCenter: Bool
    private let textView = IncreasedHitTestTextView()
    private var linkURLStringToAction: [String: (URL) -> Void] = [:]

    init(
        font: UIFont,
        boldFont: UIFont,
        linkFont: UIFont,
        textColor: UIColor,
        alignCenter: Bool = false
    ) {
        self.font = font
        self.boldFont = boldFont
        self.linkFont = linkFont
        self.textColor = textColor
        self.alignCenter = alignCenter
        super.init(frame: .zero)
        textView.isScrollEnabled = false
        textView.delaysContentTouches = false
        textView.isEditable = false
        textView.isSelectable = true
        textView.backgroundColor = UIColor.clear
        // Get rid of the extra padding added by default to UITextViews
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0.0
        textView.linkTextAttributes = [
            .foregroundColor: UIColor.textBrand
        ]
        textView.delegate = self
        // remove clipping so when user selects an attributed
        // link, the selection area does not get clipped
        textView.clipsToBounds = false
        addAndPinSubview(textView)

        // enable faster tap recognizing
        if let gestureRecognizers = textView.gestureRecognizers {
            for gestureRecognizer in gestureRecognizers {
                if let tapGestureRecognizer = gestureRecognizer as? UITapGestureRecognizer,
                    tapGestureRecognizer.numberOfTapsRequired == 2
                {
                    // double-tap gesture recognizer causes a delay
                    // to single-tap gesture recognizer so we
                    // disable it
                    tapGestureRecognizer.isEnabled = false
                }
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Helper that automatically handles extracting links and, optionally, opening it via `SFSafariViewController`
    @available(iOSApplicationExtension, unavailable)
    func setText(
        _ text: String,
        action: @escaping ((URL) -> Void) = { url in
            SFSafariViewController.present(url: url)
        }
    ) {
        let textLinks = text.extractLinks()
        setText(
            textLinks.linklessString,
            links: textLinks.links.map {
                ClickableLabel.Link(
                    range: $0.range,
                    urlString: $0.urlString,
                    action: action
                )
            }
        )
    }

    private func setText(
        _ text: String,
        links: [Link]
    ) {
        let paragraphStyle = NSMutableParagraphStyle()
        if alignCenter {
            paragraphStyle.alignment = .center
        }
        let string = NSMutableAttributedString(
            string: text,
            attributes: [
                .paragraphStyle: paragraphStyle,
                .font: font,
                .foregroundColor: textColor,
            ]
        )

        // apply link attributes
        for link in links {
            string.addAttribute(.link, value: link.urlString, range: link.range)

            // setting font in `linkTextAttributes` does not work
            string.addAttribute(.font, value: linkFont, range: link.range)

            linkURLStringToAction[link.urlString] = link.action
        }

        // apply bold attributes
        string.addBoldFontAttributesByMarkdownRules(boldFont: boldFont)

        textView.attributedText = string
    }
}

// MARK: <UITextViewDelegate>

extension ClickableLabel: UITextViewDelegate {

    func textView(
        _ textView: UITextView,
        shouldInteractWith URL: URL,
        in characterRange: NSRange,
        interaction: UITextItemInteraction
    ) -> Bool {
        if let linkAction = linkURLStringToAction[URL.absoluteString] {
            linkAction(URL)
            return false
        } else {
            assertionFailure("Expected every URL to have an action defined. keys:\(linkURLStringToAction); url:\(URL)")
        }
        return true
    }

    func textViewDidChangeSelection(_ textView: UITextView) {
        // disable the ability to select/copy the text as a way to improve UX
        textView.selectedTextRange = nil
    }
}

private class IncreasedHitTestTextView: UITextView {

    // increase the area of NSAttributedString taps
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        // Note that increasing size here does NOT help to
        // increase NSAttributedString implementation of how
        // large a tap area is. As a result, this function
        // can return `true` and the link-tap may still
        // not happen.
        let largerBounds = bounds.insetBy(dx: -20, dy: -20)
        return largerBounds.contains(point)
    }
}
