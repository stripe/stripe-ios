//
//  TappableAttributedLabel.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 10/14/25.
//

import UIKit

final class TappableAttributedLabel: UILabel {

    struct TappableHighlight {
        let text: String
        let font: UIFont?
        let color: UIColor?
        let action: () -> Void
    }

    private var tappableHighlights: [TappableHighlight] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupTapGesture()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupTapGesture()
    }

    private func setupTapGesture() {
        isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tapGesture)
    }

    func setText(
        _ text: String,
        baseFont: UIFont,
        baseColor: UIColor,
        highlights: [TappableHighlight]
    ) {
        self.tappableHighlights = highlights

        let attributedString = NSMutableAttributedString(string: text)
        let fullRange = NSRange(location: 0, length: attributedString.length)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = textAlignment

        attributedString.addAttribute(.font, value: baseFont, range: fullRange)
        attributedString.addAttribute(.foregroundColor, value: baseColor, range: fullRange)
        attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: fullRange)

        let nsString = text as NSString
        for highlight in highlights {
            let range = nsString.range(of: highlight.text)
            if range.location != NSNotFound {
                if let font = highlight.font {
                    attributedString.addAttribute(.font, value: font, range: range)
                }
                if let color = highlight.color {
                    attributedString.addAttribute(.foregroundColor, value: color, range: range)
                }
            }
        }

        self.attributedText = attributedString
    }

    @objc
    private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let attributedText else {
            return
        }

        let tapLocation = gesture.location(in: self)
        let textStorage = NSTextStorage(attributedString: attributedText)
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: bounds.size)

        textContainer.lineFragmentPadding = 0
        textContainer.maximumNumberOfLines = numberOfLines
        textContainer.lineBreakMode = lineBreakMode

        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        let characterIndex = layoutManager.characterIndex(
            for: tapLocation,
            in: textContainer,
            fractionOfDistanceBetweenInsertionPoints: nil
        )

        let fullText = attributedText.string as NSString

        for highlight in tappableHighlights {
            let range = fullText.range(of: highlight.text)
            if range.location != NSNotFound && NSLocationInRange(characterIndex, range) {
                highlight.action()
                break
            }
        }
    }

}
