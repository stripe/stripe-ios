//
//  View+Layout.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 10/21/26.
//

import SwiftUI

extension View {

    /// Limits the content width and centers it horizontally within the available space.
    /// - Parameter maxWidth: The maximum content width. Defaults to `LayoutConstants.contentMaxWidth`.
    /// - Returns: The width-constrained content in a horizontally expanding frame.
    func horizontallyCenteredContent(maxWidth: CGFloat = LayoutConstants.contentMaxWidth) -> some View {
        frame(maxWidth: maxWidth)
            .frame(maxWidth: .infinity)
    }

    /// Keeps controls clear of an active fold.
    ///
    /// On iPhone Duo, this adds padding to keep controls beside the vertical fold or above the horizontal fold that intersects their full-width container.
    /// When disabled, or when no active fold is present, returns the original view.
    ///
    /// - Parameter isEnabled: Whether to apply fold avoidance.
    /// - Returns: The view with fold-aware padding when enabled and supported. Otherwise, the original view.
    @ViewBuilder
    func avoidingActiveFold(_ isEnabled: Bool = true) -> some View {
        #if compiler(>=6.4)
        if #available(iOS 27.1, *), isEnabled {
            modifier(FoldAvoidingActionsModifier())
        } else {
            self
        }
        #else
        self
        #endif
    }
}

#if compiler(>=6.4)
@available(iOS 27.1, *)
private struct FoldAvoidingActionsModifier: ViewModifier {
    @Environment(\.displayScale) private var displayScale
    @State private var insets = EdgeInsets()

    func body(content: Content) -> some View {
        content
            .padding(insets)
            // Keep previous fold padding from widening the measurement during window resizing.
            .frame(minWidth: 0, maxWidth: .infinity)
            // Measure the full-width container so moving the controls doesn’t change the fold-avoidance calculation.
            .background {
                // Reading reserved regions here avoids a layout cycle during keyboard and display changes.
                GeometryReader { geometry in
                    let foldInsets = geometry.activeFoldInsets(anchoredToBottom: true)
                    // Round the insets up to display pixels to prevent tiny floating-point differences from triggering an infinite layout loop.
                    let insets = EdgeInsets(
                        top: (foldInsets.top * displayScale).rounded(.up) / displayScale,
                        leading: (foldInsets.leading * displayScale).rounded(.up) / displayScale,
                        bottom: (foldInsets.bottom * displayScale).rounded(.up) / displayScale,
                        trailing: (foldInsets.trailing * displayScale).rounded(.up) / displayScale
                    )
                    Color.clear
                        .onChange(of: insets, initial: true) { _, insets in
                            self.insets = insets
                        }
                }
            }
    }
}
#endif
