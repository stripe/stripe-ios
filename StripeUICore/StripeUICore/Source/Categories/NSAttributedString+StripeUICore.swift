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
        var hasAttachment = false
        enumerateAttribute(NSAttributedString.Key.attachment,
                           in: NSRange(location: 0, length: length),
                           options: NSAttributedString.EnumerationOptions(rawValue: 0)) { (value, _, _) in
            if (value as? NSTextAttachment) != nil {
                hasAttachment = true
            }
        }

        return hasAttachment
    }

}
