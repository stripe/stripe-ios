//
//  RowButtonContent.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 2/12/25.
//

import UIKit

/// Defines a view that is contained with a `RowButton`
protocol RowButtonContent: UIView {

    /// Indicates whether the row button content is currently selected.
    ///
    /// When set to `true`, the content should visually indicate its selected state.
    /// When set to `false`, the content should appear in its normal, unselected state.
    var isSelected: Bool { get set }

    /// A boolean that indicates if this content view is displaying any subtext
    var hasSubtext: Bool { get }

    /// A boolean indicating if this content view is displaying an accessory view
    var isDisplayingAccessoryView: Bool { get set }

    /// Sets the text for a sublabel within the row button content.
    /// If the text is nil or empty, the sublabel should be hidden.
    ///
    /// - Parameter text: The text to be displayed in the sublabel. If nil or empty, the sublabel should be hidden.
    func setSublabel(text: String?)

    /// Sets the content view alpha to the desired alpha
    /// - Parameter alpha: The alpha to be applied to the view
    func setContentViewAlpha(_ alpha: CGFloat)
}

extension RowButtonContent {
    func setContentViewAlpha(_ alpha: CGFloat) {
        subviews.map { $0 }.forEach {
            $0.alpha = alpha
        }
    }
}
