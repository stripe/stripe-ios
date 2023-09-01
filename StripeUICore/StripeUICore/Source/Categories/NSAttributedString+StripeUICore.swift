//
//  NSAttributedString+StripeUICore.swift
//  StripeUICore
//
//  Created by Nick Porter on 8/31/23.
//

import Foundation
import UIKit

extension NSAttributedString {

    /// Returns true if this attributed string has a text attachment
    var hasTextAttachment: Bool {
        return attributes(at: 0, longestEffectiveRange: nil, in: NSRange(location: 0, length: length)).contains(where: { (key, value) -> Bool in
            return key == NSAttributedString.Key.attachment && value is NSTextAttachment
        })
    }

}
