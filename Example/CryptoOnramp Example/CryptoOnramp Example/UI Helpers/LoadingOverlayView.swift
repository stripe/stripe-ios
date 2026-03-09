//
//  LoadingOverlayView.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 3/9/26.
//

import SwiftUI

extension View {

    /// Wraps the receiver in a ZStack and optionally displays a loading overlay above it.
    /// - Parameter isVisible: Whether the loading view should be shown.
    func loadingOverlay(isVisible: Bool) -> some View {
        modifier(LoadingOverlayModifier(isVisible: isVisible))
    }
}

/// Reusable loading overlay for blocking UI while asynchronous work is in progress.
private struct LoadingOverlayView: View {

    /// Whether to display the loading overlay.
    let isVisible: Bool

    // MARK: - View

    var body: some View {
        if isVisible {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            ProgressView("Loading…")
                .padding()
                .background {
                    Color(.tertiarySystemBackground)
                        .cornerRadius(8)
                }
        }
    }
}

private struct LoadingOverlayModifier: ViewModifier {
    let isVisible: Bool

    func body(content: Content) -> some View {
        ZStack {
            content

            LoadingOverlayView(isVisible: isVisible)
        }
    }
}
