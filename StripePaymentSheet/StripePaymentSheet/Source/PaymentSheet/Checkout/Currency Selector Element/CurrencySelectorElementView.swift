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
    @ObservedObject private var viewModel: CurrencySelectorElementViewModel

    @MainActor
    init(viewModel: CurrencySelectorElementViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        if viewModel.isAvailable {
            CurrencySelectorElementUIViewRepresentable(uiView: viewModel.uiView)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// Bridges CurrencySelectorElement's UIKit state into SwiftUI without retaining Checkout.
@MainActor
final class CurrencySelectorElementViewModel: ObservableObject {
    let uiView: CurrencySelectorElementUIView
    @Published var isAvailable: Bool

    private var sessionCancellable: AnyCancellable?

    init(checkout: Checkout, uiView: CurrencySelectorElementUIView) {
        self.uiView = uiView
        self.isAvailable = CurrencySelectorUtilities.adaptivePricingData(from: checkout.session) != nil
        sessionCancellable = checkout.$session
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] session in
                self?.isAvailable = CurrencySelectorUtilities.adaptivePricingData(from: session) != nil
            }
    }
}

private struct CurrencySelectorElementUIViewRepresentable: UIViewRepresentable {
    let uiView: CurrencySelectorElementUIView

    func makeUIView(context: Context) -> CurrencySelectorElementUIView {
        uiView.isEnabled = context.environment.isEnabled
        return uiView
    }

    func updateUIView(_ uiView: CurrencySelectorElementUIView, context: Context) {
        uiView.isEnabled = context.environment.isEnabled
    }
}
