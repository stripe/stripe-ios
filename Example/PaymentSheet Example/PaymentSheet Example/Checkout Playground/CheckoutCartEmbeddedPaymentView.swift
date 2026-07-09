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
    let onDismiss: () -> Void

    @StateObject private var viewModel = EmbeddedPaymentElementViewModel()
    @State private var isLoading = true
    @State private var loadError: Error?
    @State private var paymentResult: PaymentSheetResult?
    @State private var isConfirming = false
    @State private var showEmbeddedScreen = false

    private var session: Checkout.Session { checkout.session }

    var body: some View {
        VStack {
            if let result = paymentResult {
                paymentResultView(result: result)
            } else if viewModel.isLoaded {
                paymentBarView
            } else if isLoading {
                ProgressView()
                    .padding()
            } else if let loadError {
                errorView(error: loadError)
            }
        }
        .task {
            await load()
        }
    }

    // MARK: - Payment Bar

    @ViewBuilder
    private var paymentBarView: some View {
        VStack(spacing: 12) {
            Button {
                showEmbeddedScreen = true
            } label: {
                HStack {
                    if let paymentOption = viewModel.paymentOption {
                        Image(uiImage: paymentOption.image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 20)
                        Text(paymentOption.label)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    } else {
                        Text("Select payment method")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
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
                CheckoutEmbeddedScreen(viewModel: viewModel)
            }

            Button {
                confirm()
            } label: {
                HStack {
                    if isConfirming {
                        ProgressView()
                            .tint(.white)
                            .padding(.trailing, 8)
                        Text("Processing...")
                    } else {
                        Text("Checkout")
                        Spacer()
                        if let total = session.total, let currency = session.currency {
                            Text(formatCartCurrency(amount: total.total.minorUnitsAmount, currency: currency))
                        }
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(viewModel.paymentOption != nil && !isConfirming ? Color.blue : Color.gray)
                .cornerRadius(14)
            }
            .disabled(viewModel.paymentOption == nil || isConfirming)
            .padding(.horizontal)
        }
        .padding(.bottom, 16)
        .padding(.top, 16)
        .background(
            Color(UIColor.systemBackground)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
        )
    }

    // MARK: - Result Views

    @ViewBuilder
    private func paymentResultView(result: PaymentSheetResult) -> some View {
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
            errorView(error: error)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        paymentResult = nil
                    }
                }
        }
    }

    @ViewBuilder
    private func errorView(error: Error) -> some View {
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

    // MARK: - Actions

    private func load() async {
        isLoading = true
        do {
            var configuration = EmbeddedPaymentElement.Configuration()
            configuration.returnURL = "payments-example://stripe-redirect"
            configuration.applePay = .init(
                merchantId: "merchant.com.stripe.umbrella.test",
                merchantCountryCode: "US"
            )
            configuration.billingDetailsCollectionConfiguration.name = .always
            configuration.billingDetailsCollectionConfiguration.address = .full
            configuration.defaultBillingDetails.name = "Jane Doe"
            configuration.defaultBillingDetails.phone = "+15555555555"
            configuration.defaultBillingDetails.address = .init(
                city: "San Francisco",
                country: "US",
                line1: "510 Townsend St",
                postalCode: "94103",
                state: "CA"
            )
            try await viewModel.load(checkout: checkout, configuration: configuration)
        } catch {
            loadError = error
        }
        isLoading = false
    }

    private func confirm() {
        isConfirming = true
        Task { @MainActor in
            let result = await viewModel.confirm()
            isConfirming = false
            switch result {
            case .completed, .failed:
                paymentResult = result
            case .canceled:
                break
            }
        }
    }
}

// MARK: - Embedded Payment Method Screen

private struct CheckoutEmbeddedScreen: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: EmbeddedPaymentElementViewModel

    var body: some View {
        NavigationView {
            ScrollView {
                EmbeddedPaymentElementView(viewModel: viewModel)
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
