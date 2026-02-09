//
//  PMMESinglePartnerView.swift
//  StripePaymentSheet
//
//  Created by George Birch on 10/29/25.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

class PMMESinglePartnerView: UIView {

    private let logoSet: PaymentMethodMessagingElement.LogoSet
    private let promotion: String
    private let learnMoreText: String
    private let infoUrl: URL
    private let appearance: PaymentMethodMessagingElement.Appearance

    private lazy var promotionTextView: UITextView = {
        let textView = UITextView()
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.clipsToBounds = false
        textView.adjustsFontForContentSizeCategory = true
        textView.linkTextAttributes = [.foregroundColor: appearance.linkTextColor]
        return textView
    }()

    // Needs to be set on the appropriate view to take effect
    var customAccessibilityLabel: String {
        promotion.replacingOccurrences(of: "{partner}", with: logoSet.altText) + " " + learnMoreText
    }

    init(
        logoSet: PaymentMethodMessagingElement.LogoSet,
        promotion: String,
        learnMoreText: String,
        infoUrl: URL,
        appearance: PaymentMethodMessagingElement.Appearance,
        textViewDelegate: UITextViewDelegate
    ) {
        self.logoSet = logoSet
        self.promotion = promotion
        self.learnMoreText = learnMoreText
        self.infoUrl = infoUrl
        self.appearance = appearance
        super.init(frame: .zero)

        promotionTextView.delegate = textViewDelegate
        promotionTextView.attributedText = getPromotionAttributedString()
        addAndPinSubview(promotionTextView)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // user interface style may be different because of the new superview overriding it
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        promotionTextView.attributedText = getPromotionAttributedString()
    }

    #if !os(visionOS)
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        promotionTextView.attributedText = getPromotionAttributedString()
    }
    #endif

    func getPromotionAttributedString() -> NSMutableAttributedString {
        .pmmePromoString(
            font: appearance.scaledFont,
            textColor: appearance.textColor,
            template: promotion,
            substitution: ("{partner}", traitCollection.isDarkMode ? logoSet.dark : logoSet.light),
            learnMoreText: learnMoreText,
            learnMoreUrl: infoUrl
        )
    }
}

extension NSMutableAttributedString {
    /// Generates an attributed string for PMME promo text with a clickable "Learn more" link at the end.
    static func pmmePromoString(
        font: UIFont,
        textColor: UIColor,
        template: String,
        substitution: (placeholder: String, bnplLogo: UIImage)?,
        learnMoreText: String,
        learnMoreUrl: URL
    ) -> NSMutableAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 2
        let stringAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor,
            .paragraphStyle: paragraphStyle,
        ]

        let resultingString = NSMutableAttributedString()
        var endsWithLogo = false

        // Replace placeholder with BNPL image if needed
        if let (partnerPlaceholder, bnplLogoImage) = substitution {
            guard let imgRange = template.range(of: partnerPlaceholder) else {
                return resultingString
            }

            var imgAppended = false
            let lastCharIndex = template.index(before: template.endIndex)

            // Go through string, replacing the placeholder with the BNPL logo
            for (indexOffset, currCharacter) in template.enumerated() {
                let currIndex = template.index(template.startIndex, offsetBy: indexOffset)
                if imgRange.contains(currIndex) {
                    if imgAppended {
                        continue
                    }
                    imgAppended = true

                    // Add BNPL logo with 2x scale
                    let bnplLogo = attributedStringOfImage(uiImage: bnplLogoImage, font: font, additionalScale: 2.0)
                    resultingString.append(bnplLogo)

                    // Check if logo is at the end of the template
                    if imgRange.upperBound == template.endIndex || imgRange.upperBound > lastCharIndex {
                        endsWithLogo = true
                    }
                } else {
                    resultingString.append(NSAttributedString(string: String(currCharacter), attributes: stringAttributes))
                }
            }
        } else {
            // Otherwise just fill in the whole template
            resultingString.append(NSAttributedString(string: template, attributes: stringAttributes))
        }

        // Add separator before "Learn more" text
        // - If template ends with period: add just a space
        // - If template ends with logo: add just a space
        // - Otherwise: add ". " (period + space)
        let trimmedTemplate = template.trimmingCharacters(in: .whitespaces)
        if trimmedTemplate.hasSuffix(".") || endsWithLogo {
            resultingString.append(NSAttributedString(string: " ", attributes: stringAttributes))
        } else {
            resultingString.append(NSAttributedString(string: ". ", attributes: stringAttributes))
        }

        // Add learn more text with link attribute
        let linkAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .link: learnMoreUrl,
            .paragraphStyle: paragraphStyle,
        ]
        resultingString.append(NSAttributedString(string: learnMoreText, attributes: linkAttributes))

        return resultingString
    }

    // Returns an attributed string containing only a text attachment for the given image.
    // The image is scaled so that its height matches the `.capHeight` of the font, and it is vertically centered.
    fileprivate static func attributedStringOfImage(
        uiImage: UIImage,
        font: UIFont,
        additionalScale: CGFloat
    ) -> NSAttributedString {
        let imageAttachment = NSTextAttachment()
        let scaledSize = uiImage.sizeMatchingFont(font, additionalScale: additionalScale)
        let heightDifference = font.capHeight - scaledSize.height
        let verticalOffset = heightDifference.rounded() / 2
        imageAttachment.bounds = CGRect(origin: .init(x: 0, y: verticalOffset), size: scaledSize)
        imageAttachment.image = uiImage
        return NSAttributedString(attachment: imageAttachment)
    }
}
