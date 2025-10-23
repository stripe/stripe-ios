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

    static func bnplPromoString(
        font: UIFont,
        textColor: UIColor,
        infoIconColor: UIColor,
        template: String,
        substitution: (String, UIImage, scale: CGFloat)?
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
        if let (partnerPlaceholder, bnplLogoImage, scale) = substitution {
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

                    // Add BNPL logo
                    let bnplLogo = Self.attributedStringOfImageWithoutLink(uiImage: bnplLogoImage, font: font, scale: scale)
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

        // Add info icon
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: font.pointSize)
        if let infoIconImage = UIImage(systemName: "info.circle", withConfiguration: symbolConfig)?
            .withTintColor(infoIconColor, renderingMode: .alwaysTemplate) {
            let infoIcon = Self.attributedStringOfImageWithoutLink(uiImage: infoIconImage, font: font, scale: 1.5)
            resultingString.append(NSAttributedString(string: "\u{00A0}\u{00A0}", attributes: stringAttributes))
            resultingString.append(infoIcon)
        } else {
            stpAssertionFailure("Failed to load system image info.circle")
        }

        return resultingString
    }

    private static func attributedStringOfImageWithoutLink(
        uiImage: UIImage,
        font: UIFont,
        scale: CGFloat
    ) -> NSAttributedString {
        let imageAttachment = NSTextAttachment()
        imageAttachment.bounds = boundsOfImage(font: font, uiImage: uiImage, scale: scale)
        imageAttachment.image = uiImage
        return NSAttributedString(attachment: imageAttachment)
    }

    // https://stackoverflow.com/questions/26105803/center-nstextattachment-image-next-to-single-line-uilabel
    // TODO: document
    private static func boundsOfImage(font: UIFont, uiImage: UIImage, scale: CGFloat) -> CGRect {
        let scaledSize = uiImage.sizeMatchingFont(font, scale: scale)
        return CGRect(
            origin: .init(x: 0, y: (font.capHeight - scaledSize.height).rounded() / 2),
            size: scaledSize
        )
    }
}
