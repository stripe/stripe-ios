//
//  NSAttributedString+Stripe.swift
//  StripePaymentSheet
//
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
import UIKit

extension NSMutableAttributedString {
    func replaceOccurrences(of textToReplace: String, with attachment: NSTextAttachment) {
        while let range = string.range(of: textToReplace) {
            let replacement = NSAttributedString(attachment: attachment)
            replaceCharacters(in: NSRange(range, in: string), with: replacement)
        }
    }

    /// Generates an attributed for use in BNPL info context. Adds line spacing, an info icon at the end, and optionally substitutes a BNPL logo in for a placeholder in the template.
    /// - Parameters:
    ///    - template: The promotional text to be displayed, including a placeholder if needed (e.g. "Buy now or pay later with {partner}")
    ///    - substitution: An optional tuple containing the placeholder text from the template to be replaced and the partner logo image to replace it with.
    static func bnplPromoString(
        font: UIFont,
        textColor: UIColor,
        infoIconColor: UIColor,
        template: String,
        substitution: (placeholder: String, bnplLogo: UIImage)?
    ) -> NSMutableAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 2
        let stringAttributes = [
            NSAttributedString.Key.font: font,
            .foregroundColor: textColor,
            .paragraphStyle: paragraphStyle,
        ]

        let resultingString = NSMutableAttributedString()
        resultingString.append(NSAttributedString(string: ""))

        // Replace placeholder with BNPL image if needed
        if let (partnerPlaceholder, bnplLogoImage) = substitution {
            guard let img = template.range(of: partnerPlaceholder) else {
                return resultingString
            }

            var imgAppended = false

            // Go through string, replacing the placeholder with the BNPL logo
            for (indexOffset, currCharacter) in template.enumerated() {
                let currIndex = template.index(template.startIndex, offsetBy: indexOffset)
                if img.contains(currIndex) {
                    if imgAppended {
                        continue
                    }
                    imgAppended = true

                    // Add BNPL logo. Use additioanl scale of 2x
                    let bnplLogo = Self.attributedStringOfImageWithoutLink(uiImage: bnplLogoImage, font: font, additionalScale: 2.0)
                    resultingString.append(bnplLogo)
                } else {
                    resultingString.append(NSAttributedString(string: String(currCharacter),
                                                              attributes: stringAttributes))
                }
            }
        } else {
            // Otherwise just fill in the whole template
            resultingString.append(NSAttributedString(string: template, attributes: stringAttributes))
        }

        // Add info icon. Use additional scale of 1.5x
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: font.pointSize)
        if let infoIconImage = UIImage(systemName: "info.circle", withConfiguration: symbolConfig)?
            .withTintColor(infoIconColor, renderingMode: .alwaysTemplate) {
            let infoIcon = Self.attributedStringOfImageWithoutLink(uiImage: infoIconImage, font: font, additionalScale: 1.5)
            resultingString.append(NSAttributedString(string: "\u{00A0}", attributes: stringAttributes))
            resultingString.append(infoIcon)
        } else {
            stpAssertionFailure("Failed to load system image info.circle")
        }

        return resultingString
    }

    // Returns an attributed string containing only a text attachment for the given image.
    // The image is scaled so that its height matches the `.capHeight` of the font, and it is vertically centered.
    // An additionalScale can be provided to make the image taller or shorter than the text.
    private static func attributedStringOfImageWithoutLink(
        uiImage: UIImage,
        font: UIFont,
        additionalScale: CGFloat
    ) -> NSAttributedString {
        let imageAttachment = NSTextAttachment()
        imageAttachment.bounds = boundsOfImage(font: font, uiImage: uiImage, additionalScale: additionalScale)
        imageAttachment.image = uiImage
        return NSAttributedString(attachment: imageAttachment)
    }

    // Originally based on https://stackoverflow.com/questions/26105803/center-nstextattachment-image-next-to-single-line-uilabel
    private static func boundsOfImage(font: UIFont, uiImage: UIImage, additionalScale: CGFloat) -> CGRect {
        let scaledSize = uiImage.sizeMatchingFont(font, additionalScale: additionalScale)
        // Calculate the difference in height between the scaled image and the font
        let heightDifference = font.capHeight - scaledSize.height
        // To vertically center the image, we want to vertically offset it by half of the height difference between it and the font
        let verticalOffset = heightDifference.rounded() / 2
        return CGRect(
            origin: .init(x: 0, y: verticalOffset),
            size: scaledSize
        )
    }
}
