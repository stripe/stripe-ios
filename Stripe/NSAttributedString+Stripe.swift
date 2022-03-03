//
//  NSAttributedString+Stripe.swift
//  StripeiOS
//
//  Created by Ramon Torres on 1/11/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

extension NSAttributedString {

    /// A range covering from the start to the end of the attributed string.
    var extent: NSRange {
        return NSRange(location: 0, length: self.length)
    }

}

extension NSMutableAttributedString {
    func replaceOccurrences(of textToReplace: String, with attachment: NSTextAttachment) {
        while let range = string.range(of: textToReplace) {
            let replacement = NSAttributedString(attachment: attachment)
            replaceCharacters(in: NSRange(range, in: string), with: replacement)
        }
    }
}
