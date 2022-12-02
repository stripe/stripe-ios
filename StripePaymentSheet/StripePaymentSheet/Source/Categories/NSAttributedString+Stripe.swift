//
//  NSAttributedString+Stripe.swift
//  StripePaymentSheet
//
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import UIKit

extension NSMutableAttributedString {
    func replaceOccurrences(of textToReplace: String, with attachment: NSTextAttachment) {
        while let range = string.range(of: textToReplace) {
            let replacement = NSAttributedString(attachment: attachment)
            replaceCharacters(in: NSRange(range, in: string), with: replacement)
        }
    }
}
