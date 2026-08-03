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
        if viewModel.isAvailable {
            ExpressCheckoutElementUIViewRepresentable(viewModel: viewModel)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// Bridges ExpressCheckoutElement's UIKit state into SwiftUI without retaining Checkout.
@MainActor
final class ExpressCheckoutElementViewModel: ObservableObject {
    let uiView: ExpressCheckoutElementUIView
    @Published var isAvailable: Bool

    private var sessionCancellable: AnyCancellable?

    init(sessionSource: CheckoutSessionSource, configuration: Checkout.Configuration, uiView: ExpressCheckoutElementUIView) {
        self.uiView = uiView
        let initialPaymentMethods = ExpressCheckoutElement.availablePaymentMethods(for: sessionSource.initialSession, configuration: configuration)
        self.isAvailable = !initialPaymentMethods.isEmpty
        sessionCancellable = sessionSource.sessionPublisher
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] session in
                guard let self else { return }
                let paymentMethods = ExpressCheckoutElement.availablePaymentMethods(for: session, configuration: configuration)
                self.uiView.update(with: paymentMethods, session: session)
                self.isAvailable = !paymentMethods.isEmpty
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
