//
//  PreviewWrapperView.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 8/7/25.
//

import SwiftUI

@_spi(STP)
import StripeCryptoOnramp

@_spi(STP)
import StripePaymentSheet

/// A wrapper view used for Swift UI previews to reduce duplication around views that require a publishable key and `CryptoOnrampCoordinator` instance to be set up.
struct PreviewWrapperView<Content: View>: View {
    @State private var coordinator: CryptoOnrampCoordinator?

    @ViewBuilder
    private let content: (CryptoOnrampCoordinator) -> Content

    /// Creates a new `PreviewWrapperView`.
    /// - Parameter content: A view builder responsible for creating the content view.
    init(@ViewBuilder _ content: @escaping (CryptoOnrampCoordinator) -> Content) {
        self.content = content
    }

    var body: some View {
        NavigationView {
            if let coordinator = coordinator {
                content(coordinator)
            }
        }
        .onAppear {
            STPAPIClient.shared.setUpPublishableKey(livemode: false)
            Task {
                let coordinator = try? await CryptoOnrampCoordinator.create()

                await MainActor.run {
                    self.coordinator = coordinator
                }
            }
        }
    }
}
