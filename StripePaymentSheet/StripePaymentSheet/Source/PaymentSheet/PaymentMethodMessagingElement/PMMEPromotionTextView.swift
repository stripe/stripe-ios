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
}
