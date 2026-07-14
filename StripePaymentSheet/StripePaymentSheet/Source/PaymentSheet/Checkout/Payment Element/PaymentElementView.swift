//
//  PaymentElementView.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 7/13/26.
//

import SwiftUI
import UIKit

/// A SwiftUI view that displays payment methods.
@_spi(STP)
public struct PaymentElementView: View {
    @ObservedObject private var viewModel: PaymentElementViewModel

    init(viewModel: PaymentElementViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        PaymentElementViewRepresentable(viewModel: viewModel)
            .frame(maxWidth: .infinity)
            .frame(height: viewModel.height)
    }
}

@MainActor
final class PaymentElementViewModel: ObservableObject {
    let uiView: PaymentElementUIView

    @Published private(set) var height: CGFloat = 0

    private var width: CGFloat = 0

    init(uiView: PaymentElementUIView) {
        self.uiView = uiView
    }

    func updateHeight(width: CGFloat? = nil, animated: Bool = true) {
        if let width, width > 0 {
            self.width = width
        }

        Task { @MainActor [weak self] in
            self?.updateHeightNow(animated: animated)
        }
    }

    private func updateHeightNow(animated: Bool) {
        let fittingWidth = width > 0 ? width : uiView.bounds.width
        guard fittingWidth > 0 else { return }

        let newHeight = uiView.systemLayoutSizeFitting(
            CGSize(
                width: fittingWidth,
                height: UIView.layoutFittingCompressedSize.height
            ),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height

        guard abs(height - newHeight) > 1 else { return }

        if animated {
            withAnimation(.easeInOut(duration: 0.2)) {
                height = newHeight
            }
        } else {
            height = newHeight
        }
    }
}

private struct PaymentElementViewRepresentable: UIViewRepresentable {
    let viewModel: PaymentElementViewModel

    func makeUIView(context: Context) -> PaymentElementUIView {
        viewModel.uiView.delegate = context.coordinator
        return viewModel.uiView
    }

    func updateUIView(_ uiView: PaymentElementUIView, context: Context) {
        // No-op. UIKit reports height changes through PaymentElementViewDelegate.
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(viewModel: viewModel)
    }

    @MainActor
    final class Coordinator: PaymentElementViewDelegate {
        let viewModel: PaymentElementViewModel

        init(viewModel: PaymentElementViewModel) {
            self.viewModel = viewModel
        }

        func paymentElementViewDidUpdateHeight(paymentElementView: PaymentElementUIView) {
            viewModel.updateHeight()
        }
    }
}
