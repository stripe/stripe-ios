//
//  CheckoutCartPaymentButton.swift
//  PaymentSheet Example
//
//  Created by Nick Porter on 3/3/26.
//

@_spi(STP) import StripePaymentSheet
import SwiftUI

struct CheckoutCartPaymentMethodSection: View {
    @ObservedObject var checkout: CheckoutController
    let integrationType: CheckoutPlayground.IntegrationType

    @State private var showEmbeddedScreen = false

    private var session: CheckoutController.Session { checkout.session }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Payment Method")
                .font(.title2).bold()
                .padding(.horizontal)

            Button {
                presentPaymentElement()
            } label: {
                HStack {
                    paymentMethodLabel
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding()
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .background(Color(UIColor.systemBackground))
            .cornerRadius(16)
            .padding(.horizontal)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
            .accessibilityLabel("Select payment method")
            .accessibilityValue(session.paymentOption?.label ?? "No payment method selected")
            .sheet(isPresented: $showEmbeddedScreen) {
                CheckoutEmbeddedScreen(paymentElement: checkout.getPaymentElement())
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private var paymentMethodLabel: some View {
        if let paymentOption = session.paymentOption {
            HStack(spacing: 8) {
                Image(uiImage: paymentOption.image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 16)
                Text(paymentOption.label)
                    .font(.body)
                    .foregroundColor(.primary)
            }
        } else {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 24))
                Text("Select payment method")
                    .font(.body)
                    .foregroundColor(.primary)
            }
        }
    }

    private func presentPaymentElement() {
        switch integrationType {
        case .flowController:
            Task { @MainActor in
                await checkout.getPaymentElement().present()
            }
        case .embedded:
            showEmbeddedScreen = true
        case .eceOnly:
            break
        }
    }
}

struct CheckoutCartBuyButton: View {
    @ObservedObject var checkout: CheckoutController
    let onConfirm: (CheckoutController.ConfirmResult) -> Void

    private var session: CheckoutController.Session { checkout.session }

    var body: some View {
        Button {
            Task { @MainActor in
                onConfirm(await checkout.confirm())
            }
        } label: {
            HStack {
                if checkout.isUpdating {
                    Spacer()
                    ProgressView()
                        .tint(.white)
                    Spacer()
                } else {
                    Spacer()
                    Text("Buy · \(session.totals.total.amount)")
                    Spacer()
                }
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .background(Color.blue)
            .cornerRadius(14)
        }
        .padding(.horizontal)
        .disabled(checkout.isUpdating)
    }
}
