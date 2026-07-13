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
    @State private var height: CGFloat = 0

    private let uiView: PaymentElementUIView

    init(uiView: PaymentElementUIView) {
        self.uiView = uiView
    }

    public var body: some View {
        PaymentElementViewRepresentable(uiView: uiView, height: $height)
            .frame(height: height)
    }
}

private struct PaymentElementViewRepresentable: UIViewRepresentable {
    let uiView: PaymentElementUIView

    @Binding var height: CGFloat

    func makeUIView(context: Context) -> PaymentElementUIView {
        uiView.delegate = context.coordinator
        context.coordinator.updateHeight(for: uiView)
        return uiView
    }

    func updateUIView(_ uiView: PaymentElementUIView, context: Context) {
        context.coordinator.height = $height
        context.coordinator.updateHeight(for: uiView)
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(height: $height)
    }

    @MainActor
    final class Coordinator: PaymentElementViewDelegate {
        var height: Binding<CGFloat>

        init(height: Binding<CGFloat>) {
            self.height = height
        }

        func paymentElementViewDidUpdateHeight(paymentElementView: PaymentElementUIView) {
            updateHeight(for: paymentElementView)
        }

        func updateHeight(for paymentElementView: PaymentElementUIView) {
            let newHeight = paymentElementView.systemLayoutSizeFitting(
                CGSize(
                    width: paymentElementView.bounds.width,
                    height: UIView.layoutFittingCompressedSize.height
                )
            ).height

            withAnimation(.easeInOut(duration: 0.2)) {
                height.wrappedValue = newHeight
            }
        }
    }
}
