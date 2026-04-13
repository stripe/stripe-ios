//
//  CheckoutCartPaymentButton.swift
//  PaymentSheet Example
//
//  Created by Nick Porter on 3/3/26.
//

@_spi(STP) import StripePayments
@_spi(CheckoutSessionsPreview) @_spi(STP) import StripePaymentSheet
import SwiftUI

@available(iOS 15.0, *)
struct CheckoutCartPaymentButton: View {
    @ObservedObject var checkout: Checkout
    let onDismiss: () -> Void

    private var session: Checkout.Session { checkout.state.session }

    @State private var paymentResult: PaymentSheetResult?

    var body: some View {
        VStack {
            if let result = paymentResult {
                switch result {
                case .completed:
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.green)
                        Text("Payment Successful!")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .background(
                        Color(UIColor.systemBackground)
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
                    )
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            onDismiss()
                        }
                    }
                case .canceled:
                    Color.clear
                        .onAppear { paymentResult = nil }
                case .failed(let error):
                    VStack(spacing: 8) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.red)
                        Text(error.localizedDescription)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        Color(UIColor.systemBackground)
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
                    )
                }
            } else {
                let paymentSheet = makePaymentSheet()
                PaymentSheet.PaymentButton(
                    paymentSheet: paymentSheet,
                    onCompletion: { result in
                        paymentResult = result
                    }
                ) {
                    HStack {
                        Text("Checkout")
                        Spacer()
                        if let totals = session.totals, let currency = session.currency {
                            Text(formatCartCurrency(amount: totals.total, currency: currency))
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(14)
                }
                .padding(.horizontal)
                .padding(.bottom, 16)
                .padding(.top, 16)
                .background(
                    Color(UIColor.systemBackground)
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
                )
            }
        }
    }

    private func makePaymentSheet() -> PaymentSheet {
        var configuration = PaymentSheet.Configuration()
        configuration.returnURL = "payments-example://stripe-redirect"
        return PaymentSheet(checkout: checkout, configuration: configuration)
    }
}
