//
//  CheckoutCartPaymentButton.swift
//  PaymentSheet Example
//
//  Created by Nick Porter on 3/3/26.
//

@_spi(STP) import StripePaymentSheet
import SwiftUI

struct CheckoutCartPaymentButton: View {
    @ObservedObject var checkout: Checkout

    private var session: Checkout.Session { checkout.session }

    @State private var showConfirmStub = false

    var body: some View {
        VStack(spacing: 12) {
            Button {
                presentPaymentElement()
            } label: {
                HStack {
                    Text("Select payment method")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )
            }
            .padding(.horizontal)

            Button {
                showConfirmStub = true
            } label: {
                HStack {
                    Text("Checkout")
                    Spacer()
                    if let total = session.total, let currency = session.currency {
                        Text(formatCartCurrency(amount: total.total.minorUnitsAmount, currency: currency))
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(14)
            }
            .padding(.horizontal)
            .alert(isPresented: $showConfirmStub) {
                Alert(
                    title: Text("Confirm stubbed"),
                    message: Text("Checkout confirm is not implemented yet."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .padding(.bottom, 16)
        .padding(.top, 16)
        .background(
            Color(UIColor.systemBackground)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
        )
    }

    // MARK: - Helpers

    private func presentPaymentElement() {
        Task { @MainActor in
            await checkout.getPaymentElement().present()
        }
    }
}
