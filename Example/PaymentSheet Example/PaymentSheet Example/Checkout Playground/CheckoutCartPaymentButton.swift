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

    @State private var isConfirming = false
    @State private var confirmResult: Checkout.ConfirmResult?

    var body: some View {
        VStack(spacing: 12) {
            Button {
                presentPaymentElement()
            } label: {
                HStack {
                    paymentMethodLabel
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
                confirm()
            } label: {
                HStack {
                    if isConfirming {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Checkout")
                    }
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
            .disabled(isConfirming || session.paymentOption == nil)
            .padding(.horizontal)
            .alert(item: $confirmResult) { result in
                switch result {
                case .succeeded(let paymentStatus):
                    return Alert(title: Text("Payment succeeded"), message: Text("Payment status: \(String(describing: paymentStatus))"))
                case .canceled:
                    return Alert(title: Text("Canceled"))
                case .failed(let error):
                    return Alert(title: Text("Payment failed"), message: Text(error.localizedDescription))
                }
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

    @ViewBuilder
    private var paymentMethodLabel: some View {
        if let paymentOption = session.paymentOption {
            HStack(spacing: 8) {
                Image(uiImage: paymentOption.image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 16)
                Text(paymentOption.label)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
        } else {
            Text("Select payment method")
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }

    private func presentPaymentElement() {
        Task { @MainActor in
            await checkout.getPaymentElement().present()
        }
    }

    private func confirm() {
        Task { @MainActor in
            isConfirming = true
            confirmResult = await checkout.confirm()
            isConfirming = false
        }
    }
}

extension Checkout.ConfirmResult: Identifiable {
    public var id: String {
        switch self {
        case .succeeded: return "succeeded"
        case .canceled: return "canceled"
        case .failed: return "failed"
        }
    }
}
