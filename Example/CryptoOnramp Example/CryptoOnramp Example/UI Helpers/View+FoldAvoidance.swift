//
//  View+FoldAvoidance.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 10/21/26.
//

import SwiftUI

extension View {

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
    @State private var insets = EdgeInsets()

    func body(content: Content) -> some View {
        content
            .padding(insets)
            .frame(maxWidth: .infinity)
            // Measure the full-width container so moving the controls doesn’t change the fold-avoidance calculation.
            .onGeometryChange(for: EdgeInsets.self) { geometry in
                geometry.activeFoldInsets(anchoredToBottom: true)
            } action: { insets in
                self.insets = insets
            }
    }
}
#endif
