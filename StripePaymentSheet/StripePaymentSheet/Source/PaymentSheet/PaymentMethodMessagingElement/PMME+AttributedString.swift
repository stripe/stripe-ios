//
//  PMME+AttributedString.swift
//  StripePaymentSheet
//

@_spi(STP) import StripeCore
import UIKit

extension NSMutableAttributedString {
    /// Generates an attributed string for PMME promotional text.
    /// Adds line spacing, optionally substitutes a BNPL logo for a placeholder, and appends info message text with underline.
    /// - Parameters:
    ///    - template: The promotional text to be displayed, including a placeholder if needed (e.g. "Buy now or pay later with {partner}")
    ///    - substitution: An optional tuple containing the placeholder text from the template to be replaced and the partner logo image to replace it with.
    ///    - infoMessage: The text to display at the end with underline styling.
    static func pmmePromoString(
        font: UIFont,
        textColor: UIColor,
        template: String,
        substitution: (placeholder: String, bnplLogo: UIImage)?,
        infoMessage: String
    ) -> NSMutableAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 2
        let stringAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor,
            .paragraphStyle: paragraphStyle,
        ]

        let infoMessageAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor,
            .paragraphStyle: paragraphStyle,
            .underlineStyle: NSUnderlineStyle.single.rawValue,
        ]

        let resultingString = NSMutableAttributedString()

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

                    // Add BNPL logo. Use additional scale of 2x
                    let bnplLogo = attributedStringOfImageWithoutLink(uiImage: bnplLogoImage, font: font, additionalScale: 2.0)
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

        // Add info message text with underline
        resultingString.append(NSAttributedString(string: " ", attributes: stringAttributes))
        resultingString.append(NSAttributedString(string: infoMessage, attributes: infoMessageAttributes))

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
