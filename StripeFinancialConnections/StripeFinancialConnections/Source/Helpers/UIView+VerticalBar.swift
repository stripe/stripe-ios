//
//  UIView+VerticalBar.swift
//  StripeFinancialConnections
//

import UIKit

extension UIView {

    /// The physical edges where the system places its vertical bar, such as the iPhone Duo's side column,
    /// or `nil` when the system doesn't report it (before iOS 27.1).
    ///
    /// `verticalBarEdge` follows the layout direction, while safe area insets use physical edges.
    var stp_verticalBarEdges: UIRectEdge? {
        #if compiler(>=6.4.2) && !os(visionOS)
        if #available(iOS 27.1, *) {
            let isRightToLeft = effectiveUserInterfaceLayoutDirection == .rightToLeft
            switch traitCollection.verticalBarEdge {
            case .leading:
                return isRightToLeft ? .right : .left
            case .trailing:
                return isRightToLeft ? .left : .right
            case .unspecified:
                return []
            @unknown default:
                return []
            }
        }
        #endif
        return nil
    }
}
