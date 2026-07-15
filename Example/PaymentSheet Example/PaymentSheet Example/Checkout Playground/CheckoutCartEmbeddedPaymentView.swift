//
//  CheckoutCartEmbeddedPaymentView.swift
//  PaymentSheet Example
//
//  Created by Nick Porter on 7/2/26.
//

@_spi(STP) import StripePaymentSheet
import SwiftUI

struct CheckoutCartEmbeddedPaymentView: View {
    @ObservedObject var checkout: Checkout

    @State private var showConfirmStub = false
    @State private var showEmbeddedScreen = false

    private var session: Checkout.Session { checkout.session }

    var body: some View {
        paymentBarView
    }

    // MARK: - Payment Bar

    @ViewBuilder
    private var paymentBarView: some View {
        VStack(spacing: 12) {
            Button {
                showEmbeddedScreen = true
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
            .sheet(isPresented: $showEmbeddedScreen) {
                CheckoutEmbeddedScreen(paymentElement: checkout.getPaymentElement())
            }

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
}

// MARK: - Embedded Payment Method Screen

private struct CheckoutEmbeddedScreen: View {
    @Environment(\.dismiss) private var dismiss
    let paymentElement: PaymentElement

    var body: some View {
        NavigationView {
            ScrollView {
                paymentElement.view
                    .padding()
            }
            .navigationTitle("Payment Method")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
