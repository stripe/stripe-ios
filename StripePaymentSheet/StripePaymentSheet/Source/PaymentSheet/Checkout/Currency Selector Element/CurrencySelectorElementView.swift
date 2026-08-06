//
//  CurrencySelectorElementView.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 7/22/26.
//

import Combine
import SwiftUI

/// A SwiftUI view that displays an Adaptive Pricing currency selector.
@_spi(STP)
@_spi(ReactNativeSDK)
public struct CurrencySelectorElementView: View {
    private let viewModel: CurrencySelectorElementViewModel

    @MainActor
    init(viewModel: CurrencySelectorElementViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        CurrencySelectorElementUIViewRepresentable(viewModel: viewModel)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// Bridges CurrencySelectorElement's UIKit state into SwiftUI without retaining Checkout.
@MainActor
final class CurrencySelectorElementViewModel {
    let uiView: CurrencySelectorElementUIView

    private var sessionCancellable: AnyCancellable?

    init(
        sessionSource: CheckoutSessionSource,
        uiView: CurrencySelectorElementUIView
    ) {
        self.uiView = uiView
        sessionCancellable = sessionSource.sessionPublisher
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] session in
                self?.uiView.update(with: session)
            }
    }
}

private struct CurrencySelectorElementUIViewRepresentable: UIViewRepresentable {
    let viewModel: CurrencySelectorElementViewModel

    func makeUIView(context: Context) -> CurrencySelectorElementUIView {
        viewModel.uiView.isEnabled = context.environment.isEnabled
        return viewModel.uiView
    }

    func updateUIView(_ uiView: CurrencySelectorElementUIView, context: Context) {
        uiView.isEnabled = context.environment.isEnabled
    }
}
