//
//  ClickableLabel.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 6/16/22.
//

import Foundation
import SafariServices
import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

class ClickableLabel: UIView {
    
    struct Link {
        let range: NSRange
        let urlString: String
        let action: (URL) -> Void
    }
    
    private let textView = UITextView()
    private var linkURLStringToAction: [String: (URL) -> Void] = [:]
    
    init() {
        super.init(frame: .zero)
        
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.isSelectable = true
        textView.backgroundColor = UIColor.clear
        // Get rid of the extra padding added by default to UITextViews
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0.0
        textView.linkTextAttributes = [
            .foregroundColor: UIColor.textBrand,
        ]
        textView.delegate = self
        
        addAndPinSubview(textView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Helper that automatically handles extracting links and, optionally, opening it via `SFSafariViewController`
    @available(iOSApplicationExtension, unavailable)
    func setText(
        _ text: String,
        font: UIFont = UIFont.stripeFont(forTextStyle: .detail),
        boldFont: UIFont = UIFont.stripeFont(forTextStyle: .detailEmphasized),
        linkFont: UIFont = UIFont.stripeFont(forTextStyle: .detailEmphasized),
        textColor: UIColor = .textSecondary,
        alignCenter: Bool = false,
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
            },
            font: font,
            boldFont: boldFont,
            linkFont: linkFont,
            textColor: textColor,
            alignCenter: alignCenter
        )
    }
    
    private func setText(
        _ text: String,
        links: [Link],
        font: UIFont,
        boldFont: UIFont,
        linkFont: UIFont,
        textColor: UIColor,
        alignCenter: Bool = false
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
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
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
