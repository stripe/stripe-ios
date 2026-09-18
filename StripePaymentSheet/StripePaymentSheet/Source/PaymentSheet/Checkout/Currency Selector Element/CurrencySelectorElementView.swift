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
        _viewModel = ObservedObject(wrappedValue: viewModel)
    }

    public var body: some View {
        CurrencySelectorElementUIViewRepresentable(viewModel: viewModel)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// Bridges CurrencySelectorElement's UIKit state into SwiftUI without retaining CheckoutController.
@MainActor
final class CurrencySelectorElementViewModel: ObservableObject {
    let uiView: CurrencySelectorElementUIView

    private var sessionCancellable: AnyCancellable?

    init(
        sessionSource: CheckoutSessionSource,
        uiView: CurrencySelectorElementUIView
    ) {
        self.uiView = uiView
        uiView.didUpdateContentHeight = { [weak self] in
            self?.objectWillChange.send()
        }
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
        viewModel.uiView.setEnabled(context.environment.isEnabled)
        return viewModel.uiView
    }

    func updateUIView(_ uiView: CurrencySelectorElementUIView, context: Context) {
        uiView.setEnabled(context.environment.isEnabled)
    }

    @available(iOS 16.0, *)
    func sizeThatFits(
        _ proposal: ProposedViewSize,
        uiView: CurrencySelectorElementUIView,
        context: Context
    ) -> CGSize? {
        guard let width = proposal.width, width > 0 else {
            return nil
        }
        return uiView.systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
    }
}
