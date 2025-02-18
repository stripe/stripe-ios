//
//  RowButtonContent.swift
//  StripeElements
//
//  Created by Nick Porter on 2/12/25.
//

@_spi(STP) import StripeUICore
import UIKit

/// Defines a view that is contained with a `RowButton`
protocol RowButtonContent: UIView, EventHandler {

    /// Indicates whether the row button content is currently selected.
    ///
    /// When set to `true`, the content should visually indicate its selected state.
    /// When set to `false`, the content should appear in its normal, unselected state.
    var isSelected: Bool { get set }

    /// A boolean that indicates if this content view is displaying any subtext
    var hasSubtext: Bool { get }

    /// Sets the text for a sublabel within the row button content.
    /// If the text is nil or empty, the sublabel should be hidden.
    ///
    /// - Parameter text: The text to be displayed in the sublabel. If nil or empty, the sublabel should be hidden.
    func setSublabel(text: String?)

    /// Sets the transparency of key visual elements (image, label, sublabel, etc).
    ///
    /// - Parameter alpha: Opacity level from 0.0 (clear) to 1.0 (opaque).
    func setKeyContent(alpha: CGFloat)
}

extension RowButtonContent {
    // Default implementation reduces alpha on all subviews for disabled state
    func handleEvent(_ event: STPEvent) {
        switch event {
        case .shouldEnableUserInteraction:
            subviews.forEach { $0.alpha = 1 }
        case .shouldDisableUserInteraction:
            subviews.forEach { $0.alpha = 0.5 }
        default:
            break
        }
    }
}
