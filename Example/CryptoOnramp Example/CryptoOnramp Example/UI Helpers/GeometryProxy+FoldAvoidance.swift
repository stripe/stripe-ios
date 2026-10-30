//
//  GeometryProxy+FoldAvoidance.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 10/21/26.
//

import SwiftUI

extension GeometryProxy {

    /// Calculates padding that keeps content within one usable region of the geometry.
    ///
    /// Vertical folds leave content on the trailing side, or on the leading side when the fold reaches the view's trailing edge.
    /// Horizontal folds add top padding, unless the content is anchored to the bottom, in which case they add bottom padding instead.
    /// Returns zero insets when no active fold intersects the bounds or the APIs are unavailable.
    ///
    /// - Parameter anchoredToBottom: Whether a horizontal fold should leave content above the fold instead of below it. Defaults to `false`.
    /// - Returns: Insets that exclude intersecting fold regions and their interaction margins.
    func activeFoldInsets(anchoredToBottom: Bool = false) -> EdgeInsets {
        #if compiler(>=6.4)
        if #available(iOS 27.1, *) {
            let bounds = CGRect(origin: .zero, size: size)
            var insets = EdgeInsets()

            // Frames already include the system's interaction margins and mirror in RTL layouts.
            for region in reservedRegions(kind: .division) where region.frame.intersects(bounds) {
                if region.frame.height > region.frame.width {
                    if region.frame.maxX >= size.width {
                        // A left-side Split View window can end within the fold's interaction margin.
                        insets.trailing = max(insets.trailing, min(size.width, size.width - region.frame.minX))
                    } else {
                        insets.leading = max(insets.leading, min(size.width, region.frame.maxX))
                    }
                } else if anchoredToBottom {
                    insets.bottom = max(insets.bottom, min(size.height, size.height - region.frame.minY))
                } else {
                    insets.top = max(insets.top, min(size.height, region.frame.maxY))
                }
            }
            return insets
        }
        #endif
        return EdgeInsets()
    }
}
