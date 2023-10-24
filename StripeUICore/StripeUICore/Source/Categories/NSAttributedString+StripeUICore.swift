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

    func switchAttachments(for traitCollection: UITraitCollection) -> NSAttributedString {
        let mutable = NSMutableAttributedString(attributedString: self)
        mutable.enumerateAttribute(.attachment, in: NSRange(location: 0, length: mutable.length), options: []) { attachment, range, _ in
            guard let attachment = attachment as? NSTextAttachment else { return }
            guard let asset = attachment.image?.imageAsset else { return }
            attachment.image = asset.image(with: traitCollection)
            mutable.replaceCharacters(in: range, with: NSAttributedString(attachment: attachment))
        }
        return mutable
    }

}
