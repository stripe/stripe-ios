//
//  Label.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 5/8/23.
//

import Foundation
import UIKit

// Prefer `AttributedLabel` over `AttributedTextView` for single-line text.
final class AttributedLabel: UILabel {

    private let customFont: FinancialConnectionsFont
    private let customTextColor: UIColor
    private var customTextAlignment: NSTextAlignment?

    // one can accidentally forget to call `setText` instead of `text` so
    // this makes it convenient to use `AttributedLabel`
    override var text: String? {
        didSet {
            setText(text ?? "")
        }
    }

    override var textAlignment: NSTextAlignment {
        didSet {
            self.customTextAlignment = textAlignment
        }
    }

    init(font: FinancialConnectionsFont, textColor: UIColor) {
        self.customFont = font
        self.customTextColor = textColor
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // UILabel with custom `lineHeight` via `NSParagraphStyle` was not properly
    // centering the text, so here we adjust it to be centered.
    override func drawText(in rect: CGRect) {
        guard
            let attributedText = self.attributedText,
            attributedText.length > 0, // `attributes(at:effectiveRange)` crashes if empty string
            let font = attributedText.attributes(at: 0, effectiveRange: nil)[.font] as? UIFont,
            let paragraphStyle = attributedText.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle
        else {
            super.drawText(in: rect)
            return
        }
        let uiFontLineHeight = font.lineHeight
        let paragraphStyleLineHeight = paragraphStyle.minimumLineHeight
        assert(paragraphStyle.minimumLineHeight == paragraphStyle.maximumLineHeight, "we are assuming that minimum and maximum are the same")

        if paragraphStyleLineHeight > uiFontLineHeight {
            let lineHeightDifference = (paragraphStyle.minimumLineHeight - uiFontLineHeight)
            let newRect = CGRect(
                x: rect.origin.x,
                y: rect.origin.y - lineHeightDifference / 2,
                width: rect.width,
                height: rect.height
            )
            super.drawText(in: newRect)
        } else {
            super.drawText(in: rect)
        }
    }

    func setText(_ text: String, underline: Bool = false) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = customFont.lineHeight
        paragraphStyle.maximumLineHeight = customFont.lineHeight
        if let customTextAlignment = customTextAlignment {
            paragraphStyle.alignment = customTextAlignment
        }

        let string = NSMutableAttributedString(
            string: text,
            attributes: {
                var attributes: [NSAttributedString.Key: Any] = [
                    .paragraphStyle: paragraphStyle,
                    .font: customFont.uiFont,
                    .foregroundColor: customTextColor,
                ]
                if underline {
                    attributes[.underlineColor] = customTextColor
                    attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
                }
                return attributes
            }()
        )
        attributedText = string
    }
}
