//
//  CheckoutCartPaymentButton.swift
//  PaymentSheet Example
//
//  Created by Nick Porter on 3/3/26.
//

@_spi(STP) import StripePaymentSheet
import SwiftUI

struct CheckoutCartPaymentButton: View {
    @ObservedObject var checkout: CheckoutController
    let onConfirm: (CheckoutController.ConfirmResult) -> Void

    private var session: CheckoutController.Session { checkout.session }

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
                        Text("Checkout")
                        Spacer()
                        Text(session.totals.total.amount)
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
}
