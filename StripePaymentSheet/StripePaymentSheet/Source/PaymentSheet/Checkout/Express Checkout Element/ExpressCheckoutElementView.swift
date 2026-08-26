//
//  ExpressCheckoutElementView.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 7/22/26.
//

import Combine
@_spi(STP) import StripeCore
import SwiftUI

/// A SwiftUI view that displays wallet payment buttons (Apple Pay, Link).
@_spi(STP)
@_spi(ReactNativeSDK)
public struct ExpressCheckoutElementView: View {
    @ObservedObject private var viewModel: ExpressCheckoutElementViewModel

    @MainActor
    init(viewModel: ExpressCheckoutElementViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        if viewModel.isAvailable {
            ExpressCheckoutElementUIViewRepresentable(viewModel: viewModel)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// Bridges ExpressCheckoutElement's UIKit state into SwiftUI without retaining CheckoutController.
@MainActor
final class ExpressCheckoutElementViewModel: ObservableObject {
    let uiView: ExpressCheckoutElementUIView
    @Published var isAvailable: Bool

    private var sessionCancellable: AnyCancellable?

    init(
        sessionSource: CheckoutSessionSource,
        configuration: ExpressCheckoutElement.Configuration,
        apiClient: STPAPIClient,
        uiView: ExpressCheckoutElementUIView
    ) {
        self.uiView = uiView
        self.isAvailable = !ExpressCheckoutElementUtilities.resolveButtons(for: sessionSource.initialSession, configuration: configuration, apiClient: apiClient).isEmpty
        sessionCancellable = sessionSource.sessionPublisher
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] session in
                self?.uiView.update(with: session)
                self?.isAvailable = !ExpressCheckoutElementUtilities.resolveButtons(for: session, configuration: configuration, apiClient: apiClient).isEmpty
            }
    }
}

private struct ExpressCheckoutElementUIViewRepresentable: UIViewRepresentable {
    let viewModel: ExpressCheckoutElementViewModel

    func makeUIView(context: Context) -> ExpressCheckoutElementUIView {
        return viewModel.uiView
    }

    func updateUIView(_ uiView: ExpressCheckoutElementUIView, context: Context) {}
}
