//
//  AttributedTextView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 5/2/23.
//

import Foundation
import SafariServices
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

// Adds support for markdown links and markdown bold.
//
// `AttributedTextView` is also the `UITextView` version of `AttributedLabel`.
final class AttributedTextView: HitTestView {

    private struct LinkDescriptor {
        let range: NSRange
        let urlString: String
        let action: (URL) -> Void
    }

    private let font: FinancialConnectionsFont
    private let boldFont: FinancialConnectionsFont
    private let linkFont: FinancialConnectionsFont
    private let textColor: UIColor
    private let alignment: NSTextAlignment?
    private let textView: IncreasedHitTestTextView
    private var linkURLStringToAction: [String: (URL) -> Void] = [:]

    init(
        font: FinancialConnectionsFont,
        boldFont: FinancialConnectionsFont,
        linkFont: FinancialConnectionsFont,
        textColor: UIColor,
        // links are the same color as the text by default
        linkColor: UIColor? = nil,
        showLinkUnderline: Bool = true,
        alignment: NSTextAlignment? = nil
    ) {
        let linkColor = linkColor ?? textColor
        let textContainer = NSTextContainer(size: .zero)
        let layoutManager = VerticalCenterLayoutManager()
        layoutManager.addTextContainer(textContainer)
        let textStorage = NSTextStorage()
        textStorage.addLayoutManager(layoutManager)
        self.textView = IncreasedHitTestTextView(
            frame: .zero,
            textContainer: textContainer
        )
        self.font = font
        self.boldFont = boldFont
        self.linkFont = linkFont
        self.textColor = textColor
        self.alignment = alignment
        super.init(frame: .zero)
        textView.isScrollEnabled = false
        textView.delaysContentTouches = false
        textView.isEditable = false
        textView.isSelectable = true
        textView.backgroundColor = UIColor.clear
        // Get rid of the extra padding added by default to UITextViews
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0.0
        textView.linkTextAttributes = {
            var linkTextAttributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: linkColor
            ]
            if showLinkUnderline {
                linkTextAttributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
            }
            return linkTextAttributes
        }()
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
                AttributedTextView.LinkDescriptor(
                    range: $0.range,
                    urlString: $0.urlString,
                    action: action
                )
            }
        )
    }

    private func setText(
        _ text: String,
        links: [LinkDescriptor]
    ) {
        let paragraphStyle = NSMutableParagraphStyle()
        if let alignment {
            paragraphStyle.alignment = alignment
        }
        paragraphStyle.minimumLineHeight = font.lineHeight
        paragraphStyle.maximumLineHeight = font.lineHeight
        let string = NSMutableAttributedString(
            string: text,
            attributes: [
                .paragraphStyle: paragraphStyle,
                .font: font.uiFont,
                .foregroundColor: textColor,
            ]
        )

        // apply link attributes
        for link in links {
            string.addAttribute(.link, value: link.urlString, range: link.range)

            // setting font in `linkTextAttributes` does not work
            string.addAttribute(.font, value: linkFont.uiFont, range: link.range)

            linkURLStringToAction[link.urlString] = link.action
        }

        // apply bold attributes
        string.addBoldFontAttributesByMarkdownRules(boldFont: boldFont.uiFont)

        textView.attributedText = string
    }
}

// MARK: <UITextViewDelegate>

extension AttributedTextView: UITextViewDelegate {

    #if !canImport(CompositorServices)
    func textView(
        _ textView: UITextView,
        shouldInteractWith URL: URL,
        in characterRange: NSRange,
        interaction: UITextItemInteraction
    ) -> Bool {
        if let linkAction = linkURLStringToAction[URL.absoluteString] {
            FeedbackGeneratorAdapter.buttonTapped()
            linkAction(URL)
            return false
        } else {
            assertionFailure("Expected every URL to have an action defined. keys:\(linkURLStringToAction); url:\(URL)")
        }
        return true
    }
    #endif

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

// UITextView with custom `lineHeight` via `NSParagraphStyle` was not properly
// centering the text, so here we adjust it to be centered.
private class VerticalCenterLayoutManager: NSLayoutManager {
    override func drawGlyphs(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        let range = characterRange(forGlyphRange: glyphsToShow, actualGlyphRange: nil)
        guard
            let attributedString = textStorage?.attributedSubstring(from: range),
            attributedString.length > 0, // `attributes(at:effectiveRange)` crashes if empty string
            let font = attributedString.attributes(at: 0, effectiveRange: nil)[.font] as? UIFont,
            let paragraphStyle = attributedString.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle
        else {
            super.drawGlyphs(forGlyphRange: glyphsToShow, at: origin)
            return
        }
        let uiFontLineHeight = font.lineHeight
        let paragraphStyleLineHeight = paragraphStyle.minimumLineHeight
        assert(paragraphStyle.minimumLineHeight == paragraphStyle.maximumLineHeight, "we are assuming that minimum and maximum are the same")
        if paragraphStyleLineHeight > uiFontLineHeight {
            let lineHeightDifference = (paragraphStyleLineHeight - uiFontLineHeight)
            let newOrigin = CGPoint(
                x: origin.x,
                y: origin.y - lineHeightDifference / 2
            )
            super.drawGlyphs(forGlyphRange: glyphsToShow, at: newOrigin)
        } else {
            super.drawGlyphs(forGlyphRange: glyphsToShow, at: origin)
        }
    }

    override func underlineGlyphRange(
        _ glyphRange: NSRange,
        underlineType: NSUnderlineStyle,
        lineFragmentRect: CGRect,
        lineFragmentGlyphRange: NSRange,
        containerOrigin: CGPoint
    ) {
        var lineFragmentRect = lineFragmentRect
        lineFragmentRect.origin.y += 1.5 // move the underline down more
        super.underlineGlyphRange(
            glyphRange,
            underlineType: underlineType,
            lineFragmentRect: lineFragmentRect,
            lineFragmentGlyphRange: lineFragmentGlyphRange,
            containerOrigin: containerOrigin
        )
    }
}
