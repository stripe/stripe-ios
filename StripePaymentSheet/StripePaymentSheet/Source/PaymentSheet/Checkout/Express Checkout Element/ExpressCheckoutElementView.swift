//
//  ExpressCheckoutElementView.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 7/22/26.
//

import SwiftUI

/// A SwiftUI view that displays wallet payment buttons (Apple Pay, Link).
@_spi(STP)
@_spi(ReactNativeSDK)
public struct ExpressCheckoutElementView: View {
    private let uiView: ExpressCheckoutElementUIView

    @MainActor
    init(uiView: ExpressCheckoutElementUIView) {
        self.uiView = uiView
    }

    public var body: some View {
        ExpressCheckoutElementUIViewRepresentable(uiView: uiView)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct ExpressCheckoutElementUIViewRepresentable: UIViewRepresentable {
    let uiView: ExpressCheckoutElementUIView

    func makeUIView(context: Context) -> ExpressCheckoutElementUIView {
        return uiView
    }

    func updateUIView(_ uiView: ExpressCheckoutElementUIView, context: Context) {}
}
