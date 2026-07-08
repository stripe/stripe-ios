//
//  PMMEPromotionTextView.swift
//  StripePaymentSheet
//
//  Created by George Birch on 4/30/26.
//

#if canImport(UIKit)
import UIKit
#else
import Foundation
#endif

/// Shared text view used by PMME surfaces that need tappable links without selectable text.
/// Do NOT subclass from LinkOpeningTextView — subclassing `open` classes across SPM modules
/// causes dyld crashes. See: https://github.com/swiftlang/swift/issues/54323
class PMMEPromotionTextView: UITextView {

    init(foregroundColor: UIColor) {
        super.init(frame: .zero, textContainer: nil)
        isScrollEnabled = false
        isEditable = false
        // Keep super.isSelectable = true so UIKit allows link taps to work.
        super.isSelectable = true
        backgroundColor = .clear
        textContainerInset = .zero
        textContainer.lineFragmentPadding = 0
        clipsToBounds = false
        adjustsFontForContentSizeCategory = true
        linkTextAttributes = [.foregroundColor: foregroundColor]
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Block double-tap gestures to the system menu from showing
    override var selectedTextRange: UITextRange? {
        get { super.selectedTextRange }
        set {
            // Only allow collapsed cursors, reject actual selections
            if newValue == nil || newValue?.isEmpty == true {
                super.selectedTextRange = newValue
            }
        }
    }

    // Never show text being selected
    override func selectionRects(for range: UITextRange) -> [UITextSelectionRect] {
        return []
    }

    // Only register taps that land on a link — suppress all other touch events.
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard let pos = closestPosition(to: point),
              let range = tokenizer.rangeEnclosingPosition(pos, with: .character, inDirection: .layout(.left))
        else {
            return false
        }

        let startIndex = offset(from: beginningOfDocument, to: range.start)
        return attributedText?.attribute(.link, at: startIndex, effectiveRange: nil) != nil
    }
}
