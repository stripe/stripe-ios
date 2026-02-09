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
}

extension NSAttributedString {
    /// Returns an attributed string containing only a text attachment for the given image.
    /// The image is scaled so that its height matches the `.capHeight` of the font, and it is vertically centered.
    static func attributedStringForImage(
        _ image: UIImage,
        font: UIFont,
        additionalScale: CGFloat
    ) -> NSAttributedString {
        let imageAttachment = NSTextAttachment()
        let scaledSize = image.sizeMatchingFont(font, additionalScale: additionalScale)
        let heightDifference = font.capHeight - scaledSize.height
        let verticalOffset = heightDifference.rounded() / 2
        imageAttachment.bounds = CGRect(origin: .init(x: 0, y: verticalOffset), size: scaledSize)
        imageAttachment.image = image
        return NSAttributedString(attachment: imageAttachment)
    }
}
