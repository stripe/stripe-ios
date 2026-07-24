//
//  ExpressCheckoutElementViewModel.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 7/24/26.
//

import Combine

/// Bridges ExpressCheckoutElement's UIKit state into SwiftUI without retaining Checkout.
@MainActor
final class ExpressCheckoutElementViewModel: ObservableObject {
    let uiView: ExpressCheckoutElementUIView
    @Published var isAvailable: Bool

    private var sessionCancellable: AnyCancellable?

    init(checkout: Checkout, uiView: ExpressCheckoutElementUIView) {
        self.uiView = uiView
        self.isAvailable = checkout.session.isExpressCheckoutElementAvailable
        sessionCancellable = checkout.$session
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] session in
                self?.isAvailable = session.isExpressCheckoutElementAvailable
            }
    }
}
