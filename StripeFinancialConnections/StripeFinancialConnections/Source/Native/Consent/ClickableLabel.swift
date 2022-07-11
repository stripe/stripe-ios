//
//  ClickableLabel.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 6/16/22.
//

import Foundation
import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

class ClickableLabel: UIView {
    
    struct Link {
        let text: String
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
        textView.textColor = .textSecondary
        textView.linkTextAttributes = [
            .foregroundColor: UIColor.textBrand,
        ]
        textView.delegate = self
        
        addAndPinSubview(textView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setText(_ text: String, link: Link?, alignCenter: Bool = false) {
        let links: [Link]
        if let link = link {
            links = [link]
        } else {
            links = []
        }
        setText(text, links: links, alignCenter: alignCenter)
    }
    
    func setText(_ text: String, links: [Link], alignCenter: Bool = false) {
        let paragraphStyle = NSMutableParagraphStyle()
        if alignCenter {
            paragraphStyle.alignment = .center
        }
        let string = NSMutableAttributedString(
            string: text,
            attributes: [
                .paragraphStyle: paragraphStyle,
                .font: UIFont.stripeFont(forTextStyle: .detail),
            ]
        )
        
        for link in links {
            let range = (string.string as NSString).range(of: link.text)
            string.addAttribute(.link, value: link.urlString, range: range)
            
            // setting font in `linkTextAttributes` does not work
            string.addAttribute(.font, value: UIFont.stripeFont(forTextStyle: .detailEmphasized), range: range)
                        
            linkURLStringToAction[link.urlString] = link.action
        }
        
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
