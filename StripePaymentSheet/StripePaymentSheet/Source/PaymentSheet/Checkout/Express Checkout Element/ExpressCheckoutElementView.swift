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

/// Bridges ExpressCheckoutElement's UIKit state into SwiftUI without retaining CheckoutController.
@MainActor
final class ExpressCheckoutElementViewModel: ObservableObject {
    let uiView: ExpressCheckoutElementUIView
    @Published private(set) var buttons: [ExpressCheckoutElement.PaymentMethod]

    var isAvailable: Bool {
        return !buttons.isEmpty
    }

    private var sessionCancellable: AnyCancellable?

    init(
        sessionSource: CheckoutSessionSource,
        uiView: ExpressCheckoutElementUIView
    ) {
        let initialSession = sessionSource.initialSession
        let initialButtons = Self.resolveButtons(for: initialSession)
        self.uiView = uiView
        self.buttons = initialButtons
        uiView.update(with: initialSession, buttons: initialButtons)
        sessionCancellable = sessionSource.sessionPublisher
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] session in
                guard let self else { return }
                let buttons = Self.resolveButtons(for: session)
                self.uiView.update(with: session, buttons: buttons)
                self.buttons = buttons
            }
    }

    private static func resolveButtons(
        for session: CheckoutController.Session
    ) -> [ExpressCheckoutElement.PaymentMethod] {
        return session.availableExpressCheckoutPaymentMethods.compactMap(
            ExpressCheckoutElement.PaymentMethod.init(rawValue:)
        )
    }
}

private struct ExpressCheckoutElementUIViewRepresentable: UIViewRepresentable {
    let viewModel: ExpressCheckoutElementViewModel

    func makeUIView(context: Context) -> ExpressCheckoutElementUIView {
        return viewModel.uiView
    }

    func updateUIView(_ uiView: ExpressCheckoutElementUIView, context: Context) {}
}
