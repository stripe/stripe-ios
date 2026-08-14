//
//  ExpressCheckoutElementView.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 7/22/26.
//

import Combine
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
        if !viewModel.availableExpressCheckoutPaymentMethods.isEmpty {
            ExpressCheckoutElementUIViewRepresentable(viewModel: viewModel)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// Bridges ExpressCheckoutElement's UIKit state into SwiftUI without retaining Checkout.
///
/// This is the single source of truth for which wallet buttons are currently available:
/// ``ExpressCheckoutElement/availableExpressCheckoutPaymentMethods`` reads from this instance
/// rather than maintaining its own session subscription.
@MainActor
final class ExpressCheckoutElementViewModel: ObservableObject {
    let uiView: ExpressCheckoutElementUIView
    @Published var availableExpressCheckoutPaymentMethods: [ExpressCheckoutElement.ExpressButton] = []

    private let configuration: Checkout.Configuration
    private var sessionCancellable: AnyCancellable?

    init(configuration: Checkout.Configuration, uiView: ExpressCheckoutElementUIView) {
        self.configuration = configuration
        self.uiView = uiView
    }

    /// Resolves the initial button list from `sessionSource` and subscribes to future session
    /// changes. Called once Checkout has an initial session to hand off, since that isn't known
    /// until after `Checkout.init` has finished loading and syncing it.
    func attach(sessionSource: CheckoutSessionSource) {
        update(with: sessionSource.initialSession)
        sessionCancellable = sessionSource.sessionPublisher
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] session in
                self?.update(with: session)
            }
    }

    private func update(with session: Checkout.Session) {
        uiView.update(with: session)
        availableExpressCheckoutPaymentMethods = ExpressCheckoutElementUtilities.resolveButtons(for: session, configuration: configuration)
    }
}

private struct ExpressCheckoutElementUIViewRepresentable: UIViewRepresentable {
    let viewModel: ExpressCheckoutElementViewModel

    func makeUIView(context: Context) -> ExpressCheckoutElementUIView {
        return viewModel.uiView
    }

    func updateUIView(_ uiView: ExpressCheckoutElementUIView, context: Context) {}
}
