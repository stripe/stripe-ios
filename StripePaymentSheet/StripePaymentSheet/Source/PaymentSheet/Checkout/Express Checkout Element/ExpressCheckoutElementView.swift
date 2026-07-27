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
            ExpressCheckoutElementUIViewRepresentable(uiView: viewModel.uiView)
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

    init(
        sessionSource: ExpressCheckoutElementSessionSource,
        configuration: Checkout.Configuration,
        uiView: ExpressCheckoutElementUIView
    ) {
        self.uiView = uiView
        self.isAvailable = !ExpressCheckoutElementUtilities.resolveButtons(for: sessionSource.session, configuration: configuration).isEmpty
        sessionCancellable = sessionSource.$session
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] session in
                self?.uiView.update(session: session)
                self?.isAvailable = !ExpressCheckoutElementUtilities.resolveButtons(for: session, configuration: configuration).isEmpty
            }
    }
}

private struct ExpressCheckoutElementUIViewRepresentable: UIViewRepresentable {
    let uiView: ExpressCheckoutElementUIView

    func makeUIView(context: Context) -> ExpressCheckoutElementUIView {
        return uiView
    }

    func updateUIView(_ uiView: ExpressCheckoutElementUIView, context: Context) {}
}
