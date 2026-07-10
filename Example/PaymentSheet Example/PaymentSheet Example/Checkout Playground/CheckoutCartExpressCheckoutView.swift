//
//  CheckoutCartExpressCheckoutView.swift
//  PaymentSheet Example
//

@_spi(STP) import StripePaymentSheet
import SwiftUI

/// Playground view for Express Checkout Element with Checkout Sessions.
struct CheckoutCartExpressCheckoutView: View {
    @ObservedObject var checkout: Checkout
    let onDismiss: () -> Void

    @State private var expressCheckoutElement: ExpressCheckoutElement?
    @State private var isLoading = true
    @State private var loadError: Error?
    @State private var paymentResult: PaymentSheetResult?

    private var session: Checkout.Session { checkout.session }

    var body: some View {
        VStack {
            if let result = paymentResult {
                paymentResultView(result: result)
            } else if let element = expressCheckoutElement {
                expressCheckoutBar(element: element)
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

    // MARK: - Express Checkout Bar

    @ViewBuilder
    private func expressCheckoutBar(element: ExpressCheckoutElement) -> some View {
        VStack(spacing: 8) {
            if element.hasWallets {
                if #available(iOS 16.0, *) {
                    element.view
                        .padding(.horizontal)
                } else {
                    Text("Express Checkout requires iOS 16 or later.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding()
                }
            } else {
                Text("No express payment methods available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .padding(.vertical, 16)
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

    // MARK: - Loading

    private func load() async {
        isLoading = true
        loadError = nil
        do {
            let element = try await checkout.getExpressCheckoutElement()
            element.delegate = PaymentResultDelegate(onResult: { result in
                paymentResult = result
            })
            expressCheckoutElement = element
        } catch {
            loadError = error
        }
        isLoading = false
    }
}

// MARK: - Delegate helper

private class PaymentResultDelegate: ExpressCheckoutElementDelegate {
    let onResult: (PaymentSheetResult) -> Void

    init(onResult: @escaping (PaymentSheetResult) -> Void) {
        self.onResult = onResult
    }

    func expressCheckoutElement(
        _ element: ExpressCheckoutElement,
        didCompleteWith result: PaymentSheetResult
    ) {
        onResult(result)
    }
}
