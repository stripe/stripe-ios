//
//  CheckoutCartExpressCheckoutView.swift
//  PaymentSheet Example
//
//  Created by Joyce Qin on 7/21/26.
//

@_spi(STP) import StripePaymentSheet
import SwiftUI

struct CheckoutCartExpressCheckoutView: View {
    @ObservedObject var checkout: Checkout

    var body: some View {
        VStack(spacing: 12) {
            checkout.getExpressCheckoutElement().view
                .padding(.horizontal)
        }
        .padding(.vertical, 16)
        .background(
            Color(UIColor.systemBackground)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
        )
    }
}
