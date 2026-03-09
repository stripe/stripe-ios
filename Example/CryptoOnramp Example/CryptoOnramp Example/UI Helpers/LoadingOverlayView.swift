//
//  LoadingOverlayView.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 3/9/26.
//

import SwiftUI

/// Reusable loading overlay for blocking UI while asynchronous work is in progress.
struct LoadingOverlayView: View {

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
