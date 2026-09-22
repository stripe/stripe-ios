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
            .frame(maxWidth: .infinity)
            .frame(height: viewModel.height)
    }
}

/// Bridges CurrencySelectorElement's UIKit state into SwiftUI without retaining CheckoutController.
@MainActor
final class CurrencySelectorElementViewModel: ObservableObject {
    let uiView: CurrencySelectorElementUIView

    @Published private(set) var height: CGFloat?

    private var width: CGFloat = 0
    private var sessionCancellable: AnyCancellable?

    init(
        sessionSource: CheckoutSessionSource,
        uiView: CurrencySelectorElementUIView
    ) {
        self.uiView = uiView
        uiView.didUpdateContentHeight = { [weak self] in
            self?.updateHeight()
        }
        sessionCancellable = sessionSource.sessionPublisher
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] session in
                self?.uiView.update(with: session)
            }
    }

    func updateHeight(width: CGFloat? = nil) {
        if let width, width > 0 {
            self.width = width
        }

        Task { @MainActor [weak self] in
            self?.updateHeightNow()
        }
    }

    private func updateHeightNow() {
        let fittingWidth = width > 0 ? width : uiView.bounds.width
        guard fittingWidth > 0 else { return }

        let newHeight = uiView.systemLayoutSizeFitting(
            CGSize(width: fittingWidth, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height

        guard height.map({ abs($0 - newHeight) > 1 }) ?? true else { return }
        height = newHeight
    }
}

private struct CurrencySelectorElementUIViewRepresentable: UIViewRepresentable {
    let viewModel: CurrencySelectorElementViewModel

    func makeUIView(context: Context) -> CurrencySelectorElementUIView {
        viewModel.uiView.setEnabled(context.environment.isEnabled)
        viewModel.updateHeight()
        return viewModel.uiView
    }

    func updateUIView(_ uiView: CurrencySelectorElementUIView, context: Context) {
        uiView.setEnabled(context.environment.isEnabled)
        viewModel.updateHeight(width: uiView.bounds.width)
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
