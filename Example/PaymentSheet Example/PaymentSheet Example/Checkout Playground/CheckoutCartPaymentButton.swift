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
    @State private var clearPaymentOptionErrorMessage: String?

    private var session: CheckoutController.Session { checkout.session }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Payment Method")
                    .font(.title2).bold()

                Spacer()

                if session.paymentOption != nil {
                    Button(role: .destructive) {
                        clearPaymentOption()
                    } label: {
                        Label("Clear", systemImage: "xmark.circle")
                            .font(.subheadline.weight(.medium))
                    }
                    .disabled(checkout.isUpdating)
                    .accessibilityLabel("Clear payment method selection")
                }
            }
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
            .alert(
                "Unable to clear payment method",
                isPresented: Binding(
                    get: { clearPaymentOptionErrorMessage != nil },
                    set: { if !$0 { clearPaymentOptionErrorMessage = nil } }
                ),
                actions: {
                    Button("OK", role: .cancel) {
                        clearPaymentOptionErrorMessage = nil
                    }
                },
                message: {
                    Text(clearPaymentOptionErrorMessage ?? "")
                }
            )
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

    private func clearPaymentOption() {
        Task { @MainActor in
            do {
                try await checkout.clearPaymentOption()
            } catch {
                clearPaymentOptionErrorMessage = error.localizedDescription
            }
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
