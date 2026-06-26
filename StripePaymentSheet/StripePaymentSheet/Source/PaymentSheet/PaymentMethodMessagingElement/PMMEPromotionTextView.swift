//
//  PMMEPromotionTextView.swift
//  StripePaymentSheet
//
//  Created by George Birch on 4/30/26.
//

import UIKit

/// Shared text view used by PMME surfaces that need tappable links without selectable text.
/// Do NOT subclass from LinkOpeningTextView — subclassing `open` classes across SPM modules
/// causes dyld crashes due. See: https://github.com/swiftlang/swift/issues/54323
class PMMEPromotionTextView: UITextView {
    private var isTextSelectable = true

    override var isSelectable: Bool {
        get {
            return isTextSelectable
        }
        set {
            super.isSelectable = true
            isTextSelectable = newValue
        }
    }

    init(foregroundColor: UIColor) {
        super.init(frame: .zero, textContainer: nil)
        isScrollEnabled = false
        isEditable = false
        isSelectable = false
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

    // To avoid double-tap selection behavior we block double tap gestures. These double taps will instead open the link
    public override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // Intercept tap gesture recognizers
        if let tapGesture = gestureRecognizer as? UITapGestureRecognizer {
            // Block the gesture if it requires a double-tap
            if tapGesture.numberOfTapsRequired == 2 {
                return false
            }
        }

        // Allow all other system gestures (scrolling, link clicks, etc.)
        return super.gestureRecognizerShouldBegin(gestureRecognizer)
    }

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
