//
//  NSAttributedString+Stripe.swift
//  StripePaymentSheet
//
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
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
        foregroundColor: UIColor,
        template: String,
        partnerPlaceholder: String,
        bnplLogoImage: UIImage
    ) -> NSMutableAttributedString {
        let stringAttributes = [
            NSAttributedString.Key.font: font,
            .foregroundColor: foregroundColor,
        ]

        let resultingString = NSMutableAttributedString()
        resultingString.append(NSAttributedString(string: ""))
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
                let bnplLogo = Self.attributedStringOfImageWithoutLink(uiImage: bnplLogoImage, font: font)
                resultingString.append(bnplLogo)

                // Add info icon
                let infoIconColor = UIColor.dynamic(
                    light: UIColor(hex: 0x1A1A1A),
                    dark: UIColor.white
                ).withAlphaComponent(0.7)
                if let infoIconImage = UIImage(systemName: "info.circle")?
                    .withTintColor(infoIconColor, renderingMode: .alwaysTemplate) {
                    let infoIcon = Self.attributedStringOfImageWithoutLink(uiImage: infoIconImage, font: font)
                    resultingString.append(NSAttributedString(string: "\u{00A0}\u{00A0}", attributes: stringAttributes))
                    resultingString.append(infoIcon)
                } else {
                    stpAssertionFailure("Failed to load system image info.circle")
                }
            } else {
                resultingString.append(NSAttributedString(string: String(currCharacter),
                                                          attributes: stringAttributes))
            }
        }
        return resultingString
    }

    private static func attributedStringOfImageWithoutLink(
        uiImage: UIImage,
        font: UIFont,
        tintColor: UIColor? = nil
    ) -> NSAttributedString {
        let imageAttachment = NSTextAttachment()
        imageAttachment.bounds = boundsOfImage(font: font, uiImage: uiImage)
        if let tintColor {
            imageAttachment.image = uiImage.withTintColor(tintColor, renderingMode: .alwaysTemplate)
        } else {
            imageAttachment.image = uiImage
        }
        return NSAttributedString(attachment: imageAttachment)
    }

    // https://stackoverflow.com/questions/26105803/center-nstextattachment-image-next-to-single-line-uilabel
    private static func boundsOfImage(font: UIFont, uiImage: UIImage) -> CGRect {
        return CGRect(x: 0,
                      y: (font.capHeight - uiImage.size.height).rounded() / 2,
                      width: uiImage.size.width,
                      height: uiImage.size.height)
    }
}
