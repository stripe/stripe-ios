//
//  LinkOpeningTextView.swift
//  StripeUICore
//
//  Created by Mel Ludowise on 5/11/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

/**
 Subclass of UITextView that allows for links to be opened on tap when the text is un-selectable.
 */
@objc(STP_Internal_LinkOpeningTextView)
class LinkOpeningTextView: UITextView {
    private var isTextSelectable = true

    /*
     UITextView only allows links to be opened on tap if the text is
     selectable. Override the `isSelectable` property such that
     `super.isSelectable` is always true to enable the links to be tappable
     but track internally whether the user should be able to select text in
     the view using `isTextSelectable`.
     */
    override var isSelectable: Bool {
        get {
            return isTextSelectable
        }
        set {
            super.isSelectable = true
            isTextSelectable = newValue
        }
    }

    /*
     Override to only enable events if either:
     - The text should be selectable.
     - The user tapped on a link.
     */
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        // Only override the default behavior if the view should not be selectable
        guard !isTextSelectable else {
            return super.point(inside: point, with: event)
        }

        guard let pos = closestPosition(to: point),
              let range = tokenizer.rangeEnclosingPosition(pos, with: .character, inDirection: .layout(.left))
        else {
            return false
        }

        let startIndex = offset(from: beginningOfDocument, to: range.start)

        return attributedText.attribute(.link, at: startIndex, effectiveRange: nil) != nil
    }
}
