//
//  PMMEPromotionTextView.swift
//  StripePaymentSheet
//
//  Created by George Birch on 4/30/26.
//

@_spi(STP) import StripeUICore
import UIKit

/// Shared text view used by PMME surfaces that need tappable links without selectable text.
class PMMEPromotionTextView: LinkOpeningTextView {

    init(foregroundColor: UIColor) {
        super.init(frame: .zero, textContainer: nil)
        isScrollEnabled = false
        isEditable = false
        /*
         `LinkOpeningTextView` keeps the underlying actual `isSelectable` property set to `true`,
         which is required for links to work. However, setting it `false` will disable events to
         any point other than the link text. We still need to handle double tap selection on the
         link, which we do below.
         This is a workaround for UIKit not allowing links to work if the `UITextView` does not
         have `isSelectable = true`.
         */
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
}
